//
//  SettingsWindow.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 18.06.23.
//  Rewritten in Swift from KYASettingsWindow.m.
//

import AppKit

/// Settings window using NSTabViewController with toolbar tab style.
/// All programmatic — no NIB.
final class SettingsWindow: NSWindow {
    init(additionalTabViewItems: [NSTabViewItem] = []) {
        var tabViewItems: [NSTabViewItem] = [
            GeneralSettingsViewController.preferredTabViewItem,
            DurationSettingsViewController.preferredTabViewItem,
            BatterySettingsViewController.preferredTabViewItem,
            AdvancedSettingsViewController.preferredTabViewItem,
        ]
        tabViewItems.append(contentsOf: additionalTabViewItems)
        tabViewItems.append(AboutSettingsViewController.preferredTabViewItem)

        let tabViewController = NSTabViewController()
        tabViewController.tabStyle = .toolbar
        tabViewController.transitionOptions = NSViewController.TransitionOptions()
        tabViewController.tabViewItems = tabViewItems

        let frame = NSRect(x: 150, y: 430, width: 480, height: 320)
        let styleMask: NSWindow.StyleMask = [.titled, .closable]
        let behavior: NSWindow.CollectionBehavior = [.managed, .participatesInCycle, .fullScreenNone]

        super.init(contentRect: frame, styleMask: styleMask, backing: .buffered, defer: false)

        isReleasedWhenClosed = false
        contentViewController = tabViewController
        collectionBehavior = behavior
        title = KYAL10nSettings.title
        setFrame(frame, display: false)
        setFrameAutosaveName("PreferencesWindow")
    }

    // MARK: - Keyboard Handling

    override func keyDown(with event: NSEvent) {
        guard event.type == .keyDown else { return }
        guard event.modifierFlags.contains(.command) else { return }

        if event.characters == "q" {
            NSApplication.shared.terminate(self)
            return
        }
        if event.characters == "w" {
            close()
            return
        }

        super.keyDown(with: event)
    }
}