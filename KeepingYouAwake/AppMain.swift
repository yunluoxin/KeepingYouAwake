//
//  AppMain.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 17.10.14.
//  Rewritten in Swift from main.m.
//

import AppKit

@main
struct AppMain {
    static func main() {
        let app = NSApplication.shared
        let appDelegate = AppDelegate()
        app.delegate = appDelegate
        app.mainMenu = MainMenuBuilder.build(activationDurationsSubMenu: appDelegate.appController.menuController.menu)
        app.setActivationPolicy(.accessory)
        app.run()
    }
}