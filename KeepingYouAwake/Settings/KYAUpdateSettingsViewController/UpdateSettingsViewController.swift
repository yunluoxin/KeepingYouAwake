//
//  UpdateSettingsViewController.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 30.12.17.
//  Rewritten in Swift from KYAUpdateSettingsViewController.m.
//

#if KYA_APP_UPDATER_ENABLED

import AppKit
import KYAApplicationSupport

final class UpdateSettingsViewController: SettingsContentViewController {
    override class var tabViewItemImage: NSImage? {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "network", accessibilityDescription: nil)
        } else {
            return NSImage(named: NSImageNameNetwork)
        }
    }

    override class var preferredTitle: String? { KYAL10nSettings.updates }

    private lazy var automaticallyCheckCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: NSLocalizedString("Automatically Check for Updates", tableName: "KYASettings", bundle: .main, value: "Automatically Check for Updates", comment: "Automatically Check for Updates"), target: nil, action: nil)
        checkbox.setButtonType(.switch)
        checkbox.bind(NSBindingName.value,
                      to: AppUpdater.defaultAppUpdater.updater,
                      withKeyPath: "automaticallyChecksForUpdates",
                      options: [.raisesForNotApplicableKeys: true])
        return checkbox
    }()

    private lazy var preReleaseCheckbox: NSButton = {
        let checkbox = NSButton(checkboxWithTitle: NSLocalizedString("Check for Pre-Release Updates", tableName: "KYASettings", bundle: .main, value: "Check for Pre-Release Updates", comment: "Check for Pre-Release Updates"), target: nil, action: nil)
        checkbox.setButtonType(.switch)
        checkbox.bind(NSBindingName.value,
                      to: UserDefaults.standard,
                      withKeyPath: UserDefaults.preReleaseUpdatesEnabledKey,
                      options: [.raisesForNotApplicableKeys: true])
        return checkbox
    }()

    private lazy var checkNowButton: NSButton = {
        let button = NSButton(title: NSLocalizedString("Check Now", tableName: "KYASettings", bundle: .main, value: "Check Now", comment: "Check Now"), target: self, action: #selector(checkForUpdates(_:)))
        button.bezelStyle = .rounded
        button.keyEquivalent = "\r"
        return button
    }()

    private lazy var iconImageView: NSImageView = {
        let imageView = NSImageView()
        imageView.image = NSImage(named: NSImageNameRefreshFreestandingTemplate)
        imageView.imageScaling = .scaleProportionallyUpOrDown
        imageView.isEditable = false
        imageView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        imageView.setContentHuggingPriority(.defaultLow, for: .vertical)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.widthAnchor.constraint(equalToConstant: 96).isActive = true
        imageView.heightAnchor.constraint(equalToConstant: 96).isActive = true
        return imageView
    }()

    private lazy var contentBox: NSBox = {
        let box = NSBox()
        box.boxType = .primary
        box.titlePosition = .noTitle
        box.contentView = contentStackView
        box.translatesAutoresizingMaskIntoConstraints = false
        box.heightAnchor.constraint(equalToConstant: 150).isActive = true
        return box
    }()

    private lazy var contentStackView: NSStackView = {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.edgeInsets = NSEdgeInsets(top: 22, left: 20, bottom: 22, right: 22)
        stack.spacing = 16
        stack.addView(automaticallyCheckCheckbox, in: .top)
        stack.addView(preReleaseCheckbox, in: .top)
        stack.addView(checkNowButton, in: .bottom)
        return stack
    }()

    override func loadView() {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        container.addSubview(iconImageView)
        container.addSubview(contentBox)

        NSLayoutConstraint.activate([
            iconImageView.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 20),
            iconImageView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            iconImageView.topAnchor.constraint(greaterThanOrEqualTo: container.topAnchor, constant: 20),

            contentBox.topAnchor.constraint(equalTo: container.topAnchor, constant: -2),
            contentBox.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -2),
            contentBox.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -2),
            contentBox.leadingAnchor.constraint(equalTo: iconImageView.trailingAnchor, constant: 20),
        ])

        view = container
    }

    @objc private func checkForUpdates(_ sender: Any?) {
        AppUpdater.defaultAppUpdater.checkForUpdates(sender)
    }

    deinit {
        automaticallyCheckCheckbox.unbind(NSBindingName.value)
        preReleaseCheckbox.unbind(NSBindingName.value)
    }
}

#endif