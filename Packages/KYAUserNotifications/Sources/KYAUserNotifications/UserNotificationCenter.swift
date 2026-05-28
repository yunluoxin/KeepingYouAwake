//
//  UserNotificationCenter.swift
//  KYAUserNotifications
//
//  Created by Marcel Dierkes on 13.02.21.
//

import Foundation
import UserNotifications
import os

/// Manages authorization and posting of user notifications.
@available(macOS 11, *)
public final class UserNotificationCenter {
    /// The primary user notification center.
    /// - Note: Prefer using this object instead of creating new instances.
    public static let sharedCenter = UserNotificationCenter()

    private let center: UNUserNotificationCenter
    private let log = OSLog(subsystem: "info.marcel-dierkes.KeepingYouAwake", category: "UserNotifications")

    private init() {
        center = UNUserNotificationCenter.current()
    }

    /// Creates a center backed by a specific `UNUserNotificationCenter`.
    /// - Parameter center: The backing UNUserNotificationCenter instance
    init(center: UNUserNotificationCenter) {
        self.center = center
    }

    // MARK: - Authorization Status

    /// Retrieves the current user notification authorization status.
    /// - Parameter completion: A completion handler with the user's current
    ///   authorization status; returns on the main queue.
    public func getAuthorizationStatus(completion: @escaping (AuthorizationStatus) -> Void) {
        center.getNotificationSettings { settings in
            let authStatus: AuthorizationStatus
            switch settings.authorizationStatus {
            case .notDetermined:
                authStatus = .undetermined
            case .provisional, .authorized:
                authStatus = .granted
            default:
                authStatus = .denied
            }
            DispatchQueue.main.async {
                completion(authStatus)
            }
        }
    }

    /// Requests authorization for posting user notifications.
    /// - Parameter completion: An optional completion handler with the
    ///   authorization status and any error; returns on the main queue.
    public func requestAuthorization(completion: ((AuthorizationStatus, Error?) -> Void)? = nil) {
        let options: UNAuthorizationOptions = [.alert, .provisional]
        center.requestAuthorization(options: options) { granted, error in
            let status: AuthorizationStatus
            if let error {
                os_log("Failed to request notification access: %{public}@", log: self.log, type: .error, error as NSError)
                status = .denied
            } else if granted {
                status = .granted
            } else {
                status = .undetermined
            }

            if let completion {
                DispatchQueue.main.async {
                    completion(status, error)
                }
            }
        }
    }

    /// A convenience method to request authorization for posting user
    /// notifications when the user's authorization status is `undetermined`.
    public func requestAuthorizationIfUndetermined() {
        center.getNotificationSettings { settings in
            if settings.authorizationStatus == .notDetermined {
                self.requestAuthorization()
            }
        }
    }

    // MARK: - Notification Handling

    /// Posts a user notification if the user has granted authorization.
    /// - Parameter notification: A user notification
    public func postNotification(_ notification: UserNotification) {
        let content = notification.createNotificationContent()
        let identifier = notification.identifier

        let request = UNNotificationRequest(
            identifier: identifier,
            content: content,
            trigger: nil
        )

        center.add(request) { error in
            if let error {
                os_log("Failed to add notification request: %{public}@", log: self.log, type: .error, error as NSError)
            }
        }
    }

    /// Removes all previously delivered user notifications from the
    /// notification center.
    public func clearAllDeliveredNotifications() {
        center.removeAllDeliveredNotifications()
    }
}

// MARK: - Legacy Fallback for macOS < 11

/// Posts a notification via the deprecated `NSUserNotificationCenter`
/// for macOS versions prior to 11.0.
/// - Note: On macOS 11 and later, use `UserNotificationCenter.postNotification()` instead.
@available(macOS, introduced: 10.8, deprecated: 10.14, message: "Use UserNotificationCenter on macOS 11+")
public func postLegacyUserNotification(
    title: String?,
    subtitle: String?,
    bodyText: String?,
    userInfo: [String: Any]? = nil
) {
    let notification = NSUserNotification()
    notification.title = title
    notification.subtitle = subtitle
    notification.informativeText = bodyText
    if let userInfo {
        notification.userInfo = userInfo
    }
    NSUserNotificationCenter.default.deliver(notification)
}