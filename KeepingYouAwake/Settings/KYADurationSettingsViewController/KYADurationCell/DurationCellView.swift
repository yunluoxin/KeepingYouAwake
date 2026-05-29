//
//  DurationCellView.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 27.07.19.
//  Rewritten in Swift from KYADurationCell.m.
//

import AppKit
import SnapKit

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

    // Cells are created programmatically in dequeue(); no nib registration needed.
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

        textLabel.lineBreakMode = .byClipping
        textLabel.textColor = .labelColor
        textLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)

        defaultLabel.lineBreakMode = .byClipping
        defaultLabel.textColor = .secondaryLabelColor
        defaultLabel.isHidden = true
        defaultLabel.setContentHuggingPriority(.required, for: .horizontal)

        addSubview(textLabel)
        addSubview(defaultLabel)

        textLabel.snp.makeConstraints { make in
            make.leading.equalTo(self).offset(8)
            make.top.equalTo(self).offset(3)
            make.bottom.equalTo(self.snp.bottom).offset(-4)
        }

        defaultLabel.snp.makeConstraints { make in
            make.leading.equalTo(textLabel.snp.trailing).offset(8)
            make.firstBaseline.equalTo(textLabel)
            make.trailing.equalTo(self).offset(-8)
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }
}