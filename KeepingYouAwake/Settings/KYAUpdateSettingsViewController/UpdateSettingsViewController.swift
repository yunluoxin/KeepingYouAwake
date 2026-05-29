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
import SnapKit

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
                      to: NSUserDefaultsController.shared,
                      withKeyPath: "values.\(UserDefaults.preReleaseUpdatesEnabledKey)",
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
        imageView.snp.makeConstraints { make in
            make.width.height.equalTo(96)
        }
        return imageView
    }()

    private lazy var contentBox: NSBox = {
        let box = NSBox()
        box.boxType = .primary
        box.titlePosition = .noTitle
        box.contentView = contentStackView
        box.snp.makeConstraints { make in
            make.height.equalTo(150)
        }
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

        container.addSubview(iconImageView)
        container.addSubview(contentBox)

        iconImageView.snp.makeConstraints { make in
            make.leading.equalTo(container).offset(20)
            make.centerY.equalTo(container)
            make.top.greaterThanOrEqualTo(container).offset(20)
        }

        contentBox.snp.makeConstraints { make in
            make.top.equalTo(container).offset(-2)
            make.bottom.equalTo(container).offset(-2)
            make.trailing.equalTo(container).offset(-2)
            make.leading.equalTo(iconImageView.snp.trailing).offset(20)
        }

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