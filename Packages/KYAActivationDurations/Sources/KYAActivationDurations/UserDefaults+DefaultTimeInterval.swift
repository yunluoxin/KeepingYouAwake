//
//  UserDefaults+DefaultTimeInterval.swift
//  KYAActivationDurations
//
//  Created by Marcel Dierkes on 23.02.22.
//

import Foundation

/// The UserDefaults key for the default time interval.
public let KYAUserDefaultsKeyDefaultTimeInterval = "info.marcel-dierkes.KeepingYouAwake.TimeInterval"

extension UserDefaults {
    /// The default activation time interval stored as an integer.
    /// Decimal places are truncated (matching the original integer-based storage).
    public var kya_defaultTimeInterval: TimeInterval {
        get {
            return TimeInterval(integer(forKey: KYAUserDefaultsKeyDefaultTimeInterval))
        }
        set {
            set(Int(newValue), forKey: KYAUserDefaultsKeyDefaultTimeInterval)  // decimal places will be cut-off
        }
    }
}