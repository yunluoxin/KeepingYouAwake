//
//  StatusItemController.swift
//  KYAStatusItemUI
//
//  Created by Marcel Dierkes on 10.09.17.
//  Copyright © 2017 Marcel Dierkes. All rights reserved.
//

import AppKit
import KYAApplicationSupport
import KYACommon

/// Data source protocol for providing a menu to the status item controller.
protocol StatusItemControllerDataSource: AnyObject {
    /// The menu that is displayed when the status item is right-clicked.
    func menuForStatusItemController(_ controller: StatusItemController) -> NSMenu?
}

/// Delegate protocol for receiving primary click actions from the status item.
protocol StatusItemControllerDelegate: AnyObject {
    /// Notifies the delegate that the primary click action was invoked.
    func statusItemControllerShouldPerformPrimaryAction(_ controller: StatusItemController)
}

/// Manages the display and interaction with the menu bar status item.
///
/// Inherits from NSObject to support @objc target/action for NSStatusItem.button
/// and KVO compliance for the `appearance` property.
final class StatusItemController: NSObject {
    /// The underlying system status bar item.
    @objc private(set) var systemStatusItem: NSStatusItem

    /// A data source for providing a menu.
    weak var dataSource: StatusItemControllerDataSource?

    /// A delegate for receiving click events.
    weak var delegate: StatusItemControllerDelegate?

    /// Controls the active/inactive appearance of the status item image.
    var appearance: StatusItemAppearance {
        get {
            let provider = StatusItemImageProvider.currentProvider
            return systemStatusItem.button?.image == provider.activeIconImage
                ? .active : .inactive
        }
        set {
            willChangeValue(forKey: "appearance")
            let button = systemStatusItem.button!
            let provider = StatusItemImageProvider.currentProvider

            switch newValue {
            case .active:
                button.image = provider.activeIconImage
                button.toolTip = StatusItemUIL10n.clickToAllowSleep
            case .inactive:
                button.image = provider.inactiveIconImage
                button.toolTip = StatusItemUIL10n.clickToPreventSleep
            }
            didChangeValue(forKey: "appearance")
        }
    }

    override init() {
        // Create the status item and configure properties that don't reference self.
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.highlightMode = !UserDefaults.standard.kya_isMenuBarIconHighlightDisabled

        if statusItem.responds(to: NSSelectorFromString("behavior")) {
            // The `behavior` property was introduced in macOS 10.14.
            statusItem.behavior = .terminationOnRemoval
        }
        if statusItem.responds(to: NSSelectorFromString("isVisible")) {
            // The `isVisible` property was introduced in macOS 10.14.
            statusItem.isVisible = true
        }

        let button = statusItem.button!
        button.sendAction(on: .leftMouseUp.union(.rightMouseUp))

        #if DEBUG
        if #available(macOS 10.14, *) {
            button.contentTintColor = .systemBlue
        }
        // os_log_debug is a C macro unavailable in Swift; use NSLog for DEBUG builds.
        NSLog("[StatusItemUI] Blue status bar item color is enabled for DEBUG builds.")
        #endif

        self.systemStatusItem = statusItem

        // Call super.init() before setting self as button target/action.
        super.init()

        button.target = self
        button.action = #selector(toggleStatus)

        self.appearance = .inactive
    }

    // MARK: - Action

    /// Action method bound to the status item button.
    /// Determines whether to show a menu (right/ctrl/alt click) or
    /// fire the primary action delegate (left click).
    @objc private func toggleStatus() {
        let event = NSApp.currentEvent

        if event?.modifierFlags.contains(.control) == true      // ctrl click
            || event?.modifierFlags.contains(.option) == true   // alt click
            || event?.type == .rightMouseUp                     // right click
        {
            showMenuFromDataSource()
            return
        }

        delegate?.statusItemControllerShouldPerformPrimaryAction(self)
    }

    // MARK: - Menu

    private func showMenuFromDataSource() {
        guard let menu = dataSource?.menuForStatusItemController(self) else { return }
        systemStatusItem.popUpMenu(menu)
    }
}