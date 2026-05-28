//
//  AppDelegate.swift
//  KeepingYouAwake Launcher
//
//  Created by Marcel Dierkes on 25.12.17.
//  Copyright © 2017 Marcel Dierkes. All rights reserved.
//

import AppKit

@objc(AppDelegate)
final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let pathComponents = Bundle.main.bundlePath.components(separatedBy: "/")
        let trimmedComponents = pathComponents.dropLast(4)
        let parentAppPath = trimmedComponents.joined(separator: "/")
        if #available(macOS 11.0, *) {
            let url = URL(fileURLWithPath: "/" + parentAppPath)
            NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
        } else {
            NSWorkspace.shared.launchApplication(parentAppPath)
        }

        NSApplication.shared.terminate(nil)
    }
}