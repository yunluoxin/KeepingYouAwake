//
//  KYAL10n.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 03.05.19.
//  Rewritten in Swift from KYALocalizedStrings.m.
//

import Foundation

/// Localization namespace wrapping NSLocalizedString for the main app.
/// Keys match the existing .xcstrings file entries to preserve all 21 languages.
enum KYAL10n {
    // MARK: - Generic

    static let ok = NSLocalizedString("OK", tableName: "Localizable", bundle: .main, value: "OK", comment: "OK")
    static let cancel = NSLocalizedString("Cancel", tableName: "Localizable", bundle: .main, value: "Cancel", comment: "Cancel")
    static let defaultSuffix = NSLocalizedString("Default", tableName: "Localizable", bundle: .main, value: "Default", comment: "Default")

    // MARK: - Main Menu

    static let activateForDuration = NSLocalizedString("Activate for Duration", tableName: "Localizable", bundle: .main, value: "Activate for Duration", comment: "Activate for Duration")
    static let settingsEllipsis = NSLocalizedString("Settings…", tableName: "Localizable", bundle: .main, value: "Settings…", comment: "Settings…")
    static let quit = NSLocalizedString("Quit", tableName: "Localizable", bundle: .main, value: "Quit", comment: "Quit")

    // MARK: - Master Switch & Status

    static let disable = NSLocalizedString("Disable", tableName: "Localizable", bundle: .main, value: "Disable", comment: "Disable")
    static let enable = NSLocalizedString("Enable", tableName: "Localizable", bundle: .main, value: "Enable", comment: "Enable")
    static let statusDisabled = NSLocalizedString("Status: Disabled", tableName: "Localizable", bundle: .main, value: "Status: Disabled", comment: "Status: Disabled")
    static let statusIdle = NSLocalizedString("Status: Allowing Sleep", tableName: "Localizable", bundle: .main, value: "Status: Allowing Sleep", comment: "Status: Allowing Sleep")
    static let statusActive = NSLocalizedString("Status: Preventing Sleep", tableName: "Localizable", bundle: .main, value: "Status: Preventing Sleep", comment: "Status: Preventing Sleep")

    static func statusActiveReason(_ reason: String) -> String {
        String(format: NSLocalizedString("Status: Preventing Sleep (%@)", tableName: "Localizable", bundle: .main, value: "Status: Preventing Sleep (%@)", comment: "Status: Preventing Sleep (%@)"), reason)
    }

    // MARK: - Duration Display

    static let isDefaultSuffix = NSLocalizedString("(Default)", tableName: "Localizable", bundle: .main, value: "(Default)", comment: "(Default)")
    static let durationAlreadyAdded = NSLocalizedString("This duration has already been added.", tableName: "Localizable", bundle: .main, value: "This duration has already been added.", comment: "This duration has already been added.")
    static let durationInvalidInput = NSLocalizedString("The entered duration is invalid. Please try again.", tableName: "Localizable", bundle: .main, value: "The entered duration is invalid. Please try again.", comment: "The entered duration is invalid. Please try again.")
    static let indefinitely = NSLocalizedString("Indefinitely", tableName: "Localizable", bundle: .main, value: "Indefinitely", comment: "Indefinitely")
    static let version = NSLocalizedString("Version", tableName: "Localizable", bundle: .main, value: "Version", comment: "Version")

    // MARK: - Notifications

    static let preventingSleepIndefinitelyTitle = NSLocalizedString("Preventing Sleep", tableName: "Localizable", bundle: .main, value: "Preventing Sleep", comment: "Preventing Sleep")
    static let preventingSleepIndefinitelyBody = NSLocalizedString("You can still manually enable sleep mode for your Mac.", tableName: "Localizable", bundle: .main, value: "You can still manually enable sleep mode for your Mac.", comment: "You can still manually enable sleep mode for your Mac.")
    static let preventingSleepForTimeBody = NSLocalizedString("Afterwards your Mac will automatically go to sleep again when unused.", tableName: "Localizable", bundle: .main, value: "Afterwards your Mac will automatically go to sleep again when unused.", comment: "Afterwards your Mac will automatically go to sleep again when unused.")
    static let allowingSleepTitle = NSLocalizedString("Allowing Sleep", tableName: "Localizable", bundle: .main, value: "Allowing Sleep", comment: "Allowing Sleep")
    static let allowingSleepBody = NSLocalizedString("Your Mac will automatically go to sleep when unused.", tableName: "Localizable", bundle: .main, value: "Your Mac will automatically go to sleep when unused.", comment: "Your Mac will automatically go to sleep when unused.")

    static func preventingSleepForTimeTitle(_ remainingTime: String) -> String {
        String(format: NSLocalizedString("Preventing Sleep for %@", tableName: "Localizable", bundle: .main, value: "Preventing Sleep for %@", comment: "Preventing Sleep for %@"), remainingTime)
    }

    static func setDefaultActivationDuration(_ title: String) -> String {
        String(format: NSLocalizedString("Set Default: %@", tableName: "Localizable", bundle: .main, value: "Set Default: %@", comment: "Set Default: %@"), title)
    }

    // MARK: - Settings

    static let quitOnTimerExpiration = NSLocalizedString("Quit when activation duration is over", tableName: "Localizable", bundle: .main, value: "Quit when activation duration is over", comment: "Quit when activation duration is over")
    static let allowDisplaySleep = NSLocalizedString("Allow the display to sleep", tableName: "Localizable", bundle: .main, value: "Allow the display to sleep", comment: "Allow the display to sleep")
    static let activateOnExternalDisplay = NSLocalizedString("Activate when an external display is connected", tableName: "Localizable", bundle: .main, value: "Activate when an external display is connected", comment: "Activate when an external display is connected")
    static let deactivateOnUserSwitch = NSLocalizedString("Deactivate when switched to another user account", tableName: "Localizable", bundle: .main, value: "Deactivate when switched to another user account", comment: "Deactivate when switched to another user account")
    static let durationsAlertReallyResetTitle = NSLocalizedString("Reset Activation Durations", tableName: "Localizable", bundle: .main, value: "Reset Activation Durations", comment: "Reset Activation Durations")
    static let durationsAlertReallyResetMessage = NSLocalizedString("Do you really want to reset the activation durations to the default values?", tableName: "Localizable", bundle: .main, value: "Do you really want to reset the activation durations to the default values?", comment: "Do you really want to reset the activation durations to the default values?")
    static let defaultDurationInfo = NSLocalizedString("The default activation duration is used when you click on the menu bar icon.", tableName: "Localizable", bundle: .main, value: "The default activation duration is used when you click on the menu bar icon.", comment: "The default activation duration is used when you click on the menu bar icon.")
    static let setDefault = NSLocalizedString("Set Default", tableName: "Localizable", bundle: .main, value: "Set Default", comment: "Set Default")
    static let resetEllipsis = NSLocalizedString("Reset…", tableName: "Localizable", bundle: .main, value: "Reset…", comment: "Reset…")
    static let addDuration = NSLocalizedString("Add Duration", tableName: "Localizable", bundle: .main, value: "Add Duration", comment: "Add Duration")
    static let hours = NSLocalizedString("Hours", tableName: "Localizable", bundle: .main, value: "Hours", comment: "Hours")
    static let minutes = NSLocalizedString("Minutes", tableName: "Localizable", bundle: .main, value: "Minutes", comment: "Minutes")
    static let seconds = NSLocalizedString("Seconds", tableName: "Localizable", bundle: .main, value: "Seconds", comment: "Seconds")
}