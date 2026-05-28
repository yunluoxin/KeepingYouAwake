//
//  BatterySettingsViewController.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 23.09.21.
//  Rewritten in Swift from KYABatterySettingsViewController.m.
//

import AppKit
import KYADeviceInfo
import KYAApplicationSupport

class BatterySettingsViewController: SettingsContentViewController {

    private var batteryThresholdEnabledCheckbox: NSButton!
    private var batteryThresholdSlider: NSSlider!
    private var batteryThresholdValueField: NSTextField!
    private var lowPowerModeCheckbox: NSButton!

    override class var tabViewItemImage: NSImage? {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "battery.100", accessibilityDescription: nil)
        }
        return NSImage(named: .computer)
    }

    override class var preferredTitle: String? {
        KYAL10nSettings.battery
    }

    override var resizesView: Bool { true }

    var device: Device { Device.current }

    override func loadView() {
        let mainStack = NSStackView()
        mainStack.orientation = .vertical
        mainStack.alignment = .fill
        mainStack.spacing = 8
        mainStack.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        mainStack.setHuggingPriority(.defaultHigh, for: .vertical)
        mainStack.setHuggingPriority(.defaultLow, for: .horizontal)

        let batteryHeading = NSTextField(labelWithString:
            NSLocalizedString("Battery Level", comment: "Battery Level"))
        batteryHeading.font = NSFont.headline
        mainStack.addArrangedSubview(batteryHeading)

        let thresholdRow = NSStackView()
        thresholdRow.orientation = .horizontal
        thresholdRow.alignment = .firstBaseline
        thresholdRow.spacing = 4

        batteryThresholdEnabledCheckbox = NSButton(
            checkboxWithTitle: NSLocalizedString(
                "Deactivate when battery capacity is below",
                comment: "Deactivate when battery capacity is below"),
            target: self,
            action: #selector(batterySettingsDidChange))
        batteryThresholdEnabledCheckbox.setContentHuggingPriority(
            .defaultLow, for: .horizontal)

        batteryThresholdValueField = NSTextField(labelWithString: "50 %")
        batteryThresholdValueField.font = .systemFont(ofSize: NSFont.systemFontSize)
        batteryThresholdValueField.setContentHuggingPriority(
            .required, for: .horizontal)

        thresholdRow.addArrangedSubview(batteryThresholdEnabledCheckbox)
        thresholdRow.addArrangedSubview(batteryThresholdValueField)
        mainStack.addArrangedSubview(thresholdRow)

        let thresholdIndented = NSStackView()
        thresholdIndented.orientation = .vertical
        thresholdIndented.alignment = .fill
        thresholdIndented.spacing = 8
        thresholdIndented.edgeInsets = NSEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)

        let sliderContainer = makeSliderContainer()
        thresholdIndented.addArrangedSubview(sliderContainer)

        let thresholdDesc = makeWrappingSecondaryLabel(
            NSLocalizedString(
                "This value will be ignored when you manually start the app below this battery capacity.",
                comment: "This value will be ignored when you manually start the app below this battery capacity."))
        thresholdDesc.preferredMaxLayoutWidth = 390
        thresholdIndented.addArrangedSubview(thresholdDesc)

        mainStack.addArrangedSubview(thresholdIndented)

        let separator = NSBox()
        separator.boxType = .separator
        mainStack.addArrangedSubview(separator)
        mainStack.setCustomSpacing(16, after: thresholdIndented)
        mainStack.setCustomSpacing(16, after: separator)

        let lpmHeading = NSTextField(labelWithString:
            NSLocalizedString("Low Power Mode", comment: "Low Power Mode"))
        lpmHeading.font = NSFont.headline
        mainStack.addArrangedSubview(lpmHeading)

        lowPowerModeCheckbox = NSButton(
            checkboxWithTitle: NSLocalizedString(
                "Deactivate when Low Power Mode is enabled",
                comment: "Deactivate when Low Power Mode is enabled"),
            target: self,
            action: #selector(batterySettingsDidChange))
        mainStack.addArrangedSubview(lowPowerModeCheckbox)

        let lpmIndented = NSStackView()
        lpmIndented.orientation = .vertical
        lpmIndented.alignment = .fill
        lpmIndented.spacing = 8
        lpmIndented.edgeInsets = NSEdgeInsets(top: 0, left: 20, bottom: 0, right: 0)

        let lpmDesc = makeWrappingSecondaryLabel(
            NSLocalizedString(
                "Low Power Mode can be enabled on supported Macs in System Settings \u{203A} Battery.",
                comment: "Low Power Mode can be enabled on supported Macs in System Settings \u{203A} Battery."))
        lpmDesc.preferredMaxLayoutWidth = 390
        lpmIndented.addArrangedSubview(lpmDesc)

        mainStack.addArrangedSubview(lpmIndented)

        view = mainStack

        setupBindings()
        updateEnabledStates()
    }

    @objc func batterySettingsDidChange(_ sender: Any?) {
        NotificationCenter.default.post(
            name: BatteryCapacityThreshold.didChangeNotification,
            object: nil)
        updateSliderEnabledState()
    }

    private func makeSliderContainer() -> NSView {
        let container = NSView()
        container.translatesAutoresizingMaskIntoConstraints = false

        batteryThresholdSlider = NSSlider()
        batteryThresholdSlider.translatesAutoresizingMaskIntoConstraints = false
        batteryThresholdSlider.minValue = 10
        batteryThresholdSlider.maxValue = 90
        batteryThresholdSlider.intValue = 50
        batteryThresholdSlider.numberOfTickMarks = 9
        batteryThresholdSlider.tickMarkPosition = .below
        batteryThresholdSlider.allowsTickMarkValuesOnly = true
        batteryThresholdSlider.target = self
        batteryThresholdSlider.action = #selector(batterySettingsDidChange)

        container.addSubview(batteryThresholdSlider)

        let tickContainer = NSView()
        tickContainer.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(tickContainer)

        let label10 = makeMiniLabel(NSLocalizedString("10 %", comment: "10 %"))
        let label50 = makeMiniLabel(NSLocalizedString("50 %", comment: "50 %"))
        let label90 = makeMiniLabel(NSLocalizedString("90 %", comment: "90 %"))

        label10.translatesAutoresizingMaskIntoConstraints = false
        label50.translatesAutoresizingMaskIntoConstraints = false
        label90.translatesAutoresizingMaskIntoConstraints = false

        tickContainer.addSubview(label10)
        tickContainer.addSubview(label50)
        tickContainer.addSubview(label90)

        NSLayoutConstraint.activate([
            batteryThresholdSlider.topAnchor.constraint(equalTo: container.topAnchor),
            batteryThresholdSlider.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            batteryThresholdSlider.trailingAnchor.constraint(equalTo: container.trailingAnchor),

            tickContainer.topAnchor.constraint(equalTo: batteryThresholdSlider.bottomAnchor, constant: 4),
            tickContainer.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            tickContainer.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            tickContainer.bottomAnchor.constraint(equalTo: container.bottomAnchor),

            label10.leadingAnchor.constraint(equalTo: tickContainer.leadingAnchor),
            label10.centerYAnchor.constraint(equalTo: tickContainer.centerYAnchor),
            label50.centerXAnchor.constraint(equalTo: tickContainer.centerXAnchor),
            label50.centerYAnchor.constraint(equalTo: tickContainer.centerYAnchor),
            label90.trailingAnchor.constraint(equalTo: tickContainer.trailingAnchor),
            label90.centerYAnchor.constraint(equalTo: tickContainer.centerYAnchor),
        ])

        return container
    }

    private func setupBindings() {
        let defaultsController = NSUserDefaultsController.shared

        batteryThresholdEnabledCheckbox.bind(
            .value,
            to: defaultsController,
            withKeyPath: "values.\(UserDefaults.batteryCapacityThresholdEnabledKey)",
            options: [.continuouslyUpdatesValue: true])

        batteryThresholdSlider.bind(
            .value,
            to: defaultsController,
            withKeyPath: "values.\(UserDefaults.batteryCapacityThresholdKey)",
            options: [.continuouslyUpdatesValue: true])

        let thresholdFormatter = NumberFormatter()
        thresholdFormatter.numberStyle = .decimal
        thresholdFormatter.maximumFractionDigits = 0
        batteryThresholdValueField.formatter = thresholdFormatter

        batteryThresholdValueField.bind(
            .value,
            to: defaultsController,
            withKeyPath: "values.\(UserDefaults.batteryCapacityThresholdKey)",
            options: [.displayPattern: "%{value1}@ %", .continuouslyUpdatesValue: true])

        lowPowerModeCheckbox.bind(
            .value,
            to: defaultsController,
            withKeyPath: "values.\(UserDefaults.lowPowerModeMonitoringEnabledKey)",
            options: [.continuouslyUpdatesValue: true])
    }

    private func updateEnabledStates() {
        let hasBattery = device.batteryMonitor.hasBattery
        let supportsLPM = device.lowPowerModeMonitor.supportsLowPowerMode

        batteryThresholdEnabledCheckbox.isEnabled = hasBattery
        lowPowerModeCheckbox.isEnabled = supportsLPM

        updateSliderEnabledState()
    }

    private func updateSliderEnabledState() {
        let shouldEnable = device.batteryMonitor.hasBattery
            && batteryThresholdEnabledCheckbox.state == .on
        batteryThresholdSlider.isEnabled = shouldEnable
        batteryThresholdValueField.isEnabled = shouldEnable
    }

    private func makeHeadlineLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.headline
        return label
    }

    private func makeWrappingSecondaryLabel(_ text: String) -> NSTextField {
        let label = NSTextField(wrappingLabelWithString: text)
        label.font = .systemFont(ofSize: 11)
        if #available(macOS 10.14, *) {
            label.textColor = .secondaryLabelColor
        } else {
            label.textColor = .disabledControlTextColor
        }
        return label
    }

    private func makeMiniLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = .systemFont(ofSize: NSFont.miniSystemFontSize)
        label.controlSize = .mini
        return label
    }
}