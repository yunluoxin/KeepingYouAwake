//
//  AppDelegate.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 17.10.14.
//  Rewritten in Swift from KYAAppDelegate.m.
//

import AppKit
import KYAApplicationSupport

@objc(AppDelegate)
final class AppDelegate: NSObject, NSApplicationDelegate {
    private(set) var appController = AppController()
    @objc private weak var settingsWindow: SettingsWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        #if KYA_APP_UPDATER_ENABLED
        _ = AppUpdater.defaultAppUpdater
        #endif

        if #available(macOS 13.0, *) {
            NSApplication.shared.kya_migrateLaunchAtLoginToAppServiceIfNeeded()
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        guard !flag else { return false }
        // Ignore reopen requests in the first 5 seconds
        let launchDate = NSRunningApplication.current.launchDate ?? Date()
        guard launchDate.addingTimeInterval(5.0) < Date() else { return false }
        showSettingsWindow(sender)
        return false
    }

    @objc func showSettingsWindow(_ sender: Any?) {
        if #available(macOS 14.0, *) {
            NSApplication.shared.activate()
        } else {
            NSApplication.shared.activate(ignoringOtherApps: true)
        }

        if let window = settingsWindow {
            window.makeKeyAndOrderFront(sender)
            return
        }

        var additionalTabViewItems: [NSTabViewItem] = []
        #if KYA_APP_UPDATER_ENABLED
        additionalTabViewItems = [UpdateSettingsViewController.preferredTabViewItem]
        #endif

        let window = SettingsWindow(additionalTabViewItems: additionalTabViewItems)
        settingsWindow = window
        window.makeKeyAndOrderFront(sender)
    }
}