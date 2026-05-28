//
//  UserDefaultsKeysTests.swift
//  KYAApplicationSupportTests
//
//  Created by Marcel Dierkes on 11.05.22.
//  Copyright © 2022 Marcel Dierkes. All rights reserved.
//
//  Rewritten in Swift from KYAUserDefaultsKeysTests.m.
//

import XCTest
@testable import KYAApplicationSupport

final class UserDefaultsKeysTests: XCTestCase {
    private var defaults: UserDefaults!

    override func setUp() {
        super.setUp()
        defaults = UserDefaults(suiteName: "UserDefaultsKeysTests")
    }

    override func tearDown() {
        // Clean up all stored values
        for key in [
            UserDefaults.activateOnLaunchKey,
            UserDefaults.allowDisplaySleepKey,
            UserDefaults.menuBarIconHighlightDisabledKey,
            UserDefaults.preReleaseUpdatesEnabledKey,
            UserDefaults.quitOnTimerExpirationEnabledKey,
            UserDefaults.activateOnExternalDisplayConnectedEnabledKey,
            UserDefaults.deactivateOnUserSwitchEnabledKey,
            UserDefaults.batteryCapacityThresholdEnabledKey,
            UserDefaults.lowPowerModeMonitoringEnabledKey,
            UserDefaults.batteryCapacityThresholdKey,
            UserDefaults.processNamesKey,
        ] {
            defaults.removeObject(forKey: key)
        }
        UserDefaults.standard.removeSuite(named: "UserDefaultsKeysTests")
        defaults = nil
        super.tearDown()
    }

    // MARK: - Bool Property Tests

    func testActivateOnLaunch() {
        let key = UserDefaults.activateOnLaunchKey

        defaults.kya_activateOnLaunch = true
        XCTAssertTrue(defaults.kya_activateOnLaunch)
        XCTAssertTrue(defaults.bool(forKey: key))

        defaults.kya_activateOnLaunch = false
        XCTAssertFalse(defaults.kya_activateOnLaunch)
        XCTAssertFalse(defaults.bool(forKey: key))

        defaults.set(true, forKey: key)
        XCTAssertTrue(defaults.kya_activateOnLaunch)
    }

    func testAllowDisplaySleep() {
        let key = UserDefaults.allowDisplaySleepKey

        defaults.kya_allowDisplaySleep = true
        XCTAssertTrue(defaults.kya_allowDisplaySleep)
        XCTAssertTrue(defaults.bool(forKey: key))

        defaults.kya_allowDisplaySleep = false
        XCTAssertFalse(defaults.kya_allowDisplaySleep)
        XCTAssertFalse(defaults.bool(forKey: key))

        defaults.set(true, forKey: key)
        XCTAssertTrue(defaults.kya_allowDisplaySleep)
    }

    func testMenuBarIconHighlightDisabled() {
        let key = UserDefaults.menuBarIconHighlightDisabledKey

        defaults.kya_menuBarIconHighlightDisabled = true
        XCTAssertTrue(defaults.kya_menuBarIconHighlightDisabled)
        XCTAssertTrue(defaults.bool(forKey: key))

        defaults.kya_menuBarIconHighlightDisabled = false
        XCTAssertFalse(defaults.kya_menuBarIconHighlightDisabled)
        XCTAssertFalse(defaults.bool(forKey: key))
    }

    func testPreReleaseUpdatesEnabled() {
        let key = UserDefaults.preReleaseUpdatesEnabledKey

        defaults.kya_preReleaseUpdatesEnabled = true
        XCTAssertTrue(defaults.kya_preReleaseUpdatesEnabled)
        XCTAssertTrue(defaults.bool(forKey: key))

        defaults.kya_preReleaseUpdatesEnabled = false
        XCTAssertFalse(defaults.kya_preReleaseUpdatesEnabled)
        XCTAssertFalse(defaults.bool(forKey: key))
    }

    func testQuitOnTimerExpirationEnabled() {
        let key = UserDefaults.quitOnTimerExpirationEnabledKey

        defaults.kya_quitOnTimerExpirationEnabled = true
        XCTAssertTrue(defaults.kya_quitOnTimerExpirationEnabled)
        XCTAssertTrue(defaults.bool(forKey: key))

        defaults.kya_quitOnTimerExpirationEnabled = false
        XCTAssertFalse(defaults.kya_quitOnTimerExpirationEnabled)
        XCTAssertFalse(defaults.bool(forKey: key))
    }

