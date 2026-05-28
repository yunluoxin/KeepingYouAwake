//
//  SettingsContentViewController.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 20.09.21.
//  Rewritten in Swift from KYASettingsContentViewController.m.
//

import AppKit

/// Base class for settings tab VCs. Creates tab view item and
/// provides common view lifecycle behavior.
class SettingsContentViewController: NSViewController {
    /// Creates a tab view item with this controller as its VC.
    class var preferredTabViewItem: NSTabViewItem {
        let controller = self.init()
        let item = NSTabViewItem(viewController: controller)
        item.image = tabViewItemImage
        return item
    }

    /// Tab bar icon image. Override in subclass.
    class var tabViewItemImage: NSImage? { nil }

    /// Tab bar title. Override in subclass.
    class var preferredTitle: String? { nil }

    /// Whether the view should resize to fit its content.
    var resizesView: Bool { true }

    required convenience init() {
        self.init(nibName: nil, bundle: nil)
        title = type(of: self).preferredTitle
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        if resizesView {
            preferredContentSize = view.fittingSize
        }
    }
}