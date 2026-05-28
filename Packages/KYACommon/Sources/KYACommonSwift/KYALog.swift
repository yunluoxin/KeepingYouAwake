//
//  KYALog.swift
//  KYACommonSwift
//
//  Provides a Swift-friendly logging interface for use across KYA packages.
//  Uses NSLog for macOS 10.13 compatibility (the Swift os_log API and os_log_t
//  require macOS 10.14+).
//

import Foundation

/// A Swift-accessible logging interface.
///
/// Logs messages via NSLog for macOS 10.13 compatibility.
/// On macOS 10.14+, this could be extended to use the os_log C API
/// via an Objective-C bridge for proper subsystem/category support.
public struct KYALog {
    /// The shared log instance using the default KeepingYouAwake subsystem.
    public static let shared = KYALog(category: "Default")

    /// The log category identifier.
    public let category: String

    /// Creates a log with the given category.
    public init(category: String) {
        self.category = category
    }

    /// Logs a debug message.
    public func debug(_ message: String) {
        NSLog("[KeepingYouAwake] [%@] [DEBUG] %@", category, message)
    }

    /// Logs an error message.
    public func error(_ message: String) {
        NSLog("[KeepingYouAwake] [%@] [ERROR] %@", category, message)
    }

    /// Logs a fault message.
    public func fault(_ message: String) {
        NSLog("[KeepingYouAwake] [%@] [FAULT] %@", category, message)
    }

    /// Logs an info message.
    public func info(_ message: String) {
        NSLog("[KeepingYouAwake] [%@] [INFO] %@", category, message)
    }
}