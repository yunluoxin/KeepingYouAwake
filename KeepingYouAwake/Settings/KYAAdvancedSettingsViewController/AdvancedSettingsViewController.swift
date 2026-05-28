//
//  AdvancedSettingsViewController.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 18.12.15.
//  Rewritten in Swift from KYAAdvancedSettingsViewController.m.
//

import AppKit
import KYAApplicationSupport

final class AdvancedSettingsViewController: SettingsContentViewController {
    private var settings: [UserDefaultsSetting] = []
    private var tableView: NSTableView!
    private var processMonitoringCheckbox: NSButton!
    private var processNamesTextField: NSTextField!

    override class var tabViewItemImage: NSImage? {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "gearshape.2", accessibilityDescription: nil)
        } else {
            return NSImage(named: NSImage.advancedName)
        }
    }

    override class var preferredTitle: String? { KYAL10nSettings.advanced }
    override var resizesView: Bool { false }

    override func loadView() {
        view = NSView()

        let scrollView = NSScrollView()
        scrollView.borderType = .lineBorder
        scrollView.hasHorizontalScroller = false
        scrollView.hasVerticalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false

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

        processMonitoringCheckbox = NSButton(checkboxWithTitle: NSLocalizedString("Activate when specified processes are running", tableName: "Localizable", bundle: .main, value: "Activate when specified processes are running", comment: "Activate when specified processes are running"), target: nil, action: nil)
        processMonitoringCheckbox.translatesAutoresizingMaskIntoConstraints = false
        processMonitoringCheckbox.bind(.value, to: UserDefaults.standard, withKeyPath: UserDefaults.processMonitoringEnabledKey, options: [.continuouslyUpdatesValue: true])

        let processNamesLabel = NSTextField(labelWithString: NSLocalizedString("Process Names:", tableName: "Localizable", bundle: .main, value: "Process Names:", comment: "Process Names:"))
        processNamesLabel.translatesAutoresizingMaskIntoConstraints = false

        processNamesTextField = NSTextField()
        processNamesTextField.placeholderString = NSLocalizedString("Comma-separated list of process names", tableName: "Localizable", bundle: .main, value: "Comma-separated list of process names", comment: "Comma-separated list of process names")
        processNamesTextField.translatesAutoresizingMaskIntoConstraints = false
        processNamesTextField.bind(.value, to: UserDefaults.standard, withKeyPath: UserDefaults.processNamesKey, options: [.continuouslyUpdatesValue: true])

        let warningLabel = NSTextField(wrappingLabelWithString: NSLocalizedString("Only change these advanced settings if you know what you are doing. Most of these settings require an app restart.", tableName: "Localizable", bundle: .main, value: "Only change these advanced settings if you know what you are doing. Most of these settings require an app restart.", comment: "Only change these advanced settings if you know what you are doing. Most of these settings require an app restart."))
        warningLabel.font = NSFont.messageFont(ofSize: 11)
        warningLabel.textColor = .secondaryLabelColor
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.preferredMaxLayoutWidth = 272

        let resetButton = NSButton(title: NSLocalizedString("Reset to Default", tableName: "Localizable", bundle: .main, value: "Reset to Default", comment: "Reset to Default"), target: self, action: #selector(resetAdvancedSettings))
        resetButton.bezelStyle = .rounded
        resetButton.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(processMonitoringCheckbox)
        view.addSubview(processNamesLabel)
        view.addSubview(processNamesTextField)
        view.addSubview(warningLabel)
        view.addSubview(resetButton)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor, constant: -1),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -1),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 1),
            scrollView.heightAnchor.constraint(equalToConstant: 160),

            processMonitoringCheckbox.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 12),
            processMonitoringCheckbox.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            processNamesLabel.topAnchor.constraint(equalTo: processMonitoringCheckbox.bottomAnchor, constant: 8),
            processNamesLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),

            processNamesTextField.centerYAnchor.constraint(equalTo: processNamesLabel.centerYAnchor),
            processNamesTextField.leadingAnchor.constraint(equalTo: processNamesLabel.trailingAnchor, constant: 8),
            processNamesTextField.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),

            warningLabel.topAnchor.constraint(equalTo: processNamesLabel.bottomAnchor, constant: 12),
            warningLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            warningLabel.trailingAnchor.constraint(lessThanOrEqualTo: resetButton.leadingAnchor, constant: -16),

            resetButton.lastBaselineAnchor.constraint(equalTo: warningLabel.lastBaselineAnchor),
            resetButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            resetButton.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -20),
        ])
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureAdvancedSettings()
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
        UserDefaults.standard.synchronize()
        tableView.reloadData()
        processMonitoringCheckbox.unbind(.value)
        processNamesTextField.unbind(.value)
        processMonitoringCheckbox.bind(.value, to: UserDefaults.standard, withKeyPath: UserDefaults.processMonitoringEnabledKey, options: [.continuouslyUpdatesValue: true])
        processNamesTextField.bind(.value, to: UserDefaults.standard, withKeyPath: UserDefaults.processNamesKey, options: [.continuouslyUpdatesValue: true])
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
        cellView.checkbox.bind(.value, to: UserDefaults.standard, withKeyPath: setting.key, options: [.continuouslyUpdatesValue: true])

        return cellView
    }
}

private final class SettingCellView: NSTableCellView {
    let checkbox = NSButton(checkboxWithTitle: "", target: nil, action: nil)
    var settingKey: String = ""

    init() {
        super.init(frame: .zero)
        checkbox.translatesAutoresizingMaskIntoConstraints = false
        addSubview(checkbox)

        NSLayoutConstraint.activate([
            checkbox.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            checkbox.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            checkbox.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            checkbox.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -8),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}