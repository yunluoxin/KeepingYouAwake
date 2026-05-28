//
//  AuthorizationStatus.swift
//  KYAUserNotifications
//
//  Created by Marcel Dierkes on 13.02.21.
//

/// Represents the current authorization status for posting user notifications.
public enum AuthorizationStatus {
    /// The user has not been prompted for confirming the
    /// user notification authorization status.
    case undetermined

    /// The user has granted authorization for posting
    /// user notifications.
    case granted

    /// The user denied authorization for posting user
    /// notifications.
    case denied
}