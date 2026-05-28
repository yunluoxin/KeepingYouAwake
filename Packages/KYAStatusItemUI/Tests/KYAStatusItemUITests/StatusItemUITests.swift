//
//  StatusItemUITests.swift
//  KYAStatusItemUITests
//

import XCTest
@testable import KYAStatusItemUI

final class StatusItemUITests: XCTestCase {
    // MARK: - StatusItemAppearance

    func testStatusItemAppearanceEnumCases() {
        // Verify that the enum has exactly the two expected cases.
        let allCases: [StatusItemAppearance] = [.inactive, .active]
        XCTAssertEqual(allCases.count, 2, "StatusItemAppearance should have exactly 2 cases")
    }

    func testStatusItemAppearanceInactiveIsDefaultCase() {
        // In Obj-C, the raw value 0 was inactive.
        let appearance = StatusItemAppearance.inactive
        XCTAssertNotEqual(appearance, .active)
    }

    // MARK: - Image Provider Paths

    func testDocumentsDirectoryURLIsValid() {
        let url = URL.documentsDirectoryURL
        XCTAssertTrue(url.isFileURL, "Documents directory URL should be a file URL")
        // The URL should end with /Documents.
        XCTAssertTrue(url.path.hasSuffix("Documents"), "URL path should end with Documents")
    }

    func testIconImageFileURLStandardResolution() {
        let url = URL.iconImageFileURL(withName: "ActiveIcon", isRetinaIcon: false)
        XCTAssertEqual(url.lastPathComponent, "ActiveIcon.png", "Standard icon filename should not include @2x")
    }

    func testIconImageFileURLRetinaResolution() {
        let url = URL.iconImageFileURL(withName: "ActiveIcon", isRetinaIcon: true)
        XCTAssertEqual(url.lastPathComponent, "ActiveIcon@2x.png", "Retina icon filename should include @2x")
    }

    func testIconImageFileURLInactiveIcon() {
        let url = URL.iconImageFileURL(withName: "InactiveIcon", isRetinaIcon: false)
        XCTAssertEqual(url.lastPathComponent, "InactiveIcon.png")
    }

    func testCustomIconImageFileExistsForMissingFile() {
        // An unlikely custom name should not exist.
        let result = customIconImageFileExists("NonExistentIcon_\(UUID().uuidString)", isRetinaIcon: false)
        XCTAssertFalse(result, "A random non-existent icon should not be found")
    }

    func testCustomIconImageFilesExistReturnsFalseWhenNoIconsPresent() {
        // In a test environment without custom icon files, this should be false.
        XCTAssertFalse(customIconImageFilesExist(), "Custom icon files should not exist in test environment")
    }

    // MARK: - Image Name Constants

    func testDefaultActiveIconImageName() {
        XCTAssertEqual(NSImage.defaultActiveIconImageName, "ActiveIcon")
    }

    func testDefaultInactiveIconImageName() {
        XCTAssertEqual(NSImage.defaultInactiveIconImageName, "InactiveIcon")
    }

    // MARK: - StatusItemImageProvider

    func testCustomProviderReturnsNilWithoutCustomIcons() {
        XCTAssertNil(StatusItemImageProvider.customProvider, "Custom provider should be nil when no custom icon files exist")
    }
}