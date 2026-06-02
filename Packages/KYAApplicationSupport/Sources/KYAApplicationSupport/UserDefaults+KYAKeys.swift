//
//  UserDefaults+KYAKeys.swift
//  KYAApplicationSupport
//
//  Created by Marcel Dierkes on 25.10.15.
//  Copyright © 2015 Marcel Dierkes. All rights reserved.
//
//  Rewritten in Swift from NSUserDefaults+KYAKeys.m.
//

import Foundation

// MARK: - UserDefaults Key Constants
//
// These key strings preserve the exact "info.marcel-dierkes.KeepingYouAwake.XXX"
// format for backwards compatibility with existing stored preferences.

extension UserDefaults {
    // Bool property keys
    public static let activateOnLaunchKey = "info.marcel-dierkes.KeepingYouAwake.ActivateOnLaunch"
    public static let allowDisplaySleepKey = "info.marcel-dierkes.KeepingYouAwake.AllowDisplaySleep"
    public static let menuBarIconHighlightDisabledKey = "info.marcel-dierkes.KeepingYouAwake.MenuBarIconHighlightDisabled"
    public static let batteryCapacityThresholdEnabledKey = "info.marcel-dierkes.KeepingYouAwake.BatteryCapacityThresholdEnabled"
    public static let lowPowerModeMonitoringEnabledKey = "info.marcel-dierkes.KeepingYouAwake.LowPowerModeMonitoringEnabled"
    public static let preReleaseUpdatesEnabledKey = "info.marcel-dierkes.KeepingYouAwake.PreReleaseUpdatesEnabled"
    public static let quitOnTimerExpirationEnabledKey = "info.marcel-dierkes.KeepingYouAwake.IsQuitOnTimerExpirationEnabled"
    public static let activateOnExternalDisplayConnectedEnabledKey = "info.marcel-dierkes.KeepingYouAwake.ActivateOnExternalDisplayConnectedEnabled"
    public static let deactivateOnUserSwitchEnabledKey = "info.marcel-dierkes.KeepingYouAwake.DeactivateOnUserSwitchEnabled"
    public static let processMonitoringEnabledKey = "info.marcel-dierkes.KeepingYouAwake.ProcessMonitoringEnabled"

    // Special property keys
    public static let batteryCapacityThresholdKey = "info.marcel-dierkes.KeepingYouAwake.BatteryCapacityThreshold"
    public static let processNamesKey = "info.marcel-dierkes.KeepingYouAwake.ProcessNames"

    // Legacy launch-at-login key (used by migration logic in NSApplication+LaunchAtLogin)
    static let launchAtLoginKey = "info.marcel-dierkes.KeepingYouAwake.LaunchAtLogin"

    // MARK: - Bool Properties

    /// Returns true if the sleep wake timer should be activated on app launch.
    @objc public var kya_activateOnLaunch: Bool {
        get { bool(forKey: UserDefaults.activateOnLaunchKey) }
        set { set(newValue, forKey: UserDefaults.activateOnLaunchKey) }
    }

    /// Returns true if the app should allow the display to sleep while still
    /// keeping the system awake. This exposes the `caffeinate -i` command.
    @objc public var kya_allowDisplaySleep: Bool {
        get { bool(forKey: UserDefaults.allowDisplaySleepKey) }
        set { set(newValue, forKey: UserDefaults.allowDisplaySleepKey) }
    }

    /// Returns true if the menu bar icon should not be highlighted on left and right click.
    @objc public var kya_menuBarIconHighlightDisabled: Bool {
        get { bool(forKey: UserDefaults.menuBarIconHighlightDisabledKey) }
        set { set(newValue, forKey: UserDefaults.menuBarIconHighlightDisabledKey) }
    }

    /// Returns true if the sleep wake timer should deactivate below a defined battery capacity threshold.
    @objc public var kya_batteryCapacityThresholdEnabled: Bool {
        get { bool(forKey: UserDefaults.batteryCapacityThresholdEnabledKey) }
        set { set(newValue, forKey: UserDefaults.batteryCapacityThresholdEnabledKey) }
    }

    /// Returns true if the sleep wake timer should deactivate when Low Power Mode is enabled.
    @objc public var kya_lowPowerModeMonitoringEnabled: Bool {
        get { bool(forKey: UserDefaults.lowPowerModeMonitoringEnabledKey) }
        set { set(newValue, forKey: UserDefaults.lowPowerModeMonitoringEnabledKey) }
    }

    /// Returns true if Sparkle should check for pre-release updates.
    @objc public var kya_preReleaseUpdatesEnabled: Bool {
        get { bool(forKey: UserDefaults.preReleaseUpdatesEnabledKey) }
        set { set(newValue, forKey: UserDefaults.preReleaseUpdatesEnabledKey) }
    }

    /// Returns true if the app should quit when the sleep wake timer expires.
    @objc public var kya_quitOnTimerExpirationEnabled: Bool {
        get { bool(forKey: UserDefaults.quitOnTimerExpirationEnabledKey) }
        set { set(newValue, forKey: UserDefaults.quitOnTimerExpirationEnabledKey) }
    }

    /// Returns true if the app should activate when an external display is connected.
    @objc public var kya_activateOnExternalDisplayConnectedEnabled: Bool {
        get { bool(forKey: UserDefaults.activateOnExternalDisplayConnectedEnabledKey) }
        set { set(newValue, forKey: UserDefaults.activateOnExternalDisplayConnectedEnabledKey) }
    }

    /// Returns true if the app should deactivate when the user account is switched.
    @objc public var kya_deactivateOnUserSwitchEnabled: Bool {
        get { bool(forKey: UserDefaults.deactivateOnUserSwitchEnabledKey) }
        set { set(newValue, forKey: UserDefaults.deactivateOnUserSwitchEnabledKey) }
    }

    /// Returns true if the app should activate when specified processes are running.
    @objc public var kya_processMonitoringEnabled: Bool {
        get { bool(forKey: UserDefaults.processMonitoringEnabledKey) }
        set { set(newValue, forKey: UserDefaults.processMonitoringEnabledKey) }
    }

    // MARK: - Battery Capacity Threshold

    /// A battery capacity threshold.
    ///
    /// If the stored value is below 10.0, 10.0 will be returned.
    /// Values are stored as Float to match the original Obj-C implementation.
    @objc public var kya_batteryCapacityThreshold: Double {
        get { max(10.0, Double(float(forKey: UserDefaults.batteryCapacityThresholdKey))) }
        set { set(Float(newValue), forKey: UserDefaults.batteryCapacityThresholdKey) }
    }

    // MARK: - Process Names

    /// A comma-separated list of process names to monitor for sleep prevention.
    /// Matches the executable name or any exact path component (case-insensitive),
    /// e.g. "node" matches ".../node" and "cursor-agent" matches ".../cursor-agent/.../node".
    @objc public var kya_processNames: String? {
        get { string(forKey: UserDefaults.processNamesKey) }
        set { set(newValue, forKey: UserDefaults.processNamesKey) }
    }
}