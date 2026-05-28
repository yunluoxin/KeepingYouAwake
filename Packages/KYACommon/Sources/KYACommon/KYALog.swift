import Foundation
import os

public final class KYALog {
    public static let shared = KYALog()
    private let subsystem = "info.marcel-dierkes.KeepingYouAwake"
    private var loggers: [String: Logger] = [:]
    private let queue = DispatchQueue(label: "KYALog")
    public var isEnabled = true
    private init() {}

    public func logger(for category: String) -> Logger {
        return queue.sync {
            if let existing = loggers[category] { return existing }
            let newLogger = Logger(subsystem: subsystem, category: category)
            loggers[category] = newLogger
            return newLogger
        }
    }

    public func debug(_ message: String, category: String = "Default") {
        guard isEnabled else { return }
        logger(for: category).debug("\(message, privacy: .public)")
    }

    public func info(_ message: String, category: String = "Default") {
        guard isEnabled else { return }
        logger(for: category).info("\(message, privacy: .public)")
    }

    public func error(_ message: String, category: String = "Default") {
        guard isEnabled else { return }
        logger(for: category).error("\(message, privacy: .public)")
    }

    public func fault(_ message: String, category: String = "Default") {
        // Faults always log regardless of isEnabled
        logger(for: category).fault("\(message, privacy: .public)")
    }
}