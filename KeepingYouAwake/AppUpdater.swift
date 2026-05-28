//
//  AppUpdater.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 26.09.21.
//  Rewritten in Swift from KYAAppUpdater.m.
//

import Foundation
import KYAApplicationSupport

#if KYA_APP_UPDATER_ENABLED
import Sparkle

final class AppUpdater: NSObject, SPUUpdaterDelegate {
    static let defaultAppUpdater = AppUpdater()

    private let updaterController: SPUStandardUpdaterController

    private static let releaseFeedURL = "https://newmarcel.github.io/KeepingYouAwake/appcast.xml"
    private static let preReleaseFeedURL = "https://newmarcel.github.io/KeepingYouAwake/prerelease-appcast.xml"

    var updater: SPUUpdater {
        updaterController.updater
    }

    private override init() {
        updaterController = SPUStandardUpdaterController(updaterDelegate: self, userDriverDelegate: nil)
        super.init()
    }

    func checkForUpdates(_ sender: Any?) {
        updaterController.checkForUpdates(sender)
    }

    // MARK: - SPUUpdaterDelegate

    func feedURLStringForUpdater(_ updater: SPUUpdater) -> String? {
        UserDefaults.standard.kya_preReleaseUpdatesEnabled
            ? AppUpdater.preReleaseFeedURL
            : AppUpdater.releaseFeedURL
    }
}
#endif