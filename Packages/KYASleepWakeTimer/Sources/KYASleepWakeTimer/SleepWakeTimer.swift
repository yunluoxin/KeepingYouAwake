//  SleepWakeTimer.swift
//  KYASleepWakeTimer
//
//  Created by Marcel Dierkes on 07.11.14.
//  Rewritten in Swift from KYASleepWakeTimer.m.
//

import Foundation
import os.log
import KYAApplicationSupport

/// A time interval value representing indefinite scheduling (no timeout).
/// Pass this value to ``SleepWakeTimer/schedule(timeInterval:completion:)``
/// for indefinite mode where caffeinate runs without a `-t` timeout.
public let indefiniteTimeInterval: TimeInterval = 0

/// Manages the sleep/wake state by spawning `/usr/bin/caffeinate` tasks.
///
/// Use ``schedule(timeInterval:completion:)`` to activate and
/// ``invalidate()`` to deactivate. When `timeInterval == 0`
/// (`indefiniteTimeInterval`), caffeinate runs indefinitely (no `-t` timeout).
/// When `timeInterval > 0`, caffeinate runs with `-t <seconds>`.
public final class SleepWakeTimer {

    /// Called when the timer activates with the scheduled time interval.
    public var onActivate: ((TimeInterval) -> Void)?

    /// Called when the timer deactivates (either naturally or via invalidation).
    public var onDeactivate: (() -> Void)?

    /// The completion date for the currently scheduled timer.
    ///
    /// Returns `nil` when the timer is scheduled indefinitely
    /// (`timeInterval == 0`) or when no timer is scheduled.
    public private(set) var fireDate: Date?

    /// The initial time interval that was used to schedule the timer.
    public private(set) var scheduledTimeInterval: TimeInterval = 0

    /// Returns `true` if a caffeinate task is scheduled and running.
    public var isScheduled: Bool {
        caffeinateProcess?.isRunning == true
    }

    /// An optional completion block called on the main queue when the task
    /// finishes or is invalidated.
    ///
    /// The `cancelled` flag is `true` when manually invalidated via
    /// ``invalidate()``, and `false` when the timer expired naturally.
    public var completionBlock: ((Bool) -> Void)?

    private var caffeinateProcess: Process?
    private var terminationObserver: NSObjectProtocol?

    // Logging uses os_log directly; will switch to KYALog.shared once
    // KYACommon is rewritten in Swift.
    private let log = os_log_create(
        "info.marcel-dierkes.KeepingYouAwake",
        "SleepWakeTimer"
    )

    public init() {
        // Terminate all remaining tasks on app quit
        terminationObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.willTerminateNotification,
            object: nil,
            queue: .main,
            using: { [weak self] _ in self?.invalidate() }
        )
    }

    deinit {
        if let observer = terminationObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        invalidate()
    }

    // MARK: - Scheduling

    /// Schedule the caffeinate task for a given time interval.
    ///
    /// - Parameter timeInterval: A time interval in seconds. Pass
    ///   `indefiniteTimeInterval` (or `0`) for indefinite mode with no timeout.
    /// - Parameter completion: An optional completion block called on the main
    ///   queue with a `cancelled` flag. `cancelled` is `true` for manual
    ///   invalidation, `false` for natural expiration.
    public func schedule(
        timeInterval: TimeInterval,
        completion: ((Bool) -> Void)? = nil
    ) {
        os_log(log, "SleepWakeTimer will activate with time interval %{public}.0f.", timeInterval)

        onActivate?(timeInterval)

        if let completion {
            self.completionBlock = completion
        }

        scheduledTimeInterval = timeInterval
        fireDate = timeInterval != 0
            ? Date(timeIntervalSinceNow: timeInterval)
            : nil

        spawnCaffeinateProcess(forTimeInterval: timeInterval)
    }

    /// Invalidates the timer, terminates the caffeinate process, and resets
    /// all state.
    public func invalidate() {
        fireDate = nil
        scheduledTimeInterval = 0
        terminateCaffeinateProcess()
    }

    // MARK: - Caffeinate Process Handling

    /// Builds the caffeinate command-line arguments for the given time
    /// interval. Internal visibility for testability.
    ///
    /// - Parameter timeInterval: The time interval in seconds. 0 = indefinite.
    /// - Returns: The argument array for `/usr/bin/caffeinate`.
    internal func caffeinateArguments(forTimeInterval timeInterval: TimeInterval) -> [String] {
        let defaults = UserDefaults.standard
        var arguments: [String] = []

        // Display sleep flag selection (preserves Obj-C logic exactly):
        // - `-i` when display sleep is allowed (prevent idle sleep only)
        // - `-di` when display sleep is prevented (prevent idle + display sleep)
        if defaults.kya_allowDisplaySleep {
            arguments.append("-i")
        } else {
            arguments.append("-di")
        }

        // Timeout flag
        if timeInterval != indefiniteTimeInterval {
            arguments.append("-t")
            arguments.append(String(format: "%.0f", timeInterval))
        }

        // Process watch: caffeinate exits when this process terminates
        arguments.append("-w")
        arguments.append(String(ProcessInfo.processInfo.processIdentifier))

        return arguments
    }

    private func spawnCaffeinateProcess(forTimeInterval timeInterval: TimeInterval) {
        let arguments = caffeinateArguments(forTimeInterval: timeInterval)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/caffeinate")
        process.arguments = arguments

        caffeinateProcess = process

        process.terminationHandler = { [weak self] _ in
            self?.handleTermination(cancelled: false)
        }

        do {
            process.run()
        } catch {
            os_log(
                log,
                "Failed to launch caffeinate: %{public}s",
                error.localizedDescription
            )
            handleTermination(cancelled: true)
        }
    }

    private func terminateCaffeinateProcess() {
        caffeinateProcess?.terminationHandler = nil
        caffeinateProcess?.terminate()
        handleTermination(cancelled: true)
    }

    private func handleTermination(cancelled: Bool) {
        caffeinateProcess = nil
        scheduledTimeInterval = 0
        fireDate = nil

        // Capture and nil completion block to prevent double calls
        let completion = completionBlock
        completionBlock = nil

        let deactivate = onDeactivate

        DispatchQueue.main.async {
            completion?(cancelled)
            deactivate?()
        }

        os_log(log, "SleepWakeTimer did deactivate.")
    }
}