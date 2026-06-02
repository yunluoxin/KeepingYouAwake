//
//  ProcessPathMatcherTests.swift
//  KYADeviceInfoTests
//

import XCTest
@testable import KYADeviceInfo

final class ProcessPathMatcherTests: XCTestCase {
    private let cursorAgentNodePath = "/Users/east/.local/share/cursor-agent/versions/2026.06.02-8c11d9f/node"

    func testMatchesExecutableName() {
        XCTAssertTrue(ProcessPathMatcher.isTracked(path: cursorAgentNodePath, trackedNames: ["node"]))
    }

    func testMatchesPathComponent() {
        XCTAssertTrue(ProcessPathMatcher.isTracked(path: cursorAgentNodePath, trackedNames: ["cursor-agent"]))
    }

    func testPathComponentMatchIsExactNotSubstring() {
        XCTAssertFalse(ProcessPathMatcher.isTracked(path: cursorAgentNodePath, trackedNames: ["cursor"]))
        XCTAssertFalse(ProcessPathMatcher.isTracked(path: cursorAgentNodePath, trackedNames: ["agent"]))
    }

    func testMatchingIsCaseInsensitive() {
        XCTAssertTrue(ProcessPathMatcher.isTracked(path: cursorAgentNodePath, trackedNames: ["cursor-agent"]))
        XCTAssertTrue(ProcessPathMatcher.isTracked(path: cursorAgentNodePath, trackedNames: ["NODE"]))
        XCTAssertTrue(ProcessPathMatcher.isTracked(path: "/usr/local/bin/Node", trackedNames: ["node"]))
    }

    func testNoMatchForUnrelatedName() {
        XCTAssertFalse(ProcessPathMatcher.isTracked(path: cursorAgentNodePath, trackedNames: ["python"]))
    }

    func testEmptyTrackedNamesNeverMatches() {
        XCTAssertFalse(ProcessPathMatcher.isTracked(path: cursorAgentNodePath, trackedNames: []))
    }

    func testMatchesClassicHomebrewPath() {
        XCTAssertTrue(ProcessPathMatcher.isTracked(path: "/opt/homebrew/bin/node", trackedNames: ["node"]))
    }
}
