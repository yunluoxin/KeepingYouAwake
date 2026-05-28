//
//  ActivationDurationTests.swift
//  KYAActivationDurationsTests
//
//  Created by Marcel Dierkes on 07.05.22.
//

import XCTest
@testable import KYAActivationDurations

final class ActivationDurationTests: XCTestCase {
    func testIndefiniteActivationDuration() {
        let duration: ActivationDuration = .indefinite
        XCTAssertEqual(duration.seconds, 0)
        XCTAssertEqual(duration, ActivationDuration.indefinite)
    }

    func testSecondsInitializer() {
        let expectedSeconds: TimeInterval = 3400.0
        let duration: ActivationDuration = ActivationDuration(seconds: expectedSeconds)
        XCTAssertEqual(duration.seconds, expectedSeconds)
    }

    func testHoursMinutesSecondsInitializer() {
        let expectedSeconds: TimeInterval = 30615
        let duration = ActivationDuration(hours: 8, minutes: 30, seconds: 15)
        XCTAssertNotNil(duration)
        XCTAssertEqual(duration?.seconds, expectedSeconds)
    }

    func testHoursMinutesSecondsInitializerValidation() {
        // minutes >= 60 should return nil
        XCTAssertNil(ActivationDuration(hours: 0, minutes: 60, seconds: 0))
        // seconds >= 60 should return nil
        XCTAssertNil(ActivationDuration(hours: 0, minutes: 0, seconds: 60))
        // zero total should return nil
        XCTAssertNil(ActivationDuration(hours: 0, minutes: 0, seconds: 0))
    }

    func testEquatable() {
        let expectedSeconds: TimeInterval = 30615
        let a: ActivationDuration = ActivationDuration(seconds: expectedSeconds)
        let b: ActivationDuration = ActivationDuration(seconds: expectedSeconds)
        let c: ActivationDuration = ActivationDuration(seconds: 0)
        XCTAssertEqual(a, b)
        XCTAssertNotEqual(a, c)
    }

    func testComparable() {
        let shorter: ActivationDuration = ActivationDuration(seconds: 300)
        let longer: ActivationDuration = ActivationDuration(seconds: 600)
        XCTAssertTrue(shorter < longer)
        XCTAssertTrue(shorter <= longer)
        XCTAssertFalse(longer < shorter)
    }

    func testCodable() throws {
        let expectedSeconds: TimeInterval = 30615
        let duration: ActivationDuration = ActivationDuration(seconds: expectedSeconds)

        // Encode
        let encoded = try JSONEncoder().encode(duration)

        // Decode
        let decoded: ActivationDuration = try JSONDecoder().decode(ActivationDuration.self, from: encoded)
        XCTAssertEqual(decoded, duration)
        XCTAssertEqual(decoded.seconds, expectedSeconds)
    }

    func testDefaultActivationDurations() {
        let durations = ActivationDuration.defaultActivationDurations
        XCTAssertEqual(durations.count, 7)
        XCTAssertEqual(durations[0].seconds, 300.0)
        XCTAssertEqual(durations[1].seconds, 600.0)
        XCTAssertEqual(durations[2].seconds, 900.0)
        XCTAssertEqual(durations[3].seconds, 1800.0)
        XCTAssertEqual(durations[4].seconds, 3600.0)
        XCTAssertEqual(durations[5].seconds, 7200.0)
        XCTAssertEqual(durations[6].seconds, 18000.0)
    }

    func testConvenienceInitMinutes() {
        let duration: ActivationDuration = ActivationDuration(minutes: 15)
        XCTAssertEqual(duration.seconds, 900.0)
    }

    func testConvenienceInitHours() {
        let duration: ActivationDuration = ActivationDuration(hours: 2)
        XCTAssertEqual(duration.seconds, 7200.0)
    }
}