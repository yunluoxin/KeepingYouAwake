//
//  UserDefaultsDefaultTimeIntervalTests.swift
//  KYAActivationDurationsTests
//
//  Created by Marcel Dierkes on 08.05.22.
//

import XCTest
@testable import KYAActivationDurations

final class UserDefaultsDefaultTimeIntervalTests: XCTestCase {
    override func setUp() {
        super.setUp()

        let userDefaults = UserDefaults.standard
        userDefaults.removeObject(forKey: KYAUserDefaultsKeyDefaultTimeInterval)
    }

    func testDefaultTimeInterval() {
        let userDefaults = UserDefaults.standard
        XCTAssertEqual(userDefaults.kya_defaultTimeInterval, 0.0)

        userDefaults.kya_defaultTimeInterval = 18000.0
        XCTAssertEqual(userDefaults.kya_defaultTimeInterval, 18000.0)

        // Test the decimal cut-off:
        userDefaults.kya_defaultTimeInterval = 432.5
        XCTAssertEqual(userDefaults.kya_defaultTimeInterval, 432.0)

        userDefaults.kya_defaultTimeInterval = 0.0
        XCTAssertEqual(userDefaults.kya_defaultTimeInterval, 0.0)
    }

    func testDefaultTimeIntervalKeys() {
        let userDefaults = UserDefaults.standard
        XCTAssertEqual(userDefaults.kya_defaultTimeInterval, 0.0)
        XCTAssertEqual(userDefaults.double(forKey: KYAUserDefaultsKeyDefaultTimeInterval), 0.0)

        userDefaults.kya_defaultTimeInterval = 18000.0
        XCTAssertEqual(userDefaults.double(forKey: KYAUserDefaultsKeyDefaultTimeInterval),
                       18000.0)

        // Test the decimal cut-off:
        userDefaults.set(432.5, forKey: KYAUserDefaultsKeyDefaultTimeInterval)
        XCTAssertEqual(userDefaults.kya_defaultTimeInterval, 432.0)

        userDefaults.removeObject(forKey: KYAUserDefaultsKeyDefaultTimeInterval)
        XCTAssertEqual(userDefaults.kya_defaultTimeInterval, 0.0)
    }
}