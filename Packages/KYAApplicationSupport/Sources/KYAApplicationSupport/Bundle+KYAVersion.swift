//
//  Bundle+KYAVersion.swift
//  KYAApplicationSupport
//
//  Created by Marcel Dierkes on 30.03.21.
//  Copyright © 2021 Marcel Dierkes. All rights reserved.
//
//  Rewritten in Swift from NSBundle+KYAVersion.m.
//

import Foundation

extension Bundle {
    /// Returns the marketing version of this bundle, that is set
    /// as the `CFBundleShortVersionString` Info.plist value.
    /// e.g. 1.2.3
    @objc var kya_shortVersionString: String? {
        infoDictionary?["CFBundleShortVersionString"] as? String
    }

    /// Returns the build number of this bundle, that is set
    /// as the `CFBundleVersion` Info.plist value.
    /// e.g. 1020301
    @objc var kya_buildVersionString: String? {
        infoDictionary?["CFBundleVersion"] as? String
    }

    /// Returns the full version string by combining the short version and build version.
    /// e.g. 1.2.3 (1020301)
    @objc var kya_fullVersionString: String? {
        guard let short = kya_shortVersionString, let build = kya_buildVersionString else {
            return nil
        }
        return "\(short) (\(build))"
    }

    /// Returns the `NSHumanReadableCopyright` Info.plist value for
    /// the human-readable copyright.
    @objc var kya_localizedCopyrightString: String? {
        infoDictionary?["NSHumanReadableCopyright"] as? String
    }
}