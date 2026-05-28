//
//  Monitor.swift
//  KYADeviceInfo
//
//  Created by Marcel Dierkes on 2026-05-28.
//

import Foundation

/// A protocol for monitors that can be registered and unregistered
/// to observe system state changes.
public protocol Monitor: AnyObject {
    /// Whether the monitor is currently registered for state changes.
    var isRegistered: Bool { get }

    /// Registers the monitor to begin receiving state change notifications.
    func register()

    /// Unregisters the monitor, stopping state change notifications.
    func unregister()
}