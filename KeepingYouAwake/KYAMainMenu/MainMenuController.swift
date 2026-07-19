//
//  MainMenuController.swift
//  KeepingYouAwake
//
//  Refreshes the dynamic main-menu items (status line, master-switch
//  toggle title, Activate-for-Duration availability) each time the menu
//  is about to be shown.
//

import AppKit

/// Delegate for the main status menu. Keeps the read-only status line and
/// the master-switch toggle in sync with the live app state.
final class MainMenuController: NSObject, NSMenuDelegate {
    /// Tags used to locate the dynamic items built by MainMenuBuilder.
    static let statusItemTag = 1001
    static let toggleItemTag = 1002
    static let activateItemTag = 1003

    /// Closure-based state queries supplied by the AppController.
    var isEnabled: (() -> Bool)?
    var isActive: (() -> Bool)?
    var activationReason: (() -> String?)?

    func menuNeedsUpdate(_ menu: NSMenu) {
        let enabled = isEnabled?() ?? true
        let active = isActive?() ?? false

        if let statusItem = menu.item(withTag: Self.statusItemTag) {
            statusItem.title = statusTitle(enabled: enabled, active: active)
        }
        if let toggleItem = menu.item(withTag: Self.toggleItemTag) {
            toggleItem.title = enabled ? KYAL10n.disable : KYAL10n.enable
        }
        if let activateItem = menu.item(withTag: Self.activateItemTag) {
            // Master switch off: no way to activate for a duration.
            activateItem.isEnabled = enabled
        }
    }

    private func statusTitle(enabled: Bool, active: Bool) -> String {
        guard enabled else { return KYAL10n.statusDisabled }
        guard active else { return KYAL10n.statusIdle }
        if let reason = activationReason?() {
            return KYAL10n.statusActiveReason(reason)
        }
        return KYAL10n.statusActive
    }
}
