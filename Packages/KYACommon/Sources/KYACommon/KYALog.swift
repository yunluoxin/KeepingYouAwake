import Foundation
import os
import CLogShim

/// Unified logging class with global enable/disable switch.
/// Uses C os_log shim for macOS 10.13+ compatibility.
/// For formatted messages, use Swift string interpolation: `KYALog.shared.debug("Value: \(val)")`
public final class KYALog {
    public static let shared = KYALog()

    private let subsystem = "info.marcel-dierkes.KeepingYouAwake"
    private var logs: [String: OSLog] = [:]
    private let queue = DispatchQueue(label: "KYALog")

    /// When false, debug/info/error messages are suppressed. Faults always log.
    public var isEnabled = true

    private init() {}

    /// Returns an OSLog for the given category.
    public func log(for category: String) -> OSLog {
        return queue.sync {
            if let existing = logs[category] { return existing }
            let newLog = kya_log_create(subsystem, category)!
            logs[category] = newLog
            return newLog
        }
    }

    public func debug(_ message: String, category: String = "Default") {
        guard isEnabled else { return }
        kya_log_debug(log(for: category), message)
    }

    public func info(_ message: String, category: String = "Default") {
        guard isEnabled else { return }
        kya_log_info(log(for: category), message)
    }

    public func error(_ message: String, category: String = "Default") {
        guard isEnabled else { return }
        kya_log_error(log(for: category), message)
    }

    public func fault(_ message: String, category: String = "Default") {
        // Faults always log regardless of isEnabled
        kya_log_fault(log(for: category), message)
    }
}