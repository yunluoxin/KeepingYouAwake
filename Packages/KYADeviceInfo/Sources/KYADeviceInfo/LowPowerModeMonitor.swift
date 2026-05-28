//
//  LowPowerModeMonitor.swift
//  KYADeviceInfo
//
//  Created by Marcel Dierkes on 2026-05-28.
//  Rewritten from KYALowPowerModeMonitor.m
//

import Foundation

/// Notification name for Low Power Mode state changes.
/// Hardcoded string for macOS 10.13 deployment target compatibility;
/// `ProcessInfo.powerStateDidChangeNotification` is macOS 12+ and
/// not visible to the compiler at the lower deployment target.
/// This notification name is only observed when `supportsLowPowerMode` returns true
/// (i.e., macOS 12+), so the underlying Apple notification is always available at runtime.
private let powerStateDidChangeNotification = Notification.Name("com.apple.processInfo.powerStateDidChange")

/// Monitors the status of the device's Low Power Mode.
public final class LowPowerModeMonitor: Monitor {
    /// Whether the current device supports Low Power Mode (macOS 12+).
    public var supportsLowPowerMode: Bool {
        if #available(macOS 12.0, *) {
            return true
        }
        return false
    }

    /// Whether Low Power Mode is currently enabled.
    public var isLowPowerModeEnabled: Bool {
        if #available(macOS 12.0, *) {
            return ProcessInfo.processInfo.isLowPowerModeEnabled
        }
        return false
    }

    // MARK: - Monitor Protocol

    /// Whether the monitor is registered for Low Power Mode change notifications.
    public private(set) var isRegistered: Bool = false

    /// Registers for Low Power Mode state change notifications (macOS 12+).
    /// On systems that do not support Low Power Mode, this is a no-op.
    public func register() {
        guard !isRegistered else { return }
        guard supportsLowPowerMode else { return }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handlePowerStateDidChange),
            name: powerStateDidChangeNotification,
            object: nil
        )
        isRegistered = true
    }

    /// Unregisters from Low Power Mode state change notifications.
    public func unregister() {
        guard isRegistered else { return }

        NotificationCenter.default.removeObserver(
            self,
            name: powerStateDidChangeNotification,
            object: nil
        )
        isRegistered = false
    }

    /// Called when Low Power Mode status changes. Invokes `onLowPowerModeChange` on the main queue.
    public var onLowPowerModeChange: ((Bool) -> Void)?

    // MARK: - Private

    @objc private func handlePowerStateDidChange(_ notification: Notification) {
        let enabled = isLowPowerModeEnabled
        guard let handler = onLowPowerModeChange else { return }
        DispatchQueue.main.async {
            handler(enabled)
        }
    }

    deinit {
        unregister()
    }
}