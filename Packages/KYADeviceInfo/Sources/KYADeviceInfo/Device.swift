//
//  Device.swift
//  KYADeviceInfo
//
//  Created by Marcel Dierkes on 2026-05-28.
//  Rewritten from KYADevice.m
//

import Foundation

/// Parameters that can change on the device, replacing the former
/// string-based `KYADeviceParameter` constants.
public enum DeviceParameter: String {
    /// Battery capacity changed.
    case batteryCapacity
    /// Low Power Mode was enabled or disabled.
    case lowPowerMode
    /// An external display was connected or disconnected.
    case externalDisplay
}

/// Provides access to physical device parameters, like battery status,
/// Low Power Mode, and process monitoring.
public final class Device {
    /// The singleton instance representing the current device.
    public static let current = Device()

    // MARK: - Monitors

    /// The battery status monitor.
    public let batteryMonitor = BatteryMonitor()

    /// The Low Power Mode monitor.
    public let lowPowerModeMonitor = LowPowerModeMonitor()

    /// The process monitor for CLI tool tracking.
    public let processMonitor = ProcessMonitor()

    // MARK: - Battery Monitoring

    /// Whether battery monitoring is enabled.
    public var isBatteryMonitoringEnabled: Bool {
        batteryMonitor.isRegistered
    }

    /// Enables or disables battery monitoring.
    /// Monitoring is not enabled if the device has no battery.
    public var batteryMonitoringEnabled: Bool {
        get { batteryMonitor.isRegistered }
        set {
            if newValue {
                guard batteryMonitor.hasBattery else { return }
                batteryMonitor.onCapacityChange = { [weak self] capacity in
                    guard let self, self.isBatteryMonitoringEnabled else { return }
                    self.notifyParameterChange(.batteryCapacity)
                }
                batteryMonitor.register()
            } else {
                batteryMonitor.unregister()
                batteryMonitor.onCapacityChange = nil
            }
            NSLog("[DeviceInfo] Battery Monitoring: %@", newValue ? "YES" : "NO")
        }
    }

    // MARK: - Low Power Mode Monitoring

    /// Whether Low Power Mode monitoring is enabled.
    public var isLowPowerModeMonitoringEnabled: Bool {
        lowPowerModeMonitor.isRegistered
    }

    /// Enables or disables Low Power Mode monitoring.
    /// Monitoring is not enabled if the device does not support it.
    public var lowPowerModeMonitoringEnabled: Bool {
        get { lowPowerModeMonitor.isRegistered }
        set {
            if newValue {
                guard lowPowerModeMonitor.supportsLowPowerMode else { return }
                lowPowerModeMonitor.onLowPowerModeChange = { [weak self] enabled in
                    guard let self, self.isLowPowerModeMonitoringEnabled else { return }
                    self.notifyParameterChange(.lowPowerMode)
                }
                lowPowerModeMonitor.register()
            } else {
                lowPowerModeMonitor.unregister()
                lowPowerModeMonitor.onLowPowerModeChange = nil
            }
            NSLog("[DeviceInfo] Low Power Mode Monitoring: %@", newValue ? "YES" : "NO")
        }
    }

    // MARK: - Process Monitoring

    /// Whether process monitoring is enabled.
    public var isProcessMonitoringEnabled: Bool {
        processMonitor.isRegistered
    }

    /// Enables or disables process monitoring for tracked CLI processes.
    public var processMonitoringEnabled: Bool {
        get { processMonitor.isRegistered }
        set {
            if newValue {
                processMonitor.onProcessChange = { [weak self] isRunning, paths in
                    guard let self else { return }
                    self.onProcessMonitoringChange?()
                }
                processMonitor.register()
            } else {
                processMonitor.unregister()
                processMonitor.onProcessChange = nil
            }
            NSLog("[DeviceInfo] Process Monitoring: %@", newValue ? "YES" : "NO")
        }
    }

    // MARK: - Callbacks

    /// Called when a device parameter changes (battery, low power mode, etc).
    /// Replaces the former `KYADeviceParameterDidChangeNotification`.
    public var onChange: ((DeviceParameter) -> Void)?

    /// Called when the process monitoring state changes (a tracked process starts or exits).
    public var onProcessMonitoringChange: (() -> Void)?

    // MARK: - Private

    private static let logSubsystem = "info.marcel-dierkes.KeepingYouAwake"

    private init() {}

    /// Internal for testing; called when a device parameter changes.
    func notifyParameterChange(_ parameter: DeviceParameter) {
        DispatchQueue.main.async {
            self.onChange?(parameter)
        }
    }
}