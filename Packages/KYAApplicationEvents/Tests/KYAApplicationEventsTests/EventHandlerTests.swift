//
//  EventHandlerTests.swift
//  KYAApplicationEventsTests
//
//  Created by Marcel Dierkes on 10.05.22.
//

import XCTest
@testable import KYAApplicationEvents

final class EventHandlerTests: XCTestCase {
    private var eventHandler: EventHandler!

    override func setUp() {
        super.setUp()
        eventHandler = EventHandler()
    }

    override func tearDown() {
        eventHandler = nil
        super.tearDown()
    }

    func testDefaultHandler() {
        let first = EventHandler.defaultHandler
        let second = EventHandler.defaultHandler
        XCTAssertTrue(first === second)

        let newHandler = EventHandler()
        XCTAssertFalse(first === newHandler)
    }

    func testRegisterAndRemoveAction() {
        let expectedActionName = "ACTION_NAME"
        eventHandler.registerAction(name: expectedActionName, block: { _ in })
        eventHandler.registerAction(name: "SECOND_ACTION", block: { _ in })

        eventHandler.removeAction(name: expectedActionName)

        // Removing a non-existent action should not crash
        eventHandler.removeAction(name: expectedActionName)
        eventHandler.removeAction(name: "UNKNOWN_NAME")
    }

    func testHandleEvent() {
        let expectedURL = URL(string: "appscheme:///deactivate")!
        let expectedName = "deactivate"

        let expectation = self.expectation(description: "handleEvent")

        eventHandler.registerAction(name: expectedName) { event in
            XCTAssertEqual(event.name, expectedName)
            XCTAssertNil(event.arguments)
            expectation.fulfill()
        }
        eventHandler.handleEvent(url: expectedURL)

        waitForExpectations(timeout: 5.0)
    }

    func testHandleEventWithArguments() {
        let expectedURL = URL(string: "appscheme:///activate?seconds=5")!
        let expectedName = "activate"
        let expectedArguments = ["seconds": "5"]

        let expectation = self.expectation(description: "handleEventWithArguments")

        eventHandler.registerAction(name: expectedName) { event in
            XCTAssertEqual(event.name, expectedName)
            XCTAssertEqual(event.arguments, expectedArguments)
            expectation.fulfill()
        }

        // Register a different action that should NOT be called
        eventHandler.registerAction(name: "deactivate") { _ in
            XCTFail("Unexpected action called")
        }
        eventHandler.handleEvent(url: expectedURL)

        waitForExpectations(timeout: 5.0)
    }

    func testHandleEventWithNilURL() {
        // Passing nil should not crash or dispatch anything
        eventHandler.handleEvent(url: nil)
    }
}