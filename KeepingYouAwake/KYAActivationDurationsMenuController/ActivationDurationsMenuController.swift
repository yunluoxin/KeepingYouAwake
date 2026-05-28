//
//  ActivationDurationsMenuController.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 07.08.19.
//  Rewritten in Swift from KYAActivationDurationsMenuController.m.
//

import AppKit
import KYAActivationDurations
import KYAUserNotifications
import KYACommon

/// Manages the activation durations submenu using closures instead of delegates.
final class ActivationDurationsMenuController: NSObject, NSMenuDelegate {
    let activationDurationsController = ActivationDurationsController.shared
    private(set) var menu: NSMenu!

    // Closure-based communication (replaces delegate pattern)
    var onSelectDuration: ((ActivationDuration) -> Void)?
    var onGetFireDate: ((ActivationDurationsMenuController) -> Date?)?
    var onGetCurrentDuration: ((ActivationDurationsMenuController) -> ActivationDuration?)?

    private static let remainingTimeTag = 666
    private static let menuItemFontSize: CGFloat = 14.0

    override init() {
        super.init()
        menu = NSMenu(title: KYAL10n.activateForDuration)
        menu.delegate = self
    }

    @objc func selectActivationDuration(_ sender: NSMenuItem?) {
        guard let sender else { return }
        let seconds = TimeInterval(sender.tag)
        let duration = ActivationDuration(seconds: seconds)
        onSelectDuration?(duration)
    }

    @objc func setDefaultActivationDuration(_ sender: NSMenuItem?) {
        guard let sender else { return }
        let seconds = TimeInterval(sender.tag)
        let durations = activationDurationsController.activationDurations
        let matching = durations.first(where: { $0.seconds == seconds })
        activationDurationsController.defaultActivationDuration = matching
    }

    // MARK: - Menu Item Helpers

    private func attributedTitle(_ title: String, isDefault: Bool) -> NSAttributedString {
        let font = NSFont.monospacedDigitSystemFont(ofSize: Self.menuItemFontSize, weight: .regular)
        let result = NSMutableAttributedString()

        result.append(NSAttributedString(string: "\(title) ", attributes: [.font: font]))

        if isDefault {
            let defaultColor: NSColor
            if #available(macOS 11.0, *) {
                defaultColor = .secondaryLabelColor
            } else {
                defaultColor = .tertiaryLabelColor
            }
            result.append(NSAttributedString(
                string: KYAL10n.isDefaultSuffix,
                attributes: [.font: font, .foregroundColor: defaultColor]
            ))
        }

        return result.copy() as! NSAttributedString
    }

    private func menuItemForRemainingTime() -> NSMenuItem? {
        guard let fireDate = onGetFireDate?(self) else { return nil }
        let item = NSMenuItem(title: fireDate.localizedRemainingTime, action: nil, keyEquivalent: "")
        item.tag = Self.remainingTimeTag
        return item
    }

    // MARK: - NSMenuDelegate

    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()

        let controller = activationDurationsController

        if let remainingItem = menuItemForRemainingTime() {
            menu.addItem(remainingItem)
            menu.addItem(NSMenuItem.separator())
        }

        let defaultDuration = controller.defaultActivationDuration
        let currentDuration = onGetCurrentDuration?(self)

        for duration in controller.activationDurations {
            let title = duration.localizedTitle
            let isDefault = defaultDuration == duration

            let menuItem = menu.addItem(
                withTitle: title,
                action: #selector(selectActivationDuration(_:)),
                keyEquivalent: ""
            )
            menuItem.target = self
            menuItem.tag = Int(duration.seconds)
            menuItem.attributedTitle = attributedTitle(title, isDefault: isDefault)

            // Alternate item for "Set Default"
            let alternateTitle = KYAL10n.setDefaultActivationDuration(title)
            let alternateItem = menu.addItem(
                withTitle: alternateTitle,
                action: #selector(setDefaultActivationDuration(_:)),
                keyEquivalent: ""
            )
            alternateItem.target = self
            alternateItem.isAlternate = true
            alternateItem.keyEquivalentModifierMask = .option
            alternateItem.tag = Int(duration.seconds)

            // Mark currently scheduled duration
            if let current = currentDuration, current == duration {
                menuItem.state = .on
                alternateItem.state = .on
            }
        }
    }
}