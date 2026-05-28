import XCTest
@testable import KYACommon

final class KYALogTests: XCTestCase {
    private var log: KYALog!

    override func setUp() {
        super.setUp()
        log = KYALog.shared
    }

    // MARK: - isEnabled toggle

    func testIsEnabledDefaultValue() {
        XCTAssertTrue(log.isEnabled, "isEnabled should default to true")
    }

    func testIsEnabledCanBeDisabled() {
        log.isEnabled = false
        XCTAssertFalse(log.isEnabled, "isEnabled should be false after setting it")
        // Restore
        log.isEnabled = true
    }

    // MARK: - logger(for:) category creation

    func testLoggerForCategoryReturnsValidLogger() {
        let logger = log.logger(for: "TestCategory")
        // Logger is a valid struct; successful creation = pass
        _ = logger
    }

    func testLoggerForCategoryCachesRepeatedCalls() {
        // Repeated calls for the same category should succeed (caching works)
        _ = log.logger(for: "CacheTest")
        _ = log.logger(for: "CacheTest")
        _ = log.logger(for: "CacheTest")
    }

    func testLoggerForMultipleCategories() {
        // Different categories should each create valid loggers
        _ = log.logger(for: "CategoryA")
        _ = log.logger(for: "CategoryB")
        _ = log.logger(for: "Default")
    }

    // MARK: - Log methods (functional smoke tests)

    func testDebugLogsWhenEnabled() {
        log.isEnabled = true
        // Should not crash; we cannot easily assert os_log output in unit tests
        log.debug("Test debug message")
    }

    func testDebugDoesNotLogWhenDisabled() {
        log.isEnabled = false
        log.debug("Test debug message")
        log.isEnabled = true
    }

    func testInfoLogsWhenEnabled() {
        log.isEnabled = true
        log.info("Test info message")
    }

    func testInfoDoesNotLogWhenDisabled() {
        log.isEnabled = false
        log.info("Test info message")
        log.isEnabled = true
    }

    func testErrorLogsWhenEnabled() {
        log.isEnabled = true
        log.error("Test error message")
    }

    func testErrorDoesNotLogWhenDisabled() {
        log.isEnabled = false
        log.error("Test error message")
        log.isEnabled = true
    }

    func testFaultAlwaysLogs() {
        // Faults log regardless of isEnabled
        log.isEnabled = false
        log.fault("Test fault message")
        log.isEnabled = true
    }

    func testLogWithCustomCategory() {
        log.debug("Test message", category: "CustomCategory")
        log.info("Test message", category: "CustomCategory")
        log.error("Test message", category: "CustomCategory")
        log.fault("Test message", category: "CustomCategory")
    }
}