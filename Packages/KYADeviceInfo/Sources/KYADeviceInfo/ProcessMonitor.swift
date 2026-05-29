//
//  ProcessMonitor.swift
//  KYADeviceInfo
//
//  Created by Marcel Dierkes on 2026-05-28.
//  Three-layer hybrid: polling timer + PID diffing/path matching + DispatchSourceProcess exit observers.
//

import Dispatch
import Foundation
import ClibprocShim

/// Monitors CLI processes using a three-layer hybrid approach:
/// - Layer 1: Polling timer (1s interval) for PID diffing via libproc
/// - Layer 2: Path matching to identify target CLI processes
/// - Layer 3: DispatchSourceProcess exit observers for low-latency exit detection
///
/// On register, immediately scans all existing PIDs for target processes.
/// On unregister, keeps the current sleep prevention state unchanged.
public final class ProcessMonitor: Monitor {
    /// Called when a tracked process starts or exits.
    /// Parameters: (isRunning, processPaths) where processPaths lists currently
    /// running target process paths.
    public var onProcessChange: ((Bool, [String]) -> Void)?

    /// Whether the process monitor is currently registered (polling).
    public var isRegistered: Bool {
        pollingTimer != nil
    }

    /// The set of process name patterns to track.
    /// A process is tracked if its path's last path component matches any pattern
    /// (case-insensitive comparison).
    public var trackedProcessNames: Set<String> = [] {
        didSet {
            // Pre-compute lowercase set for efficient case-insensitive matching.
            // Empty string is never a valid process name, so filter it.
            lowercaseTrackedNames = Set(trackedProcessNames.map { $0.lowercased() }.filter { !$0.isEmpty })
        }
    }

    /// Pre-computed lowercase names for case-insensitive matching.
    private var lowercaseTrackedNames: Set<String> = []

    /// Register: immediately scans all current PIDs, then starts 1s polling.
    public func register() {
        guard pollingTimer == nil else { return }

        // Reset state
        knownPIDs = Set()
        trackedProcessPaths = []
        pidPathMap = [:]
        exitObservers = [:]

        // Immediately capture all current PIDs and scan for matches
        let allPIDs = getAllPIDs()
        knownPIDs = allPIDs
        scanForMatches(in: allPIDs)

        // Start 1s polling timer
        let timer = DispatchSource.makeTimerSource(queue: pollingQueue)
        timer.schedule(deadline: .now() + .seconds(1), repeating: .seconds(1), leeway: .milliseconds(200))
        timer.setEventHandler { [weak self] in
            self?.pollProcesses()
        }
        timer.resume()
        pollingTimer = timer

        NSLog("[ProcessMonitor] registered")
    }

    /// Unregister: stops polling and removes all exit observers.
    /// Does NOT alter the caller's sleep prevention state.
    public func unregister() {
        guard let timer = pollingTimer else { return }
        timer.cancel()
        pollingTimer = nil

        // Clean up all exit observers
        for observer in exitObservers.values {
            observer.cancel()
        }
        exitObservers.removeAll()

        // Clear tracked state
        knownPIDs = Set()
        trackedProcessPaths = []
        pidPathMap = [:]

        NSLog("[ProcessMonitor] unregistered")
    }

    /// Returns the paths of currently running tracked processes.
    public var currentlyRunningProcessPaths: [String] {
        trackedProcessPaths
    }

    // MARK: - Private

    private var pollingTimer: DispatchSourceTimer?
    private let pollingQueue = DispatchQueue(label: "info.marcel-dierkes.KeepingYouAwake.process-monitor", qos: .utility)

    /// PIDs discovered in the previous poll cycle.
    private var knownPIDs: Set<pid_t> = []

    /// Paths of currently tracked (running) target processes.
    private var trackedProcessPaths: [String] = []

    /// Map from PID to its tracked process path.
    private var pidPathMap: [pid_t: String] = [:]

    /// DispatchSourceProcess exit observers keyed by PID.
    private var exitObservers: [pid_t: DispatchSourceProcess] = [:]

    // MARK: - PID Enumeration

    /// Gets all current PIDs from the system via libproc.
    private func getAllPIDs() -> Set<pid_t> {
        var pidBuffer = [pid_t](repeating: 0, count: 4096)
        let count = kya_proc_listallpids(&pidBuffer, Int32(pidBuffer.count * MemoryLayout<pid_t>.size))
        guard count > 0 else { return [] }
        return Set(pidBuffer[0..<Int(count)])
    }

    // MARK: - Layer 1: PID Polling & Diffing

    private func pollProcesses() {
        let currentPIDs = getAllPIDs()

        // Diff: find newly appeared PIDs
        let newPIDs = currentPIDs.subtracting(knownPIDs)

        // Diff: find PIDs that disappeared (fallback cleanup)
        let disappearedPIDs = knownPIDs.subtracting(currentPIDs)
        if !disappearedPIDs.isEmpty {
            cleanupDisappearedPIDs(disappearedPIDs)
        }

        knownPIDs = currentPIDs

        // Layer 2: Check new PIDs for target processes
        if !newPIDs.isEmpty && !trackedProcessNames.isEmpty {
            scanForMatches(in: newPIDs)
        }
    }

    // MARK: - Layer 2: Path Matching

    private func scanForMatches(in pids: Set<pid_t>) {
        var newTrackedPaths: [String] = []

        for pid in pids {
            let path = pidPath(pid)
            guard !path.isEmpty else { continue }

            let name = (path as NSString).lastPathComponent
            if lowercaseTrackedNames.contains(name.lowercased()) {
                newTrackedPaths.append(path)
                pidPathMap[pid] = path
                NSLog("[ProcessMonitor] Found tracked process: pid=\(pid) name=\(name) path=\(path)")

                // Layer 3: Register exit observer for this PID
                registerExitObserver(pid)
            }
        }

        if !newTrackedPaths.isEmpty {
            trackedProcessPaths.append(contentsOf: newTrackedPaths)
            NSLog("[ProcessMonitor] Matched \(newTrackedPaths.count) process(es) in scan, total tracked=\(trackedProcessPaths.count)")
            notifyProcessChange()
        }
    }

    /// Returns the executable path for a PID using libproc, or empty string on error.
    private func pidPath(_ pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: 4096)
        let result = kya_proc_pidpath(pid, &buffer, Int32(buffer.count))
        guard result > 0 else {
            if result == -1 {
                NSLog("[ProcessMonitor] pidPath error: pid=\(pid) errno=\(errno)")
            }
            return ""
        }
        return String(cString: buffer)
    }

    // MARK: - Layer 3: DispatchSourceProcess Exit Observers

    private func registerExitObserver(_ pid: pid_t) {
        guard exitObservers[pid] == nil else { return }

        let source = DispatchSource.makeProcessSource(identifier: pid, eventMask: .exit, queue: pollingQueue)
        source.setEventHandler { [weak self] in
            self?.handleProcessExit(pid)
        }
        source.resume()
        exitObservers[pid] = source
    }

    private func handleProcessExit(_ pid: pid_t) {
        // Cancel and remove observer
        exitObservers[pid]?.cancel()
        exitObservers.removeValue(forKey: pid)

        // Remove the tracked path associated with this PID
        if let path = pidPathMap[pid] {
            trackedProcessPaths.removeAll { $0 == path }
        }
        pidPathMap.removeValue(forKey: pid)

        notifyProcessChange()
    }

    /// Fallback cleanup for PIDs that disappeared between poll cycles
    /// without triggering a DispatchSourceProcess event.
    private func cleanupDisappearedPIDs(_ pids: Set<pid_t>) {
        var didChange = false

        for pid in pids {
            guard exitObservers[pid] != nil else { continue }
            exitObservers[pid]?.cancel()
            exitObservers.removeValue(forKey: pid)

            if let path = pidPathMap[pid] {
                trackedProcessPaths.removeAll { $0 == path }
            }
            pidPathMap.removeValue(forKey: pid)
            didChange = true
        }

        if didChange {
            notifyProcessChange()
        }
    }

    // MARK: - Notification

    private func notifyProcessChange() {
        guard let handler = onProcessChange else { return }
        let isRunning = !trackedProcessPaths.isEmpty
        DispatchQueue.main.async {
            handler(isRunning, self.trackedProcessPaths)
        }
    }

    deinit {
        unregister()
    }
}