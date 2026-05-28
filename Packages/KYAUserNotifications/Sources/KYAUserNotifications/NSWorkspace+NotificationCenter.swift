//
//  NSWorkspace+NotificationCenter.swift
//  KYAUserNotifications
//
//  Created by Marcel Dierkes on 20.02.21.
//

import AppKit

extension NSWorkspace {
    /// Opens the notifications pane in System Settings.
    /// - Parameter completion: An optional completion handler called with the
    ///   running application and any error.
    @available(macOS 11, *)
    public func openNotificationSettings(
        completion: ((NSRunningApplication?, Error?) -> Void)? = nil
    ) {
        let prefURL = URL.notificationSettingsURL
        let config = NSWorkspace.OpenConfiguration()
        config.addsToRecentItems = false

        openApplication(at: prefURL, configuration: config) { app, error in
            completion?(app, error)
        }
    }
}