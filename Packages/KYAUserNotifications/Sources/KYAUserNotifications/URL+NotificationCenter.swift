//
//  URL+NotificationCenter.swift
//  KYAUserNotifications
//
//  Created by Marcel Dierkes on 20.02.21.
//

import Foundation

extension URL {
    /// The URL for the notification settings pane in System Settings.
    public static let notificationSettingsURL = URL(
        string: "x-apple.systempreferences:com.apple.preference.notifications"
    )!
}