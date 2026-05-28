//
//  DurationCellView.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 27.07.19.
//  Rewritten in Swift from KYADurationCell.m.
//

import AppKit

final class DurationCellView: NSTableCellView {
    let textLabel: NSTextField
    let defaultLabel: NSTextField

    var isDefaultDuration: Bool = false {
        didSet {
            defaultLabel.isHidden = !isDefaultDuration
            let size = textLabel.font?.pointSize ?? NSFont.systemFontSize
            let weight: NSFont.Weight = isDefaultDuration ? .semibold : .regular
            textLabel.font = NSFont.monospacedDigitSystemFont(ofSize: size, weight: weight)
        }
    }

    static let identifier = NSUserInterfaceItemIdentifier("DurationCellView")

    static func register(in tableView: NSTableView) { }

    static func dequeue(from tableView: NSTableView, owner: Any?) -> DurationCellView {
        let view = tableView.makeView(withIdentifier: identifier, owner: owner)
        if let cell = view as? DurationCellView {
            return cell
        }
        let cell = DurationCellView()
        cell.identifier = identifier
        return cell
    }

    override init(frame frameRect: NSRect) {
        textLabel = NSTextField(labelWithString: "")
        defaultLabel = NSTextField(labelWithString: KYAL10n.defaultSuffix)

        super.init(frame: frameRect)

        textLabel.translatesAutoresizingMaskIntoConstraints = false
        textLabel.lineBreakMode = .byClipping
        textLabel.textColor = .labelColor
        textLabel.setContentHuggingPriority(NSLayoutConstraint.Priority(300), for: .horizontal)

        defaultLabel.translatesAutoresizingMaskIntoConstraints = false
        defaultLabel.lineBreakMode = .byClipping
        defaultLabel.textColor = .secondaryLabelColor
        defaultLabel.isHidden = true
        defaultLabel.setContentHuggingPriority(NSLayoutConstraint.Priority(800), for: .horizontal)

        addSubview(textLabel)
        addSubview(defaultLabel)

        NSLayoutConstraint.activate([
            textLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            textLabel.topAnchor.constraint(equalTo: topAnchor, constant: 3),
            bottomAnchor.constraint(equalTo: textLabel.bottomAnchor, constant: 4),

            defaultLabel.leadingAnchor.constraint(equalTo: textLabel.trailingAnchor, constant: 8),
            defaultLabel.firstBaselineAnchor.constraint(equalTo: textLabel.firstBaselineAnchor),
            trailingAnchor.constraint(equalTo: defaultLabel.trailingAnchor, constant: 8),
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}