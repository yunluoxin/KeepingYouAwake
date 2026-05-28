//
//  DeviceTests.swift
//  KYADeviceInfoTests
//
//  Created by Marcel Dierkes on 2026-05-28.
//

import XCTest
@testable import KYADeviceInfo

final class DeviceTests: XCTestCase {
    // MARK: - Device Singleton

    func testDeviceSingletonReturnsSameInstance() {
        let device1 = Device.current
        let device2 = Device.current
        XCTAssertTrue(device1 === device2, "Device.current should always return the same singleton instance")
    }

    func testDeviceHasMonitorProperties() {
        let device = Device.current
        XCTAssertNotNil(device.batteryMonitor)
        XCTAssertNotNil(device.lowPowerModeMonitor)
        XCTAssertNotNil(device.processMonitor)
    }

    // MARK: - Monitor Protocol

    func testBatteryMonitorInitiallyNotRegistered() {
        let monitor = BatteryMonitor()
        XCTAssertFalse(monitor.isRegistered, "BatteryMonitor should not be registered initially")
    }

    func testLowPowerModeMonitorInitiallyNotRegistered() {
        let monitor = LowPowerModeMonitor()
        XCTAssertFalse(monitor.isRegistered, "LowPowerModeMonitor should not be registered initially")
    }

    func testProcessMonitorInitiallyNotRegistered() {
        let monitor = ProcessMonitor()
        XCTAssertFalse(monitor.isRegistered, "ProcessMonitor should not be registered initially")
    }

    func testBatteryMonitorRegisterUnregisterCycle() {
        let monitor = BatteryMonitor()
        monitor.register()
        XCTAssertTrue(monitor.isRegistered)
        monitor.unregister()
        XCTAssertFalse(monitor.isRegistered)
    }

    func testLowPowerModeMonitorRegisterUnregisterCycle() {
        guard #available(macOS 12.0, *) else {
            // Low Power Mode not supported on older macOS
            return
        }
        let monitor = LowPowerModeMonitor()
        monitor.register()
        XCTAssertTrue(monitor.isRegistered)
        monitor.unregister()
        XCTAssertFalse(monitor.isRegistered)
    }

    func testProcessMonitorRegisterUnregisterCycle() {
        let monitor = ProcessMonitor()
        monitor.trackedProcessNames = ["test_process"]
        monitor.register()
        XCTAssertTrue(monitor.isRegistered)
        monitor.unregister()
        XCTAssertFalse(monitor.isRegistered)
        XCTAssertTrue(monitor.currentlyRunningProcessPaths.isEmpty)
    }

    // MARK: - BatteryMonitor Constants

    func testBatteryMonitorCapacityUnavailableValue() {
        XCTAssertEqual(batteryCapacityUnavailable, -1.0, "Battery capacity unavailable sentinel should be -1.0")
    }

    func testBatteryMonitorStateEnumValues() {
        // Verify all BatteryState enum cases exist and match expected rawValues
        XCTAssertEqual(BatteryState.unknown.rawValue, 0)
        XCTAssertEqual(BatteryState.unplugged.rawValue, 1)
        XCTAssertEqual(BatteryState.charging.rawValue, 2)
        XCTAssertEqual(BatteryState.full.rawValue, 3)
    }

    // Note: BatteryMonitor.hasBattery, currentCapacity, and state properties
    // call IOKit/IOPS C APIs that crash under the XCTest runner sandbox.
    // These properties should be tested in the full app context, not via SPM tests.

    // MARK: - LowPowerModeMonitor Properties

    func testLowPowerModeMonitorSupportsLowPowerMode() {
        let monitor = LowPowerModeMonitor()
        if #available(macOS 12.0, *) {
            XCTAssertTrue(monitor.supportsLowPowerMode)
        } else {
            XCTAssertFalse(monitor.supportsLowPowerMode)
        }
    }

    func testLowPowerModeMonitorIsEnabled() {
        let monitor = LowPowerModeMonitor()
        // Just verify the API is accessible; actual value depends on system state.
        _ = monitor.isLowPowerModeEnabled
    }

    // MARK: - ProcessMonitor Matching

    func testProcessMonitorTrackedProcessNames() {
        let monitor = ProcessMonitor()
        monitor.trackedProcessNames = ["caffeinate", "node"]
        XCTAssertTrue(monitor.trackedProcessNames.contains("caffeinate"))
        XCTAssertTrue(monitor.trackedProcessNames.contains("node"))
        XCTAssertEqual(monitor.trackedProcessNames.count, 2)
    }

    func testProcessMonitorInitiallyNoRunningProcesses() {
        let monitor = ProcessMonitor()
        XCTAssertTrue(monitor.currentlyRunningProcessPaths.isEmpty)
    }

    func testProcessMonitorOnProcessChangeCallback() {
        let monitor = ProcessMonitor()
        var callbackInvoked = false
        monitor.onProcessChange = { isRunning, paths in
            callbackInvoked = true
        }
        // Register and unregister to verify no crash with callback set
        monitor.trackedProcessNames = ["nonexistent_binary_xyz"]
        monitor.register()
        // Unregister immediately; callback should not have been invoked for nonexistent process
        monitor.unregister()
        XCTAssertFalse(callbackInvoked)
    }

    // MARK: - Device Parameter Enum

    func testDeviceParameterValues() {
        XCTAssertEqual(DeviceParameter.batteryCapacity.rawValue, "batteryCapacity")
        XCTAssertEqual(DeviceParameter.lowPowerMode.rawValue, "lowPowerMode")
        XCTAssertEqual(DeviceParameter.externalDisplay.rawValue, "externalDisplay")
    }

    // MARK: - Device Monitoring Toggle

    func testDeviceBatteryMonitoringToggleOff() {
        let device = Device.current
        device.batteryMonitoringEnabled = false
        XCTAssertFalse(device.isBatteryMonitoringEnabled)
    }

    func testDeviceLowPowerModeMonitoringToggleOff() {
        let device = Device.current
        device.lowPowerModeMonitoringEnabled = false
        XCTAssertFalse(device.isLowPowerModeMonitoringEnabled)
    }

    func testDeviceProcessMonitoringToggleOff() {
        let device = Device.current
        device.processMonitoringEnabled = false
        XCTAssertFalse(device.isProcessMonitoringEnabled)
    }

    func testDeviceOnChangeCallback() {
        let device = Device.current
        let expectation = XCTestExpectation(description: "onChange callback should be invoked")

        device.onChange = { parameter in
            XCTAssertEqual(parameter, .batteryCapacity)
            expectation.fulfill()
        }

        // Manually trigger the notification
        device.notifyParameterChange(.batteryCapacity)
        wait(for: [expectation], timeout: 2.0)

        device.onChange = nil
    }

    func testDeviceProcessMonitoringChangeCallback() {
        let device = Device.current
        var changeCalled = false
        device.onProcessMonitoringChange = {
            changeCalled = true
        }
        device.onProcessMonitoringChange?()
        XCTAssertTrue(changeCalled)
        device.onProcessMonitoringChange = nil
    }
}