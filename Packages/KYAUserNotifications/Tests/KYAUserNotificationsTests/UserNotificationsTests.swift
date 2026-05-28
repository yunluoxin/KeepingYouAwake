//
//  UserNotificationsTests.swift
//  KYAUserNotificationsTests
//

import XCTest
@testable import KYAUserNotifications

final class UserNotificationsTests: XCTestCase {
    // MARK: - Date+RemainingTime

    func testLocalizedRemainingTime() {
        // A date 1 hour in the future
        let futureDate = Date(timeIntervalSinceNow: 3600)
        let remaining = futureDate.localizedRemainingTime
        XCTAssertFalse(remaining.isEmpty, "localizedRemainingTime should not be empty")
        // The "with phrase" version should differ from "without phrase" version,
        // confirming the remaining phrase is present
        let withoutPhrase = futureDate.localizedRemainingTimeWithoutPhrase
        XCTAssertNotEqual(remaining, withoutPhrase, "With-phrase and without-phrase should differ")
        XCTAssertTrue(remaining.count > withoutPhrase.count, "With phrase should be longer than without phrase")
    }

    func testLocalizedRemainingTimeWithoutPhrase() {
        let futureDate = Date(timeIntervalSinceNow: 3600)
        let remaining = futureDate.localizedRemainingTimeWithoutPhrase
        XCTAssertFalse(remaining.isEmpty, "localizedRemainingTimeWithoutPhrase should not be empty")
        // Without phrase version should be shorter or different from the with-phrase version
        let withPhrase = futureDate.localizedRemainingTime
        XCTAssertNotEqual(remaining, withPhrase, "Without phrase should differ from with phrase")
    }

    func testLocalizedRemainingTimeShortInterval() {
        let futureDate = Date(timeIntervalSinceNow: 30)
        let remaining = futureDate.localizedRemainingTime
        XCTAssertFalse(remaining.isEmpty, "Should produce a string for short intervals")
    }

    // MARK: - AuthorizationStatus

    func testAuthorizationStatusValues() {
        // Verify all cases exist and are distinct
        let statuses: [AuthorizationStatus] = [.undetermined, .granted, .denied]
        XCTAssertEqual(statuses.count, 3, "Should have exactly three authorization statuses")

        // Verify equality
        XCTAssertEqual(AuthorizationStatus.undetermined, AuthorizationStatus.undetermined)
        XCTAssertEqual(AuthorizationStatus.granted, AuthorizationStatus.granted)
        XCTAssertEqual(AuthorizationStatus.denied, AuthorizationStatus.denied)

        // Verify inequality
        XCTAssertNotEqual(AuthorizationStatus.undetermined, AuthorizationStatus.granted)
        XCTAssertNotEqual(AuthorizationStatus.granted, AuthorizationStatus.denied)
        XCTAssertNotEqual(AuthorizationStatus.undetermined, AuthorizationStatus.denied)
    }

    // MARK: - UserNotification

    @available(macOS 11, *)
    func testUserNotificationConstruction() {
        let notification = UserNotification(identifier: "test-id")
        XCTAssertEqual(notification.identifier, "test-id")
        XCTAssertNil(notification.title)
        XCTAssertNil(notification.subtitle)
        XCTAssertNil(notification.bodyText)
        XCTAssertNil(notification.userInfo)
    }

    @available(macOS 11, *)
    func testUserNotificationProperties() {
        let notification = UserNotification(identifier: "test-props")
        notification.title = "Test Title"
        notification.subtitle = "Test Subtitle"
        notification.bodyText = "Test Body"
        notification.userInfo = ["key": "value"]

        XCTAssertEqual(notification.title, "Test Title")
        XCTAssertEqual(notification.subtitle, "Test Subtitle")
        XCTAssertEqual(notification.bodyText, "Test Body")
        XCTAssertEqual(notification.userInfo?["key"] as? String, "value")
    }

    @available(macOS 11, *)
    func testUserNotificationLocalizedSetters() {
        let notification = UserNotification(identifier: "test-localized")
        notification.setLocalizedTitle(key: "Test Key")
        notification.setLocalizedSubtitle(key: "Test Sub Key")
        notification.setLocalizedBodyText(key: "Test Body Key")

        // Localized setter should set a non-nil value (even if key is not found)
        XCTAssertNotNil(notification.title, "Localized title should be set")
        XCTAssertNotNil(notification.subtitle, "Localized subtitle should be set")
        XCTAssertNotNil(notification.bodyText, "Localized bodyText should be set")
    }

    @available(macOS 11, *)
    func testUserNotificationContentCreation() {
        let notification = UserNotification(identifier: "content-test")
        notification.title = "Title"
        notification.subtitle = "Subtitle"
        notification.bodyText = "Body"
        notification.userInfo = ["custom": "data"]

        let content = notification.createNotificationContent()
        XCTAssertEqual(content.title, "Title")
        XCTAssertEqual(content.subtitle, "Subtitle")
        XCTAssertEqual(content.body, "Body")
        XCTAssertEqual(content.userInfo["custom"] as? String, "data")
    }

    @available(macOS 11, *)
    func testUserNotificationContentWithNilProperties() {
        let notification = UserNotification(identifier: "nil-test")
        // title, subtitle, bodyText are all nil
        let content = notification.createNotificationContent()
        XCTAssertEqual(content.title, "", "Nil title should default to empty string in content")
        XCTAssertEqual(content.subtitle, "", "Nil subtitle should default to empty string in content")
        XCTAssertEqual(content.body, "", "Nil bodyText should default to empty string in content")
    }

    // MARK: - URL+NotificationCenter

    func testNotificationSettingsURL() {
        let url = URL.notificationSettingsURL
        XCTAssertEqual(url.absoluteString, "x-apple.systempreferences:com.apple.preference.notifications")
    }
}