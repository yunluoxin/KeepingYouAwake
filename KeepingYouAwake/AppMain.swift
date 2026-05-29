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
        let menu = MainMenuBuilder.build(activationDurationsSubMenu: appDelegate.appController.menuController.menu)
        appDelegate.appController.menu = menu
        app.mainMenu = menu
        app.setActivationPolicy(.accessory)
        app.run()
    }
}