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
/// - Layer 1: Polling timer (2s interval) for PID diffing via libproc
/// - Layer 2: Path matching to identify target CLI processes
/// - Layer 3: DispatchSourceProcess exit observers for low-latency exit detection
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
    /// A process is tracked if its path's last path component matches any pattern.
    public var trackedProcessNames: Set<String> = []

    /// Register: begins the polling timer.
    public func register() {
        guard pollingTimer == nil else { return }

        // Reset known PID state
        knownPIDs = Set()

        let timer = DispatchSource.makeTimerSource(queue: pollingQueue)
        timer.schedule(deadline: .now(), repeating: .seconds(2), leeway: .milliseconds(500))
        timer.setEventHandler { [weak self] in
            self?.pollProcesses()
        }
        timer.resume()
        pollingTimer = timer

        NSLog("[ProcessMonitor] registered")
    }

    /// Unregister: stops polling and removes all exit observers.
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

    /// DispatchSourceProcess exit observers keyed by PID.
    private var exitObservers: [pid_t: DispatchSourceProcess] = [:]

    private static let logSubsystem = "info.marcel-dierkes.KeepingYouAwake"

    // MARK: - Layer 1: PID Polling & Diffing

    private func pollProcesses() {
        // Get current PID list from libproc
        var pidBuffer = [pid_t](repeating: 0, count: 1024)
        let count = kya_proc_listallpids(&pidBuffer, Int32(pidBuffer.count * MemoryLayout<pid_t>.size))
        guard count > 0 else { return }

        let currentPIDs = Set(pidBuffer[0..<Int(count)])

        // Diff: find newly appeared PIDs
        let newPIDs = currentPIDs.subtracting(knownPIDs)

        // Diff: find PIDs that disappeared (exit detected via poll fallback)
        let disappearedPIDs = knownPIDs.subtracting(currentPIDs)
        cleanUpExitedPIDs(disappearedPIDs)

        knownPIDs = currentPIDs

        // Layer 2: Check new PIDs for target processes
        if !newPIDs.isEmpty && !trackedProcessNames.isEmpty {
            checkNewPIDs(newPIDs)
        }
    }

    // MARK: - Layer 2: Path Matching

    private func checkNewPIDs(_ pids: Set<pid_t>) {
        var newTrackedPaths: [String] = []

        for pid in pids {
            let path = pidPath(pid)
            guard !path.isEmpty else { continue }

            let name = (path as NSString).lastPathComponent
            if trackedProcessNames.contains(name) {
                newTrackedPaths.append(path)

                // Layer 3: Register exit observer for this PID
                registerExitObserver(pid)
            }
        }

        if !newTrackedPaths.isEmpty {
            trackedProcessPaths.append(contentsOf: newTrackedPaths)
            notifyProcessChange()
        }
    }

    /// Returns the executable path for a PID using libproc, or empty string on error.
    private func pidPath(_ pid: pid_t) -> String {
        var buffer = [CChar](repeating: 0, count: 4096)
        let result = kya_proc_pidpath(pid, &buffer, Int32(buffer.count))
        guard result > 0 else { return "" }
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
        // Remove the exit observer
        exitObservers[pid]?.cancel()
        exitObservers.removeValue(forKey: pid)

        // Remove the tracked path for this PID
        let exitedPath = pidPath(pid) // Path may still be available briefly after exit
        trackedProcessPaths.removeAll { path in
            // Match by path or by the last component if the PID path is no longer available
            if !exitedPath.isEmpty {
                return path == exitedPath
            }
            // Fallback: remove first path matching a tracked name we know was associated with this PID
            let name = (path as NSString).lastPathComponent
            return exitedPath.isEmpty && trackedProcessNames.contains(name) && path.contains(String(pid))
        }

        if trackedProcessPaths.isEmpty {
            NSLog("[ProcessMonitor] all tracked processes exited")
        }

        notifyProcessChange()
    }

    /// Fallback cleanup for PIDs that disappeared between poll cycles
    /// without triggering a DispatchSourceProcess event.
    private func cleanUpExitedPIDs(_ pids: Set<pid_t>) {
        for pid in pids {
            exitObservers[pid]?.cancel()
            exitObservers.removeValue(forKey: pid)
        }

        // Rebuild trackedProcessPaths by verifying remaining PIDs
        var verifiedPaths: [String] = []
        for path in trackedProcessPaths {
            let name = (path as NSString).lastPathComponent
            // Check if any known PID still has this name as its path
            var stillRunning = false
            for pid in knownPIDs {
                let currentPath = pidPath(pid)
                if (currentPath as NSString).lastPathComponent == name {
                    stillRunning = true
                    break
                }
            }
            if stillRunning {
                verifiedPaths.append(path)
            }
        }

        if verifiedPaths.count != trackedProcessPaths.count {
            trackedProcessPaths = verifiedPaths
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