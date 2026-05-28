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

    private var startAtLoginCheckBox: NSButton!
    private var activateOnLaunchCheckBox: NSButton!
    private var notificationSettingsButton: NSButton!

    override func loadView() {
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
        activateOnLaunchCheckBox.bind(.value, to: UserDefaults.standard, withKeyPath: UserDefaults.activateOnLaunchKey, options: [.continuouslyUpdatesValue: true])

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
        contentStack.addView(startAtLoginGroup, in: .top)
        contentStack.addView(activateOnLaunchGroup, in: .top)
        contentStack.addView(notificationSettingsButton, in: .top)
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.widthAnchor.constraint(greaterThanOrEqualToConstant: 350).isActive = true

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

        NSLayoutConstraint.activate([
            contentStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 20),
            contentStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 80),
            contentStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            separator.topAnchor.constraint(equalTo: contentStack.bottomAnchor, constant: 16),
            separator.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            separator.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),

            quitButton.topAnchor.constraint(greaterThanOrEqualTo: separator.bottomAnchor, constant: 16),
            quitButton.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            quitButton.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
        ])

        view = containerView
    }

    @objc private func openNotificationSettings() {
        if #available(macOS 11, *) {
            NSWorkspace.shared.openNotificationSettings()
        }
    }

    deinit {
        startAtLoginCheckBox?.unbind(.value)
        activateOnLaunchCheckBox?.unbind(.value)
    }
}