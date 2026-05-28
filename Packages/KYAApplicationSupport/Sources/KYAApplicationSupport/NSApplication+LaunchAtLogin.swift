//
//  NSApplication+LaunchAtLogin.swift
//  KYAApplicationSupport
//
//  Created by Marcel Dierkes on 25.12.17.
//  Copyright © 2017 Marcel Dierkes. All rights reserved.
//
//  Rewritten in Swift from NSApplication+KYALaunchAtLogin.m.
//

import AppKit
import ServiceManagement

private let launcherBundleIdentifier = "info.marcel-dierkes.KeepingYouAwake.Launcher"

// TODO: Switch to KYALog.shared (from import KYACommon) once KYACommon is rewritten in Swift.
// Using NSLog as a cross-version logging fallback for macOS 10.13+ deployment target.
private func logError(_ message: String) {
    NSLog("KYAApplicationSupport [ApplicationSupport]: ERROR — \(message)")
}

private func logFault(_ message: String) {
    NSLog("KYAApplicationSupport [ApplicationSupport]: FAULT — \(message)")
}

extension NSApplication {
    /// Launches the app at login when enabled.
    ///
    /// On macOS 13 and later this uses `SMAppService.mainApp`.
    /// On older macOS versions this uses the legacy `SMLoginItemSetEnabled` API.
    @objc public var kya_launchAtLoginEnabled: Bool {
        get {
            if #available(macOS 13, *) {
                return Self.appServiceIsEnabled()
            } else {
                return Self.loginItemIsEnabled()
            }
        }
        set {
            if #available(macOS 13, *) {
                Self.appServiceSetEnabled(newValue)
            } else {
                Self.loginItemSetEnabled(newValue)
            }
        }
    }

    /// Migrates the application login service from `SMLoginItemSetEnabled` to
    /// `SMAppService` on macOS 13 and later.
    @available(macOS 13, *)
    @objc public func kya_migrateLaunchAtLoginToAppServiceIfNeeded() {
        guard Self.launchAtLoginUserDefaultsExists() else { return }

        // If the legacy login item was enabled, transfer that state to SMAppService
        if Self.loginItemIsEnabled() {
            Self.loginItemSetEnabled(false)
            Self.appServiceSetEnabled(true)
        }

        // Remove the legacy user default key so migration only runs once
        UserDefaults.standard.removeObject(forKey: UserDefaults.launchAtLoginKey)
    }

    // MARK: - SMAppService (macOS 13+)

    @available(macOS 13, *)
    private static func appServiceIsEnabled() -> Bool {
        let appService = SMAppService.mainApp
        let status = appService.status

        if status == SMAppService.Status.requiresApproval {
            SMAppService.openSystemSettingsLoginItems()
        }

        return status == SMAppService.Status.enabled
    }

    @available(macOS 13, *)
    private static func appServiceSetEnabled(_ enabled: Bool) {
        let appService = SMAppService.mainApp

        if enabled {
            do {
                try appService.register()
            } catch {
                logError("Failed to register launch at login: \(error.localizedDescription)")
            }
        } else {
            do {
                try appService.unregister()
            } catch {
                logError("Failed to unregister launch at login: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Legacy User Default Helpers

    private static func launchAtLoginUserDefaultsExists() -> Bool {
        UserDefaults.standard.object(forKey: UserDefaults.launchAtLoginKey) != nil
    }

    private static func loginItemIsEnabled() -> Bool {
        let enabled = UserDefaults.standard.bool(forKey: UserDefaults.launchAtLoginKey)
        // Use SMLoginItemSetEnabled to sync the legacy login item state
        let success = SMLoginItemSetEnabled(launcherBundleIdentifier as CFString, enabled)
        if !success {
            logFault("Failed to sync legacy login item state to \(enabled ? "enabled" : "disabled")")
        }
        return enabled
    }

    private static func loginItemSetEnabled(_ enabled: Bool) {
        let success = SMLoginItemSetEnabled(launcherBundleIdentifier as CFString, enabled)
        if success {
            UserDefaults.standard.set(enabled, forKey: UserDefaults.launchAtLoginKey)
        } else {
            logFault("Failed to set legacy login item to \(enabled ? "enabled" : "disabled")")
        }
    }
}