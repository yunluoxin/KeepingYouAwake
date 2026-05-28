//
//  UserNotification.swift
//  KYAUserNotifications
//
//  Created by Marcel Dierkes on 13.02.21.
//

import Foundation
import UserNotifications

/// A generic user notification object usable for creating
/// custom dedicated user notification subclasses.
@available(macOS 11, *)
open class UserNotification {
    /// A unique notification identifier, used for grouping purposes.
    public var identifier: String

    /// A short reason description.
    /// - Note: Use `setLocalizedTitle` instead for setting this
    ///         property with a localization-aware string.
    public var title: String?

    /// A short secondary reason description.
    /// - Note: Use `setLocalizedSubtitle` instead for setting this
    ///         property with a localization-aware string.
    public var subtitle: String?

    /// The user notification message.
    /// - Note: Use `setLocalizedBodyText` instead for setting this
    ///         property with a localization-aware string.
    public var bodyText: String?

    /// Arbitrary custom information related to the user notification.
    public var userInfo: [AnyHashable: Any]?

    public init(identifier: String) {
        self.identifier = identifier
    }

    // MARK: - Localized Setters

    /// Sets `title` with a localization-aware string and arguments.
    /// - Parameter key: A localized string key
    /// - Parameter arguments: Optional localized string arguments
    public func setLocalizedTitle(key: String, arguments: [Any]? = nil) {
        title = NSString.localizedUserNotificationString(forKey: key, arguments: arguments)
    }

    /// Sets `subtitle` with a localization-aware string and arguments.
    /// - Parameter key: A localized string key
    /// - Parameter arguments: Optional localized string arguments
    public func setLocalizedSubtitle(key: String, arguments: [Any]? = nil) {
        subtitle = NSString.localizedUserNotificationString(forKey: key, arguments: arguments)
    }

    /// Sets `bodyText` with a localization-aware string and arguments.
    /// - Parameter key: A localized string key
    /// - Parameter arguments: Optional localized string arguments
    public func setLocalizedBodyText(key: String, arguments: [Any]? = nil) {
        bodyText = NSString.localizedUserNotificationString(forKey: key, arguments: arguments)
    }

    // MARK: - Notification Content

    /// Creates a `UNNotificationContent` from this notification's properties.
    @available(macOS 11, *)
    func createNotificationContent() -> UNNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title ?? ""
        content.subtitle = subtitle ?? ""
        content.body = bodyText ?? ""
        if let userInfo {
            content.userInfo = userInfo
        }
        return content as UNNotificationContent
    }
}