//  SleepWakeTimerTests.swift
//  KYASleepWakeTimerTests
//
//  Tests for the Swift SleepWakeTimer (IOKit power assertion holder).
//

import XCTest
@testable import KYASleepWakeTimer

final class SleepWakeTimerTests: XCTestCase {

    var timer: SleepWakeTimer!
    private var originalAllowDisplaySleep: Bool!

    override func setUp() {
        super.setUp()
        timer = SleepWakeTimer()
        originalAllowDisplaySleep = UserDefaults.standard.kya_allowDisplaySleep
    }

    override func tearDown() {
        timer?.invalidate()
        timer = nil
        UserDefaults.standard.kya_allowDisplaySleep = originalAllowDisplaySleep
        super.tearDown()
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

    // MARK: - Display Sleep Options

    func testActivityOptionsDisplaySleepAllowed() {
        UserDefaults.standard.kya_allowDisplaySleep = true
        let options = timer.activityOptions
        XCTAssertTrue(options.contains(.idleSystemSleepDisabled),
                      "System sleep must always be disabled")
        XCTAssertFalse(options.contains(.idleDisplaySleepDisabled),
                       "When display sleep is allowed, display sleep must not be disabled")
    }

    func testActivityOptionsDisplaySleepPrevented() {
        UserDefaults.standard.kya_allowDisplaySleep = false
        let options = timer.activityOptions
        XCTAssertTrue(options.contains(.idleSystemSleepDisabled),
                      "System sleep must always be disabled")
        XCTAssertTrue(options.contains(.idleDisplaySleepDisabled),
                      "When display sleep is prevented, display sleep must be disabled too")
    }

    // MARK: - Power Assertion

    func testScheduleHoldsPowerAssertion() {
        timer.schedule(timeInterval: indefiniteTimeInterval)
        XCTAssertTrue(timer.holdsSystemSleepAssertion(),
                      "Scheduling must hold an idle system sleep assertion")
    }

    func testInvalidationReleasesPowerAssertion() {
        timer.schedule(timeInterval: indefiniteTimeInterval)
        XCTAssertTrue(timer.holdsSystemSleepAssertion())

        timer.invalidate()
        XCTAssertFalse(timer.holdsSystemSleepAssertion(),
                       "Invalidation must release the power assertion")
    }

    /// macOS drops every power assertion when `powerd` restarts, without
    /// telling the holder. The timer must detect that and recreate it.
    func testDroppedAssertionIsRearmed() {
        timer.schedule(timeInterval: indefiniteTimeInterval)
        XCTAssertTrue(timer.holdsSystemSleepAssertion())

        // Simulate the system dropping the assertion behind our back.
        if let activity = timer.activity {
            ProcessInfo.processInfo.endActivity(activity)
        }
        XCTAssertFalse(timer.holdsSystemSleepAssertion(),
                       "Precondition: the assertion should be gone")

        timer.verifyAndRearm()
        XCTAssertTrue(timer.holdsSystemSleepAssertion(),
                      "A dropped assertion must be recreated")
        XCTAssertTrue(timer.isScheduled)
    }

    func testVerifyAndRearmKeepsExistingAssertion() {
        timer.schedule(timeInterval: indefiniteTimeInterval)
        let activity = timer.activity

        timer.verifyAndRearm()

        XCTAssertTrue(timer.holdsSystemSleepAssertion())
        XCTAssertTrue(activity === timer.activity,
                      "A still valid assertion must not be recreated")
    }

    // MARK: - Heartbeat

    func testHeartbeatRequirementMatchesOSVersion() {
        let expected = ProcessInfo.processInfo.isOperatingSystemAtLeast(
            OperatingSystemVersion(majorVersion: 26, minorVersion: 0, patchVersion: 0)
        )
        XCTAssertEqual(SleepWakeTimer.isHeartbeatRequired, expected)
    }

    /// The heartbeat only exists on systems that drop assertions on `powerd` restarts.
    func testHeartbeatIsOnlyCreatedWhenRequired() {
        timer.schedule(timeInterval: indefiniteTimeInterval)

        if SleepWakeTimer.isHeartbeatRequired {
            XCTAssertNotNil(timer.heartbeatTimer,
                            "The heartbeat must run on macOS 26 and later")
        } else {
            XCTAssertNil(timer.heartbeatTimer,
                         "The heartbeat must not run on systems that keep the assertion")
        }
    }

    func testInvalidationStopsTheHeartbeat() {
        timer.schedule(timeInterval: indefiniteTimeInterval)
        timer.invalidate()
        XCTAssertNil(timer.heartbeatTimer,
                     "Invalidation must stop the heartbeat")
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

    /// Rescheduling must release the previous assertion instead of stacking.
    func testReschedulingReplacesTheAssertion() {
        timer.schedule(timeInterval: indefiniteTimeInterval)
        let first = timer.activity

        timer.schedule(timeInterval: indefiniteTimeInterval)

        XCTAssertFalse(first === timer.activity,
                       "Rescheduling must replace the previous assertion")
        XCTAssertTrue(timer.holdsSystemSleepAssertion())
    }
}
