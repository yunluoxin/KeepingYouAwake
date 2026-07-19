//
//  MainMenuBuilder.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 12.02.22.
//  Rewritten in Swift from KYAMainMenu.m.
//

import AppKit

/// Builds the application's main menu programmatically.
enum MainMenuBuilder {
    static func build(activationDurationsSubMenu: NSMenu) -> NSMenu {
        let mainMenu = NSMenu(title: "")

        // Read-only status line, refreshed before the menu is shown.
        let statusItem = NSMenuItem(title: "", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        statusItem.tag = MainMenuController.statusItemTag
        mainMenu.addItem(statusItem)

        mainMenu.addItem(NSMenuItem.separator())

        // Master switch toggle (Disable / Enable), title refreshed before show.
        let toggleItem = NSMenuItem(
            title: KYAL10n.disable,
            action: #selector(AppDelegate.toggleMasterSwitch(_:)),
            keyEquivalent: ""
        )
        toggleItem.tag = MainMenuController.toggleItemTag
        if #available(macOS 26.0, *) {
            toggleItem.image = NSImage(systemSymbolName: "power", accessibilityDescription: nil)
        }
        // Target is resolved through the responder chain (nil) so it reaches
        // the AppDelegate, which implements toggleMasterSwitch(_:).
        mainMenu.addItem(toggleItem)

        mainMenu.addItem(NSMenuItem.separator())

        let activateForDuration = NSMenuItem(
            title: KYAL10n.activateForDuration,
            action: nil,
            keyEquivalent: ""
        )
        activateForDuration.tag = MainMenuController.activateItemTag
        if #available(macOS 26.0, *) {
            activateForDuration.image = NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
        }
        activateForDuration.submenu = activationDurationsSubMenu
        mainMenu.addItem(activateForDuration)

        mainMenu.addItem(NSMenuItem.separator())

        let settings = NSMenuItem(
            title: KYAL10n.settingsEllipsis,
            action: #selector(AppDelegate.showSettingsWindow(_:)),
            keyEquivalent: ","
        )
        if #available(macOS 26.0, *) {
            settings.image = NSImage(systemSymbolName: "gear", accessibilityDescription: nil)
        }
        mainMenu.addItem(settings)

        mainMenu.addItem(NSMenuItem.separator())

        let quit = NSMenuItem(
            title: KYAL10n.quit,
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )
        mainMenu.addItem(quit)

        return mainMenu
    }
}
