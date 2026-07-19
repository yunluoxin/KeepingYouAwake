//
//  GeneralSettingsViewController.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 20.09.21.
//  Rewritten in Swift from KYAGeneralSettingsViewController.m.
//

import AppKit
import KYAApplicationSupport
import KYAUserNotifications
import SnapKit

final class GeneralSettingsViewController: SettingsContentViewController {
    override class var tabViewItemImage: NSImage? {
        if #available(macOS 11, *) {
            return NSImage(systemSymbolName: "gearshape", accessibilityDescription: nil)
        }
        return NSImage(named: NSImage.preferencesGeneralName)
    }

    override class var preferredTitle: String? {
        KYAL10nSettings.general
    }

    private var masterEnableCheckBox: NSButton!
    private var startAtLoginCheckBox: NSButton!
    private var activateOnLaunchCheckBox: NSButton!
    private var notificationSettingsButton: NSButton!

    override func loadView() {
        // Master switch: the persistent "real off". When unchecked the app is
        // fully inert regardless of every other preference.
        masterEnableCheckBox = NSButton(checkboxWithTitle: NSLocalizedString("Enable KeepingYouAwake", tableName: "Localizable", bundle: .main, value: "Enable KeepingYouAwake", comment: "Enable KeepingYouAwake"), target: nil, action: nil)
        masterEnableCheckBox.bind(.value, to: NSUserDefaultsController.shared, withKeyPath: "values.\(UserDefaults.enabledKey)", options: [.continuouslyUpdatesValue: true])
        masterEnableCheckBox.font = NSFont.boldSystemFont(ofSize: NSFont.systemFontSize)

        let masterEnableDescription = NSTextField(labelWithString: NSLocalizedString("The master switch. When off, the app does nothing: no sleep prevention and no monitoring.", tableName: "Localizable", bundle: .main, value: "The master switch. When off, the app does nothing: no sleep prevention and no monitoring.", comment: "The master switch. When off, the app does nothing."))
        masterEnableDescription.font = NSFont.messageFont(ofSize: 11)
        masterEnableDescription.textColor = .secondaryLabelColor

        let masterEnableGroup = NSStackView()
        masterEnableGroup.orientation = .vertical
        masterEnableGroup.alignment = .leading
        masterEnableGroup.addView(masterEnableCheckBox, in: .top)
        masterEnableGroup.addView(masterEnableDescription, in: .top)

        startAtLoginCheckBox = NSButton(checkboxWithTitle: NSLocalizedString("Start at Login", tableName: "KYAGeneralSettingsViewController", bundle: .main, value: "Start at Login", comment: "Class = \"NSButtonCell\"; title = \"Start at Login\"; ObjectID = \"YWD-DY-pgf\";"), target: nil, action: nil)
        startAtLoginCheckBox.bind(.value, to: NSApplication.shared, withKeyPath: "kya_launchAtLoginEnabled", options: [.raisesForNotApplicableKeys: true, .conditionallySetsEnabled: true])

        let startAtLoginDescription = NSTextField(labelWithString: NSLocalizedString("Automatically opens the app when you start your Mac.", tableName: "KYAGeneralSettingsViewController", bundle: .main, value: "Automatically opens the app when you start your Mac.", comment: "Class = \"NSTextFieldCell\"; title = \"Automatically opens the app when you start your Mac.\"; ObjectID = \"jxf-J8-dHN\";"))
        startAtLoginDescription.font = NSFont.messageFont(ofSize: 11)
        startAtLoginDescription.textColor = .secondaryLabelColor

        let startAtLoginGroup = NSStackView()
        startAtLoginGroup.orientation = .vertical
        startAtLoginGroup.alignment = .leading
        startAtLoginGroup.addView(startAtLoginCheckBox, in: .top)
        startAtLoginGroup.addView(startAtLoginDescription, in: .top)

        activateOnLaunchCheckBox = NSButton(checkboxWithTitle: NSLocalizedString("Activate on Launch", tableName: "KYAGeneralSettingsViewController", bundle: .main, value: "Activate on Launch", comment: "Class = \"NSButtonCell\"; title = \"Activate on Launch\"; ObjectID = \"zql-rZ-9xH\";"), target: nil, action: nil)
        activateOnLaunchCheckBox.bind(.value, to: NSUserDefaultsController.shared, withKeyPath: "values.\(UserDefaults.activateOnLaunchKey)", options: [.continuouslyUpdatesValue: true])
        // Subordinate to the master switch: grayed out while the app is disabled.
        activateOnLaunchCheckBox.bind(.enabled, to: NSUserDefaultsController.shared, withKeyPath: "values.\(UserDefaults.enabledKey)", options: [.continuouslyUpdatesValue: true])

        let activateOnLaunchDescription = NSTextField(labelWithString: NSLocalizedString("Immediately starts preventing sleep when launched.", tableName: "KYAGeneralSettingsViewController", bundle: .main, value: "Immediately starts preventing sleep when launched.", comment: "Class = \"NSTextFieldCell\"; title = \"Immediately starts preventing sleep when launched.\"; ObjectID = \"7QN-oX-fJU\";"))
        activateOnLaunchDescription.font = NSFont.messageFont(ofSize: 11)
        activateOnLaunchDescription.textColor = .secondaryLabelColor

        let activateOnLaunchGroup = NSStackView()
        activateOnLaunchGroup.orientation = .vertical
        activateOnLaunchGroup.alignment = .leading
        activateOnLaunchGroup.addView(activateOnLaunchCheckBox, in: .top)
        activateOnLaunchGroup.addView(activateOnLaunchDescription, in: .top)

        notificationSettingsButton = NSButton(title: NSLocalizedString("Notification Settings…", tableName: "KYAGeneralSettingsViewController", bundle: .main, value: "Notification Settings…", comment: "Class = \"NSButtonCell\"; title = \"Notification Settings…\"; ObjectID = \"7dk-Tj-9aG\";"), target: self, action: #selector(openNotificationSettings))
        notificationSettingsButton.bezelStyle = .rounded
        if #available(macOS 11, *) {
            notificationSettingsButton.isHidden = false
        } else {
            notificationSettingsButton.isHidden = true
        }

        let contentStack = NSStackView()
        contentStack.orientation = .vertical
        contentStack.alignment = .leading
        contentStack.spacing = 16
        contentStack.addView(masterEnableGroup, in: .top)
        contentStack.addView(startAtLoginGroup, in: .top)
        contentStack.addView(activateOnLaunchGroup, in: .top)
        contentStack.addView(notificationSettingsButton, in: .top)
        contentStack.snp.makeConstraints { make in
            make.width.greaterThanOrEqualTo(350)
        }

        let separator = NSBox()
        separator.boxType = .separator

        let quitButton = NSButton(title: NSLocalizedString("Quit", tableName: "KYAGeneralSettingsViewController", bundle: .main, value: "Quit", comment: "Class = \"NSButtonCell\"; title = \"Quit\"; ObjectID = \"IGL-ft-k8h\";"), target: NSApplication.shared, action: #selector(NSApplication.terminate))
        quitButton.bezelStyle = .rounded
        quitButton.keyEquivalent = "q"
        quitButton.keyEquivalentModifierMask = .command

        let containerView = NSView()
        containerView.addSubview(contentStack)
        containerView.addSubview(separator)
        containerView.addSubview(quitButton)

        contentStack.snp.makeConstraints { make in
            make.top.equalTo(containerView).offset(20)
            make.leading.equalTo(containerView).offset(80)
            make.trailing.equalTo(containerView).offset(-20)
        }

        separator.snp.makeConstraints { make in
            make.top.equalTo(contentStack.snp.bottom).offset(16)
            make.leading.equalTo(containerView).offset(20)
            make.trailing.equalTo(containerView).offset(-20)
        }

        quitButton.snp.makeConstraints { make in
            make.top.greaterThanOrEqualTo(separator.snp.bottom).offset(16)
            make.bottom.equalTo(containerView).offset(-20)
            make.trailing.equalTo(containerView).offset(-20)
        }

        view = containerView
    }

    @objc private func openNotificationSettings() {
        if #available(macOS 11, *) {
            NSWorkspace.shared.openNotificationSettings()
        }
    }

    deinit {
        masterEnableCheckBox?.unbind(.value)
        startAtLoginCheckBox?.unbind(.value)
        activateOnLaunchCheckBox?.unbind(.value)
        activateOnLaunchCheckBox?.unbind(.enabled)
    }
}