    func testActivateOnExternalDisplayConnectedEnabled() {
        let key = UserDefaults.activateOnExternalDisplayConnectedEnabledKey

        defaults.kya_activateOnExternalDisplayConnectedEnabled = true
        XCTAssertTrue(defaults.kya_activateOnExternalDisplayConnectedEnabled)
        XCTAssertTrue(defaults.bool(forKey: key))

        defaults.kya_activateOnExternalDisplayConnectedEnabled = false
        XCTAssertFalse(defaults.kya_activateOnExternalDisplayConnectedEnabled)
        XCTAssertFalse(defaults.bool(forKey: key))
    }

    func testDeactivateOnUserSwitchEnabled() {
        let key = UserDefaults.deactivateOnUserSwitchEnabledKey

        defaults.kya_deactivateOnUserSwitchEnabled = true
        XCTAssertTrue(defaults.kya_deactivateOnUserSwitchEnabled)
        XCTAssertTrue(defaults.bool(forKey: key))

        defaults.kya_deactivateOnUserSwitchEnabled = false
        XCTAssertFalse(defaults.kya_deactivateOnUserSwitchEnabled)
        XCTAssertFalse(defaults.bool(forKey: key))
    }

    func testBatteryCapacityThresholdEnabled() {
        let key = UserDefaults.batteryCapacityThresholdEnabledKey

        defaults.kya_batteryCapacityThresholdEnabled = true
        XCTAssertTrue(defaults.kya_batteryCapacityThresholdEnabled)
        XCTAssertTrue(defaults.bool(forKey: key))

        defaults.kya_batteryCapacityThresholdEnabled = false
        XCTAssertFalse(defaults.kya_batteryCapacityThresholdEnabled)
        XCTAssertFalse(defaults.bool(forKey: key))
    }

    func testLowPowerModeMonitoringEnabled() {
        let key = UserDefaults.lowPowerModeMonitoringEnabledKey

        defaults.kya_lowPowerModeMonitoringEnabled = true
        XCTAssertTrue(defaults.kya_lowPowerModeMonitoringEnabled)
        XCTAssertTrue(defaults.bool(forKey: key))

        defaults.kya_lowPowerModeMonitoringEnabled = false
        XCTAssertFalse(defaults.kya_lowPowerModeMonitoringEnabled)
        XCTAssertFalse(defaults.bool(forKey: key))
    }

    // MARK: - Battery Capacity Threshold

    func testBatteryCapacityThreshold() {
        let key = UserDefaults.batteryCapacityThresholdKey

        // Normal value
        defaults.kya_batteryCapacityThreshold = 90.0
        XCTAssertEqual(defaults.kya_batteryCapacityThreshold, 90.0)
        XCTAssertEqual(defaults.float(forKey: key), 90.0)

        // Set directly
        defaults.set(Float(50.0), forKey: key)
        XCTAssertEqual(defaults.kya_batteryCapacityThreshold, 50.0)

        // Below 10% — the getter clamps to 10.0
        defaults.kya_batteryCapacityThreshold = 0.1
        XCTAssertEqual(defaults.kya_batteryCapacityThreshold, 10.0)
        XCTAssertEqual(defaults.float(forKey: key), 0.1)

        // Set directly below 10% — getter still clamps
        defaults.set(Float(0.2), forKey: key)
        XCTAssertEqual(defaults.kya_batteryCapacityThreshold, 10.0)

        // Over 100% (no upper bound enforcement, matching original behavior)
        defaults.kya_batteryCapacityThreshold = 512.0
        XCTAssertEqual(defaults.kya_batteryCapacityThreshold, 512.0)
        XCTAssertEqual(defaults.float(forKey: key), 512.0)
    }

    // MARK: - Process Names

    func testProcessNames() {
        let key = UserDefaults.processNamesKey

        // Default is empty array
        XCTAssertEqual(defaults.kya_processNames, [])

        // Set some names
        defaults.kya_processNames = ["Terminal", "Safari"]
        XCTAssertEqual(defaults.kya_processNames, ["Terminal", "Safari"])
        XCTAssertEqual(defaults.stringArray(forKey: key), ["Terminal", "Safari"])

        // Set empty array
        defaults.kya_processNames = []
        XCTAssertEqual(defaults.kya_processNames, [])
    }
}