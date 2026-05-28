//
//  EventTests.swift
//  KYAApplicationEventsTests
//
//  Created by Marcel Dierkes on 09.05.22.
//

import XCTest
@testable import KYAApplicationEvents

final class EventTests: XCTestCase {
    func testInitializer() {
        let expectedName = "EVENT_NAME"
        let expectedArguments: [String: String] = ["KEY_1": "1", "KEY_2": "YES"]

        let event = Event(name: expectedName, arguments: expectedArguments)
        XCTAssertEqual(event.name, expectedName)
        XCTAssertEqual(event.arguments, expectedArguments)

        let eventNoArgs = Event(name: expectedName, arguments: nil)
        XCTAssertEqual(eventNoArgs.name, expectedName)
        XCTAssertNil(eventNoArgs.arguments)
    }

    func testEquatable() {
        let expectedName = "EVENT_NAME"
        let expectedArguments: [String: String] = ["KEY_1": "1", "KEY_2": "YES"]

        let event1 = Event(name: expectedName, arguments: expectedArguments)
        let event2 = Event(name: expectedName, arguments: expectedArguments)
        XCTAssertEqual(event1, event2)

        let nilArgumentsEvent = Event(name: expectedName, arguments: nil)
        XCTAssertNotEqual(event1, nilArgumentsEvent)

        let otherEvent = Event(name: "OTHER_EVENT", arguments: [:])
        XCTAssertNotEqual(event1, otherEvent)
    }

    func testHashable() {
        let name = "EVENT_NAME"
        let arguments: [String: String] = ["KEY_1": "1"]

        let event1 = Event(name: name, arguments: arguments)
        let event2 = Event(name: name, arguments: arguments)

        var set = Set<Event>()
        set.insert(event1)
        XCTAssertTrue(set.contains(event2))

        let differentEvent = Event(name: "DIFFERENT", arguments: nil)
        set.insert(differentEvent)
        XCTAssertEqual(set.count, 2)
    }
}