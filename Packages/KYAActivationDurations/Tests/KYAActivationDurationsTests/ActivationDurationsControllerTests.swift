//
//  ActivationDurationsControllerTests.swift
//  KYAActivationDurationsTests
//
//  Created by Marcel Dierkes on 08.05.22.
//

import XCTest
@testable import KYAActivationDurations

final class ActivationDurationsControllerTests: XCTestCase {
    private var controller: ActivationDurationsController!

    override func setUp() {
        super.setUp()

        let defaults = UserDefaults.standard
        controller = ActivationDurationsController(userDefaults: defaults)
        controller.resetActivationDurations()
        controller.defaultActivationDuration = ActivationDuration.indefinite
    }

    func testSharedControllerIdentity() {
        XCTAssertTrue(ActivationDurationsController.shared === ActivationDurationsController.shared)
        XCTAssertFalse(ActivationDurationsController.shared === controller)
    }

    func testInitializer() {
        XCTAssertEqual(controller.defaultActivationDuration, ActivationDuration.indefinite)

        let expectedDurations: [ActivationDuration] = [ActivationDuration.indefinite] + ActivationDuration.defaultActivationDurations
        XCTAssertEqual(controller.activationDurations, expectedDurations)
    }

    func testDefaultActivationDuration() {
        let newDefault = controller.activationDurations[2]
        controller.defaultActivationDuration = newDefault
        XCTAssertEqual(controller.defaultActivationDuration, newDefault)
    }

    func testAddAndRemoveActivationDuration() {
        let newDuration: ActivationDuration = ActivationDuration(seconds: 1986.0)
        XCTAssertTrue(controller.add(newDuration))
        XCTAssertTrue(controller.activationDurations.contains(newDuration))

        let duplicateDuration: ActivationDuration = ActivationDuration(seconds: 1986.0)
        XCTAssertFalse(controller.add(duplicateDuration))

        let notAddedDuration: ActivationDuration = ActivationDuration(seconds: 2063.0)
        XCTAssertFalse(controller.activationDurations.contains(notAddedDuration))
        XCTAssertFalse(controller.remove(notAddedDuration))

        controller.add(notAddedDuration)
        XCTAssertTrue(controller.remove(notAddedDuration))
    }

    func testRemoveActivationDurationAtIndex() {
        let count = controller.activationDurations.count
        for i in 0..<count {
            if i == 0 {
                // The indefinite duration cannot be removed
                XCTAssertFalse(controller.removeActivationDuration(at: 0))
                continue
            }
            XCTAssertTrue(controller.removeActivationDuration(at: 1))
        }
        XCTAssertEqual(controller.activationDurations.count, 1)

        // Out of bounds
        XCTAssertFalse(controller.removeActivationDuration(at: 2063))
    }

    func testSetActivationDurationAsDefaultAtIndex() {
        XCTAssertEqual(controller.defaultActivationDuration, ActivationDuration.indefinite)

        let secondDuration = controller.activationDurations[2]
        controller.setActivationDurationAsDefault(at: 2)
        XCTAssertEqual(controller.defaultActivationDuration, secondDuration)

        // Out of bounds
        controller.setActivationDurationAsDefault(at: 2063)
        XCTAssertEqual(controller.defaultActivationDuration, secondDuration)
    }

    func testResetActivationDurations() {
        XCTAssertEqual(controller.activationDurations.count, 8)

        controller.removeActivationDuration(at: 1)
        controller.removeActivationDuration(at: 1)
        controller.removeActivationDuration(at: 1)

        let duration: ActivationDuration = ActivationDuration(seconds: 1986.0)
        controller.add(duration)

        XCTAssertEqual(controller.activationDurations.count, 6)

        controller.resetActivationDurations()
        let expectedDurations: [ActivationDuration] = [ActivationDuration.indefinite] + ActivationDuration.defaultActivationDurations
        XCTAssertEqual(controller.activationDurations, expectedDurations)
    }

    func testOnChangeDurationsCallback() {
        var changeCount = 0
        controller.onChangeDurations = { changeCount += 1 }

        let newDuration: ActivationDuration = ActivationDuration(seconds: 1986.0)
        controller.add(newDuration)
        XCTAssertEqual(changeCount, 1)

        // Setting default via setter persists but does not call onChangeDurations.
        // setActivationDurationAsDefault does trigger onChangeDurations.
        controller.setActivationDurationAsDefault(at: controller.activationDurations.firstIndex(of: newDuration) ?? 0)
        XCTAssertEqual(changeCount, 2)

        controller.remove(newDuration)
        XCTAssertEqual(changeCount, 3)

        controller.resetActivationDurations()
        XCTAssertEqual(changeCount, 4)
    }
}