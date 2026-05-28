//
//  DisplayParameters.swift
//  KYAApplicationSupport
//
//  Created by Marcel Dierkes on 16.12.24.
//  Copyright © 2024 Marcel Dierkes. All rights reserved.
//
//  Rewritten in Swift from KYADisplayParameters.m.
//

import AppKit
import CoreGraphics

/// Display-related utility functions.
///
/// No KYA prefix — Swift module namespace provides isolation.
enum DisplayParameters {
    /// Maximum number of displays to query from CoreGraphics.
    private static let displayCountMax: UInt32 = 64

    /// Returns the number of connected external displays.
    ///
    /// This function also takes into account when screen mirroring is used.
    /// Falls back to `NSScreen.screens.count` if `CGGetActiveDisplayList` fails.
    public static func numberOfExternalDisplays() -> Int {
        var displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCountMax))
        var displayCount: UInt32 = 0

        let result = CGGetActiveDisplayList(displayCountMax, &displayIDs, &displayCount)
        if result != CGError.success {
            // Fall back to the NSScreen lookup
            return NSScreen.screens.count
        }

        var uniqueIDs = Set<CGDirectDisplayID>()

        for i in 0..<Int(displayCount) {
            let display = displayIDs[i]

            // Skip null display references
            if display == kCGNullDirectDisplay { continue }

            // Skip zero-width or 1-pixel-wide displays (mirrored/spurious)
            let pixelWidth = CGDisplayPixelsWide(display)
            if pixelWidth == 0 || pixelWidth == 1 { continue }

            // Skip duplicate IDs (screen mirroring)
            if uniqueIDs.contains(display) { continue }

            // Skip the main display
            if CGDisplayIsMain(display) != 0 { continue }

            uniqueIDs.insert(display)
        }

        return uniqueIDs.count
    }
}