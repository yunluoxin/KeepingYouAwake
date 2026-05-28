//
//  UserDefaultsSetting.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 18.12.15.
//  Rewritten in Swift from KYAUserDefaultsSetting.m.
//

import Foundation

/// UI model: a Bool setting backed by UserDefaults with a display title.
struct UserDefaultsSetting {
    let title: String
    let key: String

    var value: Bool {
        get { UserDefaults.standard.bool(forKey: key) }
        set {
            if newValue {
                UserDefaults.standard.set(true, forKey: key)
            } else {
                UserDefaults.standard.removeObject(forKey: key)
            }
            UserDefaults.standard.synchronize()
        }
    }

    func reset() {
        UserDefaults.standard.removeObject(forKey: key)
    }
}