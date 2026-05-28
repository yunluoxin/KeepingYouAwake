//
//  AddDurationViewController.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 08.08.19.
//  Rewritten in Swift from KYAAddDurationViewController.m.
//

import AppKit
import KYAActivationDurations
import KYAApplicationSupport

private let maximumHours = 999
private let maximumMinutes = 59
private let maximumSeconds = 59

private enum ValidationReason {
    case success
    case invalid
    case alreadyAdded
}

final class AddDurationViewController: NSViewController, NSTextFieldDelegate {
    let activationDurationsController: ActivationDurationsController

    @objc private var hours: NSNumber? = NSNumber(value: 1)
    @objc private var minutes: NSNumber? = NSNumber(value: 0)
    @objc private var seconds: NSNumber? = NSNumber(value: 0)

    @objc private var errorMessage: String?

    private var hoursTextField: NSTextField!
    private var minutesTextField: NSTextField!
    private var secondsTextField: NSTextField!
    private var warningLabel: NSTextField!
    private var addButton: NSButton!

    init(activationDurationsController: ActivationDurationsController) {
        self.activationDurationsController = activationDurationsController
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func loadView() {
        let mainView = NSView(frame: NSRect(x: 0, y: 0, width: 320, height: 154))
        mainView.translatesAutoresizingMaskIntoConstraints = false

        let hoursGroup = makeInputGroup(label: KYAL10n.hours, maxValue: maximumHours, bindingKey: "hours")
        hoursTextField = hoursGroup.textField
        hoursTextField.delegate = self

        let minutesGroup = makeInputGroup(label: KYAL10n.minutes, maxValue: maximumMinutes, bindingKey: "minutes")
        minutesTextField = minutesGroup.textField
        minutesTextField.delegate = self

        let secondsGroup = makeInputGroup(label: KYAL10n.seconds, maxValue: maximumSeconds, bindingKey: "seconds")
        secondsTextField = secondsGroup.textField
        secondsTextField.delegate = self

        let inputStack = NSStackView(views: [hoursGroup.stackView, minutesGroup.stackView, secondsGroup.stackView])
        inputStack.translatesAutoresizingMaskIntoConstraints = false
        inputStack.orientation = .horizontal
        inputStack.alignment = .top
        inputStack.distribution = .fillEqually
        inputStack.spacing = 8

        warningLabel = NSTextField(labelWithString: "")
        warningLabel.translatesAutoresizingMaskIntoConstraints = false
        warningLabel.alignment = .center
        warningLabel.textColor = .secondaryLabelColor
        warningLabel.preferredMaxLayoutWidth = 280
        warningLabel.lineBreakMode = .byWordWrapping
        bindWarningLabel()

        let warningContainer = NSView()
        warningContainer.translatesAutoresizingMaskIntoConstraints = false
        warningContainer.addSubview(warningLabel)
        NSLayoutConstraint.activate([
            warningLabel.leadingAnchor.constraint(equalTo: warningContainer.leadingAnchor),
            warningLabel.trailingAnchor.constraint(equalTo: warningContainer.trailingAnchor),
            warningLabel.topAnchor.constraint(greaterThanOrEqualTo: warningContainer.topAnchor, constant: 8),
            warningLabel.bottomAnchor.constraint(equalTo: warningContainer.bottomAnchor, constant: -8),
        ])

        let cancelButton = NSButton(title: KYAL10n.cancel, target: self, action: #selector(cancelAction))
        cancelButton.translatesAutoresizingMaskIntoConstraints = false
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}"

        addButton = NSButton(title: KYAL10n.addDuration, target: self, action: #selector(addDuration(_:)))
        addButton.translatesAutoresizingMaskIntoConstraints = false
        addButton.bezelStyle = .rounded
        addButton.keyEquivalent = "\r"

        let buttonStack = NSStackView(views: [cancelButton, addButton])
        buttonStack.translatesAutoresizingMaskIntoConstraints = false
        buttonStack.orientation = .horizontal
        buttonStack.alignment = .top
        buttonStack.distribution = .equalSpacing

        mainView.addSubview(inputStack)
        mainView.addSubview(warningContainer)
        mainView.addSubview(buttonStack)

        NSLayoutConstraint.activate([
            inputStack.topAnchor.constraint(equalTo: mainView.topAnchor, constant: 20),
            inputStack.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 20),
            inputStack.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -20),

            warningContainer.topAnchor.constraint(equalTo: inputStack.bottomAnchor, constant: 8),
            warningContainer.leadingAnchor.constraint(equalTo: mainView.leadingAnchor, constant: 20),
            warningContainer.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -20),

            buttonStack.topAnchor.constraint(equalTo: warningContainer.bottomAnchor, constant: 8),
            buttonStack.trailingAnchor.constraint(equalTo: mainView.trailingAnchor, constant: -20),
            buttonStack.leadingAnchor.constraint(greaterThanOrEqualTo: mainView.leadingAnchor, constant: 20),
            buttonStack.bottomAnchor.constraint(equalTo: mainView.bottomAnchor, constant: -20),
        ])

        bindTextFields()

        view = mainView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        resetValues()
    }

    @objc func cancelAction(_ sender: Any?) {
        dismiss(self)
    }

    @objc func addDuration(_ sender: Any?) {
        setInputsEnabled(false)

        let result = validateInputs()
        switch result {
        case .invalid:
            errorMessage = KYAL10n.durationInvalidInput
            setInputsEnabled(true)
        case .alreadyAdded:
            errorMessage = KYAL10n.durationAlreadyAdded
            setInputsEnabled(true)
        case .success:
            dismiss(sender)
        }
    }

    // MARK: - NSTextFieldDelegate

    func control(_ control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        errorMessage = nil
        return true
    }

    // MARK: - Validation

    private func validateInputs() -> ValidationReason {
        var h = hours?.intValue ?? 0
        var m = minutes?.intValue ?? 0
        var s = seconds?.intValue ?? 0

        if h > maximumHours {
            hours = NSNumber(value: maximumHours)
            return .invalid
        }
        if hours == nil { hours = NSNumber(value: 0) }
        h = hours!.intValue

        if m > maximumMinutes {
            minutes = NSNumber(value: maximumMinutes)
            return .invalid
        }
        if minutes == nil { minutes = NSNumber(value: 0) }
        m = minutes!.intValue

        if s > maximumSeconds {
            seconds = NSNumber(value: maximumSeconds)
            return .invalid
        }
        if seconds == nil { seconds = NSNumber(value: 0) }
        s = seconds!.intValue

        guard let duration = ActivationDuration(hours: h, minutes: m, seconds: s) else {
            return .invalid
        }

        if !activationDurationsController.add(duration) {
            return .alreadyAdded
        }

        return .success
    }

    private func setInputsEnabled(_ enabled: Bool) {
        if !enabled {
            hoursTextField.resignFirstResponder()
            minutesTextField.resignFirstResponder()
            secondsTextField.resignFirstResponder()
        }
        hoursTextField.isEditable = enabled
        minutesTextField.isEditable = enabled
        secondsTextField.isEditable = enabled
    }

    private func resetValues() {
        hours = NSNumber(value: 1)
        minutes = NSNumber(value: 0)
        seconds = NSNumber(value: 0)
    }

    // MARK: - Bindings

    private func bindTextFields() {
        bind(hoursTextField, to: "hours")
        bind(minutesTextField, to: "minutes")
        bind(secondsTextField, to: "seconds")
    }

    private func bindWarningLabel() {
        let options: [NSBindingOption: Any] = [NSBindingOption(rawValue: "NSNullPlaceholder"): ""]
        warningLabel.bind(.value, to: self, withKeyPath: "errorMessage", options: options)
    }

    private func bind(_ textField: NSTextField, to keyPath: String) {
        let options: [NSBindingOption: Any] = [.continuouslyUpdatesValue: true]
        textField.bind(.value, to: self, withKeyPath: keyPath, options: options)
    }

    // MARK: - Input Group Helper

    private struct InputGroup {
        let stackView: NSStackView
        let textField: NSTextField
    }

    private func makeInputGroup(label: String, maxValue: Int, bindingKey: String) -> InputGroup {
        let titleLabel = NSTextField(labelWithString: label)
        titleLabel.font = NSFont.systemFont(ofSize: 11, weight: .regular)
        titleLabel.controlSize = .small

        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimum = NSNumber(value: 0)
        formatter.maximum = NSNumber(value: maxValue)

        let textField = NSTextField()
        textField.formatter = formatter
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.alignment = .right
        textField.bezelStyle = .roundedBezel

        let stackView = NSStackView(views: [titleLabel, textField])
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 4

        return InputGroup(stackView: stackView, textField: textField)
    }
}