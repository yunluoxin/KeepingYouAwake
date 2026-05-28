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
        let pathComponents = Bundle.main.bundlePath.pathComponents
        let pathRange = NSRange(location: 0, length: pathComponents.count - 4)
        let trimmedComponents = (pathComponents as NSArray).subarray(with: pathRange) as! [String]

        let parentAppPath = String(pathWithComponents: trimmedComponents)
        NSWorkspace.shared.launchApplication(parentAppPath)

        NSApplication.shared.terminate(nil)
    }
}