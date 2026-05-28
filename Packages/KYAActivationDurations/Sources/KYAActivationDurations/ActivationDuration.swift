//
//  ActivationDuration.swift
//  KYAActivationDurations
//
//  Created by Marcel Dierkes on 19.12.15.
//  Copyright © 2015 Marcel Dierkes. All rights reserved.
//

import Foundation
import KYACommon

/// A sleepwake timer activation duration.
///
/// Use `seconds == 0` to represent an indefinite activation duration.
public struct ActivationDuration: Codable, Equatable, Comparable {
    /// An activation duration in seconds. 0 represents an indefinite duration.
    public let seconds: TimeInterval

    /// An indefinite activation duration (0 seconds).
    public static let indefinite: ActivationDuration = ActivationDuration(seconds: 0)

    /// The standard set of activation durations: 5min, 10min, 15min, 30min, 1h, 2h, 5h.
    public static var defaultActivationDurations: [ActivationDuration] {
        return [
            ActivationDuration(minutes: 5),
            ActivationDuration(minutes: 10),
            ActivationDuration(minutes: 15),
            ActivationDuration(minutes: 30),
            ActivationDuration(hours: 1),
            ActivationDuration(hours: 2),
            ActivationDuration(hours: 5)
        ]
    }

    /// Creates an activation duration from a number of seconds.
    ///
    /// - Parameter seconds: A time interval in seconds. Pass 0 for an indefinite duration.
    public init(seconds: TimeInterval) {
        self.seconds = seconds
    }

    /// Creates an activation duration from hours, minutes, and seconds components.
    ///
    /// Component values must be within valid ranges:
    /// - minutes must be < 60
    /// - seconds must be < 60
    /// - the total must be > 0 (use `ActivationDuration.indefinite` for indefinite)
    ///
    /// Returns nil if any validation fails.
    ///
    /// - Parameters:
    ///   - hours: The hours component.
    ///   - minutes: The minutes component (must be 0..59).
    ///   - seconds: The seconds component (must be 0..59).
    public init?(hours: Int = 0, minutes: Int = 0, seconds: Int = 0) {
        if minutes >= 60 {
            KYALog.shared.error("Attempted to add a duration with a minutes component value greater than an hour.")
            return nil
        }
        if seconds >= 60 {
            KYALog.shared.error("Attempted to add a duration with a seconds component value greater than a minute.")
            return nil
        }

        // Direct integer computation replaces C++ chrono.
        // Calendar/DateComponents distance(to:) requires macOS 10.15+,
        // so we compute the total seconds directly.
        let computed: TimeInterval = TimeInterval(hours * 3600 + minutes * 60 + seconds)

        if computed <= 0 {
            KYALog.shared.error("Attempted to add a 0 duration.")
            return nil
        }

        self.seconds = computed
    }

    // MARK: - Comparable

    public static func < (lhs: ActivationDuration, rhs: ActivationDuration) -> Bool {
        return lhs.seconds < rhs.seconds
    }

    // MARK: - Codable

    private enum CodingKeys: String, CodingKey {
        case kyaSeconds
    }

    public init(from decoder: Decoder) throws {
        // Support both the legacy NSSecureCoding key name and a simple encoding.
        let container = try decoder.singleValueContainer()
        if let intValue = try? container.decode(Int.self) {
            // Int encoding (matches KYA_USES_SIMPLE_USER_DEFAULTS_VALUES=1).
            self.seconds = TimeInterval(intValue)
        } else if let doubleValue = try? container.decode(Double.self) {
            self.seconds = doubleValue
        } else {
            // Legacy keyed container encoding (KYASeconds key).
            let keyedContainer = try decoder.container(keyedBy: CodingKeys.self)
            self.seconds = try keyedContainer.decode(Double.self, forKey: .kyaSeconds)
        }
    }

    public func encode(to encoder: Encoder) throws {
        // Encode as a single integer value to match
        // KYA_USES_SIMPLE_USER_DEFAULTS_VALUES=1 persistence.
        var container = encoder.singleValueContainer()
        try container.encode(Int(seconds))
    }
}

// MARK: - Convenience Initializers

extension ActivationDuration {
    /// Creates an activation duration from a number of minutes.
    public init(minutes: Int) {
        self.seconds = TimeInterval(minutes * 60)
    }

    /// Creates an activation duration from a number of hours.
    public init(hours: Int) {
        self.seconds = TimeInterval(hours * 3600)
    }
}