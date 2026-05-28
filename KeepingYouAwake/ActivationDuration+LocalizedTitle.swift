//
//  ActivationDuration+LocalizedTitle.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 23.02.22.
//  Rewritten in Swift from KYAActivationDuration+KYALocalizedTitle.m.
//

import Foundation
import KYAActivationDurations

extension ActivationDuration {
    /// A localized title representation of this duration.
    var localizedTitle: String {
        if seconds == 0 {
            return KYAL10n.indefinitely
        }
        return sharedFormatter.string(fromTimeInterval: seconds) ?? ""
    }

    private static let sharedFormatter: DateComponentsFormatter = {
        let formatter = DateComponentsFormatter()
        formatter.unitsStyle = .full
        return formatter
    }()
}