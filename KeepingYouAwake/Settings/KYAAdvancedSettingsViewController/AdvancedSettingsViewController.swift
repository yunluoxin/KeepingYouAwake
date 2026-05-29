//
//  AdvancedSettingsViewController.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 18.12.15.
//  Rewritten in Swift from KYAAdvancedSettingsViewController.m.
//

import AppKit
import KYAApplicationSupport
import SnapKit

final class AdvancedSettingsViewController: SettingsContentViewController {
    private var settings: [UserDefaultsSetting] = []
    private var tableView: NSTableView!
    private var processMonitoringCheckbox: NSButton!
    private var processNamesTextField: NSTextField!
    private var processNamesLabel: NSTextField!
    private var processNamesConfirmButton: NSButton!
    private var processNamesCancelButton: NSButton!

    override class var tabViewItemImage: NSImage? {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: nil)
        } else {
            return NSImage(named: NSImage.advancedName)
        }
    }

    override class var preferredTitle: String? { KYAL10nSettings.advanced }

    override func loadView() {
        view = NSView()

        let scrollView = NSScrollView()
        scrollView.borderType = .lineBorder
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true

        tableView = NSTableView()
        if #available(macOS 11.0, *) {
            tableView.style = .fullWidth
        }
        tableView.selectionHighlightStyle = .none
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.rowHeight = 30
        tableView.dataSource = self
        tableView.delegate = self
        tableView.columnAutoresizingStyle = .lastColumnOnlyAutoresizingStyle
        tableView.headerView = nil

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("SettingColumn"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        scrollView.documentView = tableView
        view.addSubview(scrollView)

        processMonitoringCheckbox = NSButton(checkboxWithTitle: NSLocalizedString("Activate when specified processes are running", tableName: "Localizable", bundle: .main, value: "Activate when specified processes are running", comment: "Activate when specified processes are running"), target: self, action: #selector(processMonitoringCheckboxChanged(_:)))
                processMonitoringCheckbox.bind(.value, to: NSUserDefaultsController.shared, withKeyPath: "values.\(UserDefaults.processMonitoringEnabledKey)", options: [.continuouslyUpdatesValue: true])

        processNamesLabel = NSTextField(labelWithString: NSLocalizedString("Process Names:", tableName: "Localizable", bundle: .main, value: "Process Names:", comment: "Process Names:"))

        processNamesTextField = NSTextField()
        processNamesTextField.placeholderString = NSLocalizedString("Comma-separated list of process names", tableName: "Localizable", bundle: .main, value: "Comma-separated list of process names", comment: "Comma-separated list of process names")
        processNamesTextField.stringValue = UserDefaults.standard.kya_processNames ?? ""

        processNamesConfirmButton = NSButton(title: NSLocalizedString("OK", tableName: "Localizable", bundle: .main, value: "OK", comment: "Confirm process names"), target: self, action: #selector(confirmProcessNames(_:)))
        processNamesConfirmButton.bezelStyle = .rounded

        processNamesCancelButton = NSButton(title: NSLocalizedString("Cancel", tableName: "Localizable", bundle: .main, value: "Cancel", comment: "Cancel editing process names"), target: self, action: #selector(cancelProcessNames(_:)))
        processNamesCancelButton.bezelStyle = .rounded

        let warningLabel = NSTextField(wrappingLabelWithString: NSLocalizedString("Only change these advanced settings if you know what you are doing. Most of these settings require an app restart.", tableName: "Localizable", bundle: .main, value: "Only change these advanced settings if you know what you are doing. Most of these settings require an app restart.", comment: "Only change these advanced settings if you know what you are doing. Most of these settings require an app restart."))
        warningLabel.font = NSFont.messageFont(ofSize: 11)
        warningLabel.textColor = .secondaryLabelColor
                warningLabel.preferredMaxLayoutWidth = 272

        let resetButton = NSButton(title: NSLocalizedString("Reset to Default", tableName: "Localizable", bundle: .main, value: "Reset to Default", comment: "Reset to Default"), target: self, action: #selector(resetAdvancedSettings))
        resetButton.bezelStyle = .rounded

        view.addSubview(processMonitoringCheckbox)
        view.addSubview(processNamesLabel)
        view.addSubview(processNamesTextField)
        view.addSubview(processNamesConfirmButton)
        view.addSubview(processNamesCancelButton)
        view.addSubview(warningLabel)
        view.addSubview(resetButton)

        scrollView.snp.makeConstraints { make in
            make.top.equalTo(view).offset(-1)
            make.leading.equalTo(view).offset(-1)
            make.trailing.equalTo(view).offset(1)
            make.height.equalTo(160)
        }

        processMonitoringCheckbox.snp.makeConstraints { make in
            make.top.equalTo(scrollView.snp.bottom).offset(12)
            make.leading.equalTo(view).offset(20)
        }

        processNamesLabel.snp.makeConstraints { make in
            make.top.equalTo(processMonitoringCheckbox.snp.bottom).offset(8)
            make.leading.equalTo(view).offset(20)
        }

        processNamesTextField.snp.makeConstraints { make in
            make.centerY.equalTo(processNamesLabel)
            make.leading.equalTo(processNamesLabel.snp.trailing).offset(8)
        }

        processNamesConfirmButton.snp.makeConstraints { make in
            make.centerY.equalTo(processNamesLabel)
            make.leading.equalTo(processNamesTextField.snp.trailing).offset(8)
        }

        processNamesCancelButton.snp.makeConstraints { make in
            make.centerY.equalTo(processNamesLabel)
            make.leading.equalTo(processNamesConfirmButton.snp.trailing).offset(4)
            make.trailing.equalTo(view).offset(-20)
        }

        warningLabel.snp.makeConstraints { make in
            make.top.equalTo(processNamesLabel.snp.bottom).offset(12)
            make.leading.equalTo(view).offset(20)
            make.trailing.lessThanOrEqualTo(resetButton.snp.leading).offset(-16)
        }

        resetButton.snp.makeConstraints { make in
            make.lastBaseline.equalTo(warningLabel)
            make.trailing.equalTo(view).offset(-20)
            make.bottom.equalTo(view).offset(-20)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAdvancedSettings()
        updateProcessNamesRowVisibility()
    }

    private func configureAdvancedSettings() {
        settings = [
            UserDefaultsSetting(title: KYAL10n.quitOnTimerExpiration, key: UserDefaults.quitOnTimerExpirationEnabledKey),
            UserDefaultsSetting(title: KYAL10n.allowDisplaySleep, key: UserDefaults.allowDisplaySleepKey),
            UserDefaultsSetting(title: KYAL10n.activateOnExternalDisplay, key: UserDefaults.activateOnExternalDisplayConnectedEnabledKey),
            UserDefaultsSetting(title: KYAL10n.deactivateOnUserSwitch, key: UserDefaults.deactivateOnUserSwitchEnabledKey),
        ]
        tableView.reloadData()
    }

    @objc private func resetAdvancedSettings() {
        for setting in settings { setting.reset() }
        UserDefaults.standard.removeObject(forKey: UserDefaults.processMonitoringEnabledKey)
        UserDefaults.standard.removeObject(forKey: UserDefaults.processNamesKey)
        NSUserDefaultsController.shared.revertToInitialValues(self)
        tableView.reloadData()
        processNamesTextField.stringValue = ""
        updateProcessNamesRowVisibility()
    }

    @objc private func processMonitoringCheckboxChanged(_ sender: NSButton) {
        updateProcessNamesRowVisibility()
    }

    private func updateProcessNamesRowVisibility() {
        let isEnabled = UserDefaults.standard.kya_processMonitoringEnabled
        if isEnabled {
            processNamesTextField.stringValue = UserDefaults.standard.kya_processNames ?? ""
        }
        processNamesLabel.isHidden = !isEnabled
        processNamesTextField.isHidden = !isEnabled
        processNamesConfirmButton.isHidden = !isEnabled
        processNamesCancelButton.isHidden = !isEnabled
    }

    @objc private func confirmProcessNames(_ sender: NSButton) {
        UserDefaults.standard.kya_processNames = processNamesTextField.stringValue
        processNamesTextField.window?.makeFirstResponder(nil)
    }

    @objc private func cancelProcessNames(_ sender: NSButton) {
        processNamesTextField.stringValue = UserDefaults.standard.kya_processNames ?? ""
        processNamesTextField.window?.makeFirstResponder(nil)
    }
}

extension AdvancedSettingsViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        settings.count
    }
}

extension AdvancedSettingsViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard row < settings.count else { return nil }
        let setting = settings[row]

        let cellIdentifier = NSUserInterfaceItemIdentifier("SettingCell")
        let cellView: SettingCellView

        if let reused = tableView.makeView(withIdentifier: cellIdentifier, owner: self) as? SettingCellView {
            cellView = reused
            cellView.checkbox.unbind(.value)
        } else {
            cellView = SettingCellView()
            cellView.identifier = cellIdentifier
        }

        cellView.checkbox.title = setting.title
        cellView.settingKey = setting.key
        cellView.checkbox.bind(.value, to: NSUserDefaultsController.shared, withKeyPath: "values.\(setting.key)", options: [.continuouslyUpdatesValue: true])

        return cellView
    }
}

private final class SettingCellView: NSTableCellView {
    let checkbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    var settingKey: String = ""

    init() {
        super.init(frame: .zero)
        addSubview(checkbox)

        checkbox.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(8)
            make.top.equalTo(self).offset(8)
            make.bottom.equalTo(self).offset(-8)
            make.trailing.lessThanOrEqualTo(self).offset(-8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}