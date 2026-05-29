//
//  ActivationDurationsController.swift
//  KYAActivationDurations
//
//  Created by Marcel Dierkes on 28.07.19.
//  Copyright © 2019 Marcel Dierkes. All rights reserved.
//

import Foundation
import KYACommon

/// Manages adding and removing of activation durations, persistence,
/// and provides the ability to mark a duration as the default.
public final class ActivationDurationsController {
    /// The shared singleton instance.
    public static let shared = ActivationDurationsController(userDefaults: .standard)

    /// A callback invoked whenever the activation durations change.
    public var onChangeDurations: (() -> Void)?

    /// The underlying user defaults used for persistence.
    public let userDefaults: UserDefaults

    /// All available activation durations, sorted ascending by seconds.
    /// This always includes the indefinite activation duration at index 0
    /// (or wherever 0 seconds falls in the sorted order).
    public var activationDurations: [ActivationDuration] {
        var durations = storedActivationDurations
        durations.append(ActivationDuration.indefinite)
        return durations.sorted()
    }

    /// The activation duration marked as default.
    /// Setting this persists the value to UserDefaults.
    public var defaultActivationDuration: ActivationDuration? {
        get {
            let seconds = userDefaults.kya_defaultTimeInterval
            if seconds == ActivationDuration.indefinite.seconds {
                return ActivationDuration.indefinite
            }
            return storedActivationDurations.first(where: { $0.seconds == seconds })
        }
        set {
            guard let duration = newValue,
                  activationDurations.contains(duration) else { return }
            userDefaults.kya_defaultTimeInterval = duration.seconds
            userDefaults.synchronize()
        }
    }

    private var storedActivationDurations: [ActivationDuration]

    /// The designated initializer.
    /// For typical usage, prefer `ActivationDurationsController.shared`.
    ///
    /// - Parameter userDefaults: A UserDefaults instance for persistence.
    public init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        self.storedActivationDurations = []
        loadFromUserDefaults()
    }

    // MARK: - Add & Remove

    /// Adds an activation duration if it is not already stored.
    ///
    /// - Parameter activationDuration: The duration to add.
    /// - Returns: `true` if the duration was added; `false` if it was already present.
    @discardableResult
    public func add(_ activationDuration: ActivationDuration) -> Bool {
        if storedActivationDurations.contains(activationDuration) {
            return false
        }
        storedActivationDurations.append(activationDuration)
        didChange()
        return true
    }

    /// Removes an activation duration if it is present.
    ///
    /// - Parameter activationDuration: The duration to remove.
    /// - Returns: `true` if the duration was removed; `false` if it was not present.
    @discardableResult
    public func remove(_ activationDuration: ActivationDuration) -> Bool {
        guard let index = storedActivationDurations.firstIndex(of: activationDuration) else {
            return false
        }
        storedActivationDurations.remove(at: index)

        // Reset the default duration if the removed one was the default.
        if defaultActivationDuration == nil || defaultActivationDuration == activationDuration {
            defaultActivationDuration = ActivationDuration.indefinite
        }

        didChange()
        return true
    }

    // MARK: - Index Access

    /// Returns whether the activation duration at the given index can be removed.
    /// The indefinite duration (0 seconds) cannot be removed.
    ///
    /// - Parameter index: An index into `activationDurations`.
    /// - Returns: `true` if the duration at the index can be removed.
    public func canRemoveActivationDuration(at index: Int) -> Bool {
        let durations = activationDurations
        guard index < durations.count else { return false }
        return durations[index].seconds != 0
    }

    /// Removes the activation duration at the given index.
    ///
    /// - Parameter index: An index into `activationDurations`.
    /// - Returns: `true` if a duration was removed.
    @discardableResult
    public func removeActivationDuration(at index: Int) -> Bool {
        let durations = activationDurations
        guard index < durations.count else { return false }
        let duration = durations[index]
        guard duration.seconds != 0 else { return false }
        return remove(duration)
    }

    /// Marks the activation duration at the given index as the default.
    ///
    /// - Parameter index: An index into `activationDurations`.
    public func setActivationDurationAsDefault(at index: Int) {
        let durations = activationDurations
        guard index < durations.count else { return }
        defaultActivationDuration = durations[index]
        didChange()
    }

    // MARK: - Reset

    /// Resets all activation durations to the default set.
    public func resetActivationDurations() {
        restoreDefaultDurations()

        // Reset the default duration if it got removed.
        if defaultActivationDuration == nil {
            defaultActivationDuration = ActivationDuration.indefinite
        }

        didChange()
    }

    // MARK: - Private

    private func restoreDefaultDurations() {
        storedActivationDurations = ActivationDuration.defaultActivationDurations
    }

    private func didChange() {
        saveToUserDefaults()
        onChangeDurations?()
    }

    // MARK: - UserDefaults Persistence

    private static let defaultsKeyDurations = "info.marcel-dierkes.KeepingYouAwake.Durations"

    private func loadFromUserDefaults() {
        // Load as [Int] array of second values (KYA_USES_SIMPLE_USER_DEFAULTS_VALUES=1).
        if let secondsArray = userDefaults.object(forKey: Self.defaultsKeyDurations) as? [Int] {
            let loaded = secondsArray.map { ActivationDuration(seconds: TimeInterval($0)) }
            if loaded.isEmpty {
                restoreDefaultDurations()
                saveToUserDefaults()
            } else {
                storedActivationDurations = loaded
                KYALog.shared.debug("Loaded durations from user defaults: \(loaded)")
            }
        } else {
            restoreDefaultDurations()
            saveToUserDefaults()
        }
    }

    private func saveToUserDefaults() {
        // Save as [Int] array of second values (KYA_USES_SIMPLE_USER_DEFAULTS_VALUES=1).
        let secondsArray = storedActivationDurations.map { Int($0.seconds) }
        userDefaults.set(secondsArray, forKey: Self.defaultsKeyDurations)
        userDefaults.synchronize()

        KYALog.shared.debug("Saved durations to user defaults: \(storedActivationDurations)")
    }
}