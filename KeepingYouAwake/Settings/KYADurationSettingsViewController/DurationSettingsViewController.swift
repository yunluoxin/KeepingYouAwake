//
//  DurationSettingsViewController.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 27.07.19.
//  Rewritten in Swift from KYADurationSettingsViewController.m.
//

import AppKit
import KYAActivationDurations

private let activationDurationLimit = 42

final class DurationSettingsViewController: SettingsContentViewController, NSTableViewDataSource, NSTableViewDelegate {
    override class var preferredTitle: String? { KYAL10nSettings.activationDuration }

    override class var tabViewItemImage: NSImage? {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "timer", accessibilityDescription: nil)
        }
        return NSImage(named: "ToolbarDurations")
    }

    private let durationsController = ActivationDurationsController.shared

    private var tableView: NSTableView!
    private var segmentedControl: NSSegmentedControl!
    private var setDefaultButton: NSButton!
    private var resetButton: NSButton!

    required init() {
        super.init()
    }

    override func loadView() {
        let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 450, height: 325))
        mainView.translatesAutoresizingMaskIntoConstraints = false

        tableView = NSTableView()
        if #available(macOS 11.0, *) {
            tableView.style = .inset
        }
        tableView.rowHeight = 24
        tableView.rowSizeStyle = .medium
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsMultipleSelection = false
        tableView.allowsColumnReordering = false
        tableView.allowsColumnResizing = false
        tableView.headerView = nil
        tableView.dataSource = self
        tableView.delegate = self
        tableView.doubleAction = #selector(setDefaultDuration(_:))
        tableView.target = self

        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("DurationColumn"))
        column.resizingMask = .autoresizingMask
        tableView.addTableColumn(column)

        let scrollView = NSScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.documentView = tableView

        DurationCellView.register(in: tableView)

        let contextMenu = NSMenu()
        let setDefaultItem = NSMenuItem(title: KYAL10n.setDefault, action: #selector(setDefaultDuration(_:)), keyEquivalent: "d")
        setDefaultItem.target = self
        contextMenu.addItem(setDefaultItem)

        let removeItem = NSMenuItem(title: "Remove", action: #selector(removeDuration(_:)), keyEquivalent: "")
        removeItem.target = self
        contextMenu.addItem(removeItem)
        tableView.menu = contextMenu

        let infoLabel = NSTextField(labelWithString: KYAL10n.defaultDurationInfo)
        infoLabel.translatesAutoresizingMaskIntoConstraints = false
        infoLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        infoLabel.textColor = .secondaryLabelColor
        infoLabel.lineBreakMode = .byWordWrapping
        infoLabel.preferredMaxLayoutWidth = 414

        resetButton = NSButton(title: KYAL10n.resetEllipsis, target: self, action: #selector(resetToDefaults(_:)))
        resetButton.translatesAutoresizingMaskIntoConstraints = false
        resetButton.bezelStyle = .rounded

        setDefaultButton = NSButton(title: KYAL10n.setDefault, target: self, action: #selector(setDefaultDuration(_:)))
        setDefaultButton.translatesAutoresizingMaskIntoConstraints = false
        setDefaultButton.bezelStyle = .rounded
        setDefaultButton.keyEquivalent = "d"
        setDefaultButton.keyEquivalentModifierMask = .command

        segmentedControl = NSSegmentedControl(images: [
            NSImage(named: NSImage.removeTemplateName)!,
            NSImage(named: NSImage.addTemplateName)!
        ], trackingMode: .momentary, target: self, action: #selector(toggleSegmentedControl(_:)))
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.segmentStyle = .separated

        let bottomStack = NSStackView(views: [resetButton, setDefaultButton, segmentedControl])
        bottomStack.translatesAutoresizingMaskIntoConstraints = false
        bottomStack.orientation = .horizontal
        bottomStack.alignment = .top
        bottomStack.distribution = .gravityAreas

        mainView.addSubview(scrollView)
        mainView.addSubview(infoLabel)
        mainView.addSubview(bottomStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: mainView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: mainView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: mainView.trailingAnchor),
            scrollView.heightAnchor.constraint(equalToConstant: 240),

            infoLabel.topAnchor.constraint(equalTo: scrollView.bottomAnchor, constant: 16),
            infoLabel.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 20),
            infoLabel.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -20),

            bottomStack.topAnchor.constraint(equalTo: infoLabel.bottomAnchor, constant: 16),
            bottomStack.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 20),
            bottomStack.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -20),
            bottomStack.bottomAnchor.constraint(equalTo: mainView.bottomAnchor, constant: -20),
        ])

        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.reloadData()

        durationsController.onChangeDurations = { [weak self] in
            self?.tableView.reloadData()
            self?.updateViewForSelectedRow()
        }

        updateViewForSelectedRow()
    }

    // MARK: - Actions

    @objc func toggleSegmentedControl(_ sender: NSSegmentedControl) {
        let index = sender.selectedSegment
        if index == 0 {
            removeDuration(sender)
        } else if index == 1 {
            addDuration(sender)
        }
    }

    @objc func addDuration(_ sender: Any?) {
        let controller = AddDurationViewController(activationDurationsController: durationsController)
        presentAsSheet(controller)
    }

    @objc func removeDuration(_ sender: Any?) {
        var row = tableView.clickedRow
        if sender is NSControl {
            row = tableView.selectedRow
        }
        if row < 0 { return }
        durationsController.removeActivationDuration(at: row)
    }

    @objc func setDefaultDuration(_ sender: Any?) {
        var row = tableView.clickedRow
        if sender is NSButton {
            row = tableView.selectedRow
        }
        if row < 0 { return }
        durationsController.setActivationDurationAsDefault(at: row)
    }

    @objc func resetToDefaults(_ sender: Any?) {
        let alert = NSAlert()
        alert.alertStyle = .warning
        alert.icon = NSImage(named: NSImage.cautionName)

        alert.messageText = KYAL10n.durationsAlertReallyResetTitle
        alert.informativeText = KYAL10n.durationsAlertReallyResetMessage

        let okButton = alert.addButton(withTitle: KYAL10n.durationsAlertReallyResetTitle)
        okButton.tag = NSApplication.ModalResponse.OK.rawValue
        alert.addButton(withTitle: KYAL10n.cancel)

        guard let window = view.window else { return }
        alert.beginSheetModal(for: window) { [weak self] response in
            if response == .OK {
                self?.durationsController.resetActivationDurations()
            }
        }
    }

    // MARK: - NSTableViewDataSource

    func numberOfRows(in tableView: NSTableView) -> Int {
        durationsController.activationDurations.count
    }

    // MARK: - NSTableViewDelegate

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cell = DurationCellView.dequeue(from: tableView, owner: self)
        let durations = durationsController.activationDurations
        guard row < durations.count else { return cell }
        let duration = durations[row]
        cell.textLabel.stringValue = duration.localizedTitle

        let isDefault = durationsController.defaultActivationDuration == duration
        cell.isDefaultDuration = isDefault

        return cell
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        updateViewForSelectedRow()
    }

    private func updateViewForSelectedRow() {
        let row = tableView.selectedRow
        let canRemove = durationsController.canRemoveActivationDuration(at: row)
        setDefaultButton.isEnabled = row >= 0
        segmentedControl.setEnabled(canRemove, forSegment: 0)

        let isLimited = durationsController.activationDurations.count >= activationDurationLimit
        segmentedControl.setEnabled(!isLimited, forSegment: 1)
    }
}