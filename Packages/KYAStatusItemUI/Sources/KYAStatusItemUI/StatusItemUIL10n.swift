//
//  StatusItemUIL10n.swift
//  KYAStatusItemUI
//
//  Created by Marcel Dierkes on 30.04.22.
//

import Foundation

/// Namespace wrapping localized strings for the status item UI.
///
/// Keys are preserved for .xcstrings compatibility.
/// Note: These strings are provided by the main app bundle at runtime,
/// matching the original Obj-C behavior.
enum StatusItemUIL10n {
    /// Tooltip shown when sleep prevention is active.
    static let clickToAllowSleep = NSLocalizedString(
        "Click to allow sleep\nRight click to show menu",
        bundle: .main,
        comment: "Click to allow sleep\nRight click to show menu"
    )

    /// Tooltip shown when sleep prevention is inactive.
    static let clickToPreventSleep = NSLocalizedString(
        "Click to prevent sleep\nRight click to show menu",
        bundle: .main,
        comment: "Click to prevent sleep\nRight click to show menu"
    )

    /// Tooltip shown when the master switch is off (app disabled).
    static let clickToEnable = NSLocalizedString(
        "Click to enable\nRight click to show menu",
        bundle: .main,
        comment: "Click to enable\nRight click to show menu"
    )
}