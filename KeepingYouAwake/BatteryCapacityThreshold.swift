//
//  BatteryCapacityThreshold.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 01.01.16.
//  Rewritten in Swift from KYABatteryCapacityThreshold.h.
//

import Foundation

/// Value type wrapper for battery capacity threshold settings.
enum BatteryCapacityThreshold {
    /// Notification name posted when the threshold value changes.
    static let didChangeNotification = Notification.Name("KYABatteryCapacityThresholdDidChangeNotification")
}