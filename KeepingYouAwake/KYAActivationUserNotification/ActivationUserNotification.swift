//
//  ActivationUserNotification.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 27.02.21.
//  Rewritten in Swift from KYAActivationUserNotification.m.
//

import Foundation
import KYAUserNotifications

@available(macOS 11.0, *)
final class ActivationUserNotification: UserNotification {
    static let identifier = "KYAActivationIdentifier"

    let fireDate: Date?
    let isActivating: Bool

    init(fireDate: Date?, activating: Bool) {
        self.fireDate = fireDate
        self.isActivating = activating
        super.init(identifier: ActivationUserNotification.identifier)

        if activating {
            if let fireDate {
                let time = fireDate.localizedRemainingTimeWithoutPhrase
                setLocalizedTitle(key: KYAL10n.preventingSleepForTimeTitle(time))
                setLocalizedBodyText(key: KYAL10n.preventingSleepForTimeBody)
            } else {
                setLocalizedTitle(key: KYAL10n.preventingSleepIndefinitelyTitle)
                setLocalizedBodyText(key: KYAL10n.preventingSleepIndefinitelyBody)
            }
        } else {
            setLocalizedTitle(key: KYAL10n.allowingSleepTitle)
            setLocalizedBodyText(key: KYAL10n.allowingSleepBody)
        }
    }
}