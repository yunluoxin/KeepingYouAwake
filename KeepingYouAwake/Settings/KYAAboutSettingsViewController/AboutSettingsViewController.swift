//
//  AboutSettingsViewController.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 18.12.15.
//  Copyright © 2015 Marcel Dierkes. All rights reserved.
//
//  Rewritten in Swift from KYAAboutSettingsViewController.m.
//

import AppKit
import KYAApplicationSupport
import SnapKit

/// About settings tab — shows version, copyright, and Credits.rtf.
final class AboutSettingsViewController: SettingsContentViewController {

    // MARK: - Tab Item

    override class var tabViewItemImage: NSImage? {
        if #available(macOS 11.0, *) {
            return NSImage(systemSymbolName: "info.circle", accessibilityDescription: nil)
        } else {
            return NSImage(named: NSImage.infoName)
        }
    }

    override class var preferredTitle: String? {
        KYAL10nSettings.about
    }

    // MARK: - Lifecycle

    override func loadView() {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 8
        stackView.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        // Version label
        let versionLabel = NSTextField(labelWithString: versionText)
        versionLabel.font = .systemFont(ofSize: 13, weight: .semibold)

        // Copyright label
        let copyrightLabel = NSTextField(labelWithString: copyrightText)
        copyrightLabel.font = .systemFont(ofSize: 11)

        // Credits text view (non-editable, reads Credits.rtf)
        let creditsTextView = NSTextView()
        creditsTextView.isEditable = false
        creditsTextView.isSelectable = true
        creditsTextView.drawsBackground = false
        creditsTextView.backgroundColor = .clear
        creditsTextView.textContainerInset = NSSize(width: 0, height: 4)
        loadCredits(into: creditsTextView)

        let creditsScrollView = NSScrollView()
        creditsScrollView.documentView = creditsTextView

        creditsScrollView.hasVerticalScroller = true
        creditsScrollView.hasHorizontalScroller = false
        creditsScrollView.autohidesScrollers = true
        creditsScrollView.borderType = .noBorder
        creditsScrollView.drawsBackground = false

        stackView.addArrangedSubview(versionLabel)
        stackView.addArrangedSubview(copyrightLabel)
        stackView.addArrangedSubview(creditsScrollView)

        // Let credits stretch vertically; labels stay at natural height
        creditsScrollView.snp.makeConstraints { make in
            make.height.greaterThanOrEqualTo(100)
        }

        view = stackView
    }

    // MARK: - Text Properties

    private var versionText: String {
        guard let fullVersion = Bundle.main.kya_fullVersionString else {
            return KYAL10n.version
        }
        return "\(KYAL10n.version) \(fullVersion)"
    }

    private var copyrightText: String {
        Bundle.main.kya_localizedCopyrightString ?? ""
    }

    // MARK: - Credits Loading

    private func loadCredits(into textView: NSTextView) {
        guard let url = Bundle.main.url(forResource: "Credits", withExtension: "rtf") else {
            return
        }
        try? textView.readRTFD(fromFile: url.path)
    }
}