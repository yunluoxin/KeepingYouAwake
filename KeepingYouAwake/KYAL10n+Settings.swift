//
//  KYAL10n+Settings.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 20.09.21.
//  Rewritten in Swift from KYASettingsLocalizedStrings.m.
//

import Foundation

/// Settings-specific localization using the "KYASettings" table.
enum KYAL10nSettings {
    private static func localized(_ key: String, comment: String) -> String {
        NSLocalizedString(key, tableName: "KYASettings", bundle: .main, value: key, comment: comment)
    }

    static let title = localized("KeepingYouAwake – Settings", comment: "KeepingYouAwake – Settings")
    static let general = localized("General", comment: "General")
    static let activationDuration = localized("Activation Duration", comment: "Activation Duration")
    static let battery = localized("Battery", comment: "Battery")
    static let advanced = localized("Advanced", comment: "Advanced")
    static let updates = localized("Updates", comment: "Updates")
    static let about = localized("About", comment: "About")
}