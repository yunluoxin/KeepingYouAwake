//
//  Date+RemainingTime.swift
//  KYAUserNotifications
//
//  Created by Marcel Dierkes on 08.08.19.
//

import Foundation

extension Date {
    private static let dateComponentsFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute, .hour]
        formatter.unitsStyle = .short
        formatter.includesTimeRemainingPhrase = true
        return formatter
    }()

    /// A localized string describing the remaining time until this date,
    /// including the "remaining" phrase.
    public var localizedRemainingTime: String {
        let startDate = Date(timeInterval: -1, since: self)
        return Self.dateComponentsFormatter.string(from: startDate, to: self) ?? ""
    }

    /// A localized string describing the remaining time until this date,
    /// without the "remaining" phrase.
    public var localizedRemainingTimeWithoutPhrase: String {
        let formatter = Self.dateComponentsFormatterWithoutPhrase
        let startDate = Date(timeInterval: -1, since: self)
        return formatter.string(from: startDate, to: self) ?? ""
    }

    private static let dateComponentsFormatterWithoutPhrase: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second, .minute, .hour]
        formatter.unitsStyle = .short
        formatter.includesTimeRemainingPhrase = false
        return formatter
    }()
}