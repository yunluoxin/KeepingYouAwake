//  SleepWakeTimer.swift
//  KYASleepWakeTimer
//
//  Created by Marcel Dierkes on 07.11.14.
//  Rewritten in Swift from KYASleepWakeTimer.m.
//

import Foundation
import AppKit
import IOKit.pwr_mgt
import KYAApplicationSupport
import KYACommon

/// A time interval value representing indefinite scheduling (no timeout).
/// Pass this value to ``SleepWakeTimer/schedule(timeInterval:completion:)``
/// for indefinite mode where the activation runs until it is invalidated.
public let indefiniteTimeInterval: TimeInterval = 0

/// Manages the sleep/wake state by holding an IOKit power assertion.
///
/// The assertion is held in-process via `ProcessInfo.beginActivity`. macOS 26
/// and later drop *every* power assertion when `powerd` restarts — they clear
/// the whole assertion table without telling the holder — so on those systems
/// the assertion is verified and restored every ``heartbeatInterval`` seconds.
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

    /// Returns `true` if a sleep wake activation is in effect.
    ///
    /// Reflects the *intent* to prevent sleep. The underlying power assertion
    /// is restored within ``heartbeatInterval`` seconds should the system drop it.
    public var isScheduled: Bool {
        activity != nil
    }

    /// An optional completion block called on the main queue when the task
    /// finishes or is invalidated.
    ///
    /// The `cancelled` flag is `true` when manually invalidated via
    /// ``invalidate()``, and `false` when the timer expired naturally.
    public var completionBlock: ((Bool) -> Void)?

    // MARK: - Internal

    /// The power assertion currently held. `nil` when no activation is in effect.
    internal private(set) var activity: NSObjectProtocol?

    /// How often the held assertion is verified and restored if the system dropped it.
    internal static let heartbeatInterval: TimeInterval = 10

    /// Whether the heartbeat is needed on this system.
    ///
    /// macOS 26 and later restart `powerd` regularly, which silently drops
    /// every power assertion. Older systems keep the assertion for the whole
    /// lifetime of the holder, so the heartbeat would only burn CPU there.
    internal static var isHeartbeatRequired: Bool {
        ProcessInfo.processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0)
        )
    }

    /// Name of the power assertion. Shows up in `pmset -g assertions`.
    internal static let assertionReason = "KeepingYouAwake"

    private var fireTimer: Timer?

    /// The heartbeat timer. `nil` when the heartbeat is not needed on this system.
    internal private(set) var heartbeatTimer: Timer?
    private var terminationObserver: NSObjectProtocol?

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

    /// Schedule the sleep wake activation for a given time interval.
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
        KYALog.shared.debug("SleepWakeTimer will activate with time interval \(String(format: "%.0f", timeInterval))", category: "SleepWakeTimer")

        onActivate?(timeInterval)

        if let completion {
            self.completionBlock = completion
        }

        scheduledTimeInterval = timeInterval
        fireDate = timeInterval != 0
            ? Date(timeIntervalSinceNow: timeInterval)
            : nil

        startActivity()
        startHeartbeat()

        if let fireDate {
            startFireTimer(at: fireDate)
        }
    }

    /// Invalidates the timer, releases the power assertion, and resets all state.
    public func invalidate() {
        handleTermination(cancelled: true)
    }

    // MARK: - Power Assertion

    /// The activity options matching the "allow display sleep" setting.
    ///
    /// - `.idleSystemSleepDisabled` keeps the system awake.
    /// - `.idleDisplaySleepDisabled` additionally keeps the display awake.
    internal var activityOptions: ProcessInfo.ActivityOptions {
        var options: ProcessInfo.ActivityOptions = [.idleSystemSleepDisabled]
        if !UserDefaults.standard.kya_allowDisplaySleep {
            options.insert(.idleDisplaySleepDisabled)
        }
        return options
    }

    /// Returns `true` if this process still holds an idle-system-sleep assertion.
    internal func holdsSystemSleepAssertion() -> Bool {
        heldAssertionTypes().contains(kIOPMAssertionTypePreventUserIdleSystemSleep as String)
    }

    /// The assertion types an activation is expected to hold.
    private var expectedAssertionTypes: Set<String> {
        var types: Set<String> = [kIOPMAssertionTypePreventUserIdleSystemSleep as String]
        if !UserDefaults.standard.kya_allowDisplaySleep {
            types.insert(kIOPMAssertionTypePreventUserIdleDisplaySleep as String)
        }
        return types
    }

    /// The assertion types this process currently holds.
    private func heldAssertionTypes() -> Set<String> {
        var assertions: Unmanaged<CFDictionary>?
        guard IOPMCopyAssertionsByProcess(&assertions) == kIOReturnSuccess,
              let byProcess = assertions?.takeRetainedValue() as? [AnyHashable: Any],
              let mine = byProcess[ProcessInfo.processInfo.processIdentifier] as? [[String: Any]]
        else { return [] }

        return Set(mine.compactMap { $0[kIOPMAssertionTypeKey as String] as? String })
    }

    /// Verifies the power assertion is still held and recreates it if the
    /// system dropped it (e.g. after `powerd` restarted).
    internal func verifyAndRearm() {
        guard activity != nil else { return }
        guard !holdsSystemSleepAssertion() else { return }

        KYALog.shared.info("Power assertion was dropped by the system, recreating it", category: "SleepWakeTimer")
        startActivity()
    }

    private func startActivity() {
        endActivity()

        activity = ProcessInfo.processInfo.beginActivity(
            options: activityOptions,
            reason: Self.assertionReason
        )

        if activity == nil {
            KYALog.shared.error("Failed to create power assertion", category: "SleepWakeTimer")
        }
    }

    private func endActivity() {
        guard let activity else { return }

        // The system drops assertions silently when powerd restarts. Ending an
        // already dropped activity would only produce a Foundation warning.
        if !heldAssertionTypes().isDisjoint(with: expectedAssertionTypes) {
            ProcessInfo.processInfo.endActivity(activity)
        }
        self.activity = nil
    }

    // MARK: - Timers

    private func startHeartbeat() {
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil

        guard Self.isHeartbeatRequired else { return }

        let timer = Timer(timeInterval: Self.heartbeatInterval, repeats: true) { [weak self] _ in
            self?.verifyAndRearm()
        }
        RunLoop.main.add(timer, forMode: .common)
        heartbeatTimer = timer
    }

    private func startFireTimer(at date: Date) {
        fireTimer?.invalidate()

        let timer = Timer(fire: date, interval: 0, repeats: false) { [weak self] _ in
            self?.handleTermination(cancelled: false)
        }
        RunLoop.main.add(timer, forMode: .common)
        fireTimer = timer
    }

    // MARK: - Termination

    private func handleTermination(cancelled: Bool) {
        endActivity()

        fireTimer?.invalidate()
        fireTimer = nil
        heartbeatTimer?.invalidate()
        heartbeatTimer = nil

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

        KYALog.shared.debug("SleepWakeTimer did deactivate.", category: "SleepWakeTimer")
    }
}
