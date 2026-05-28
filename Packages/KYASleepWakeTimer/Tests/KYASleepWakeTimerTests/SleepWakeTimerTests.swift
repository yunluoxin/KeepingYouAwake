//  SleepWakeTimerTests.swift
//  KYASleepWakeTimerTests
//
//  Tests for the Swift SleepWakeTimer (Process wrapper for caffeinate).
//

import XCTest
@testable import KYASleepWakeTimer

final class SleepWakeTimerTests: XCTestCase {

    var timer: SleepWakeTimer!

    override func setUp() {
        timer = SleepWakeTimer()
    }

    override func tearDown() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Indefinite Mode (timeInterval == 0)

    func testIndefiniteTimeIntervalConstantIsZero() {
        XCTAssertEqual(indefiniteTimeInterval, 0)
    }

    func testIndefiniteModeSetsNoFireDate() {
        timer.schedule(timeInterval: indefiniteTimeInterval)
        XCTAssertNil(timer.fireDate,
                     "Indefinite mode should not set a fireDate")
        XCTAssertEqual(timer.scheduledTimeInterval, 0)
        XCTAssertTrue(timer.isScheduled,
                      "Timer should be scheduled after calling schedule")
    }

    func testIndefiniteModeCaffeinateArgumentsNoTimeout() {
        let args = timer.caffeinateArguments(forTimeInterval: 0)
        // Should NOT contain -t flag
        XCTAssertFalse(args.contains("-t"),
                       "Indefinite mode should not include -t flag")
        XCTAssertFalse(args.contains(where: { $0.hasPrefix("-t") }),
                       "No -t variant should appear in arguments")
    }

    func testIndefiniteModeCaffeinateArgumentsIncludesWatchFlag() {
        let args = timer.caffeinateArguments(forTimeInterval: 0)
        XCTAssertTrue(args.contains("-w"),
                       "Arguments must include -w process watch flag")
        XCTAssertTrue(args.contains(String(ProcessInfo.processInfo.processIdentifier)),
                       "Arguments must include current PID after -w")
    }

    // MARK: - Timed Mode (timeInterval > 0)

    func testTimedModeSetsFireDate() {
        let interval: TimeInterval = 5
        timer.schedule(timeInterval: interval)
        XCTAssertNotNil(timer.fireDate,
                        "Timed mode should set a fireDate")
        XCTAssertEqual(timer.scheduledTimeInterval, interval)
        XCTAssertTrue(timer.isScheduled)
    }

    func testTimedModeFireDateIsApproximatelyNowPlusInterval() {
        let interval: TimeInterval = 10
        let before = Date().addingTimeInterval(interval)
        timer.schedule(timeInterval: interval)
        let after = Date().addingTimeInterval(interval)

        if let fireDate = timer.fireDate {
            XCTAssertGreaterThanOrEqual(fireDate, before,
                                        "fireDate should be >= now + interval")
            XCTAssertLessThanOrEqual(fireDate, after,
                                      "fireDate should be <= now + interval (tolerance)")
        } else {
            XCTFail("fireDate should not be nil in timed mode")
        }
    }

    func testTimedModeCaffeinateArgumentsIncludeTimeout() {
        let args = timer.caffeinateArguments(forTimeInterval: 300)
        XCTAssertTrue(args.contains("-t"),
                       "Timed mode should include -t flag")
        // Verify the seconds value appears as a separate argument after -t
        if let tIndex = args.firstIndex(of: "-t") {
            let nextIndex = tIndex + 1
            XCTAssertLessThan(nextIndex, args.count,
                              "-t should be followed by a seconds value")
            XCTAssertEqual(args[nextIndex], "300",
                           "Seconds value should be formatted without decimal")
        } else {
            XCTFail("-t flag not found in arguments")
        }
    }

    // MARK: - Display Sleep Flags

    func testCaffeinateArgumentsDisplaySleepAllowed() {
        // When display sleep is allowed, caffeinate uses -i
        UserDefaults.standard.kya_allowDisplaySleep = true
        let args = timer.caffeinateArguments(forTimeInterval: 0)
        XCTAssertTrue(args.contains("-i"),
                       "When display sleep allowed, should include -i flag")
        XCTAssertFalse(args.contains("-di"),
                       "When display sleep allowed, should NOT include -di flag")
    }

    func testCaffeinateArgumentsDisplaySleepPrevented() {
        // When display sleep is prevented, caffeinate uses -di
        UserDefaults.standard.kya_allowDisplaySleep = false
        let args = timer.caffeinateArguments(forTimeInterval: 0)
        XCTAssertTrue(args.contains("-di"),
                       "When display sleep prevented, should include -di flag")
        XCTAssertFalse(args.contains("-i"),
                       "When display sleep prevented, should NOT include bare -i")
    }

    // MARK: - Invalidation Lifecycle

    func testInvalidationResetsAllState() {
        timer.schedule(timeInterval: 5)
        timer.invalidate()
        XCTAssertFalse(timer.isScheduled,
                       "Timer should not be scheduled after invalidation")
        XCTAssertNil(timer.fireDate,
                     "fireDate should be nil after invalidation")
        XCTAssertEqual(timer.scheduledTimeInterval, 0,
                       "scheduledTimeInterval should be 0 after invalidation")
    }

    func testInvalidationCallsCompletionWithCancelledTrue() {
        let expectation = XCTestExpectation(
            description: "Completion called with cancelled=true"
        )

        timer.schedule(timeInterval: 5, completion: { cancelled in
            XCTAssertTrue(cancelled,
                          "Manual invalidation should pass cancelled=true")
            expectation.fulfill()
        })

        timer.invalidate()
        wait(for: [expectation], timeout: 2.0)
    }

    func testInvalidationCallsOnDeactivate() {
        let expectation = XCTestExpectation(
            description: "onDeactivate called after invalidation"
        )

        timer.onDeactivate = {
            expectation.fulfill()
        }

        timer.schedule(timeInterval: 5)
        timer.invalidate()
        wait(for: [expectation], timeout: 2.0)
    }

    func testCompletionBlockOnlyCalledOnce() {
        var callCount = 0
        let expectation = XCTestExpectation(
            description: "Completion called exactly once"
        )
        expectation.expectedFulfillmentCount = 1

        timer.schedule(timeInterval: 5, completion: { _ in
            callCount += 1
            expectation.fulfill()
        })

        timer.invalidate()
        timer.invalidate()  // Second invalidate should not double-call

        wait(for: [expectation], timeout: 2.0)
        XCTAssertEqual(callCount, 1,
                       "Completion block should only be called once")
    }

    // MARK: - OnActivate Callback

    func testScheduleCallsOnActivate() {
        let expectation = XCTestExpectation(
            description: "onActivate called with time interval"
        )
        let expectedInterval: TimeInterval = 5

        timer.onActivate = { interval in
            XCTAssertEqual(interval, expectedInterval,
                           "onActivate should receive the scheduled interval")
            expectation.fulfill()
        }

        timer.schedule(timeInterval: expectedInterval)
        wait(for: [expectation], timeout: 1.0)
    }

    func testScheduleOverwritesPreviousSchedule() {
        // First schedule
        timer.schedule(timeInterval: 10)
        XCTAssertEqual(timer.scheduledTimeInterval, 10)

        // Wait for completion from first schedule (invalidated by second)
        let expectation = XCTestExpectation(
            description: "Completion from first schedule"
        )
        var firstCompletionCalled = false
        timer.schedule(timeInterval: 5, completion: { _ in
            firstCompletionCalled = true
            expectation.fulfill()
        })
        XCTAssertEqual(timer.scheduledTimeInterval, 5)

        timer.invalidate()
        wait(for: [expectation], timeout: 2.0)
        XCTAssertTrue(firstCompletionCalled)
    }

    // MARK: - Argument Format Consistency

    func testCaffeinateArgumentsSeparateFlags() {
        // Verify -t and -w use separate flag/value arguments
        // (not combined like "-t 300" or "-w 12345" as one string)
        let args = timer.caffeinateArguments(forTimeInterval: 300)
        for arg in args {
            // No argument should contain a space (combined flag+value)
            XCTAssertFalse(arg.contains(" "),
                           "Each argument should be a separate element: '\(arg)'")
        }
    }
}