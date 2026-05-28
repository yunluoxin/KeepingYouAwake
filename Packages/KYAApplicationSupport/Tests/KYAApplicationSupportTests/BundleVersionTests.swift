//
//  BundleVersionTests.swift
//  KYAApplicationSupportTests
//
//  Created by Marcel Dierkes on 11.05.22.
//  Copyright © 2022 Marcel Dierkes. All rights reserved.
//
//  Rewritten in Swift from KYABundleVersionTests.m.
//

import XCTest
@testable import KYAApplicationSupport

final class BundleVersionTests: XCTestCase {
    private var bundle: Bundle!

    override func setUp() {
        super.setUp()
        let parentBundle = Bundle.module
        let testBundleURL = parentBundle.url(forResource: "TestBundle", withExtension: "bundle")!
        bundle = Bundle(url: testBundleURL)!
    }

    override func tearDown() {
        bundle = nil
        super.tearDown()
    }

    func testShortVersionString() {
        XCTAssertEqual(bundle.kya_shortVersionString, "1.2.3")
    }

    func testBuildVersionString() {
        XCTAssertEqual(bundle.kya_buildVersionString, "1020301")
    }

    func testFullVersionString() {
        XCTAssertEqual(bundle.kya_fullVersionString, "1.2.3 (1020301)")
    }

    func testLocalizedCopyrightString() {
        XCTAssertEqual(bundle.kya_localizedCopyrightString, "A human-readable copyright.")
    }
}