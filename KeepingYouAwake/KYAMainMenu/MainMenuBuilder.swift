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

        let activateForDuration = NSMenuItem(
            title: KYAL10n.activateForDuration,
            action: nil,
            keyEquivalent: ""
        )
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