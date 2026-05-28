//
//  StatusItemImageProvider.swift
//  KYAStatusItemUI
//
//  Created by Marcel Dierkes on 17.08.15.
//  Copyright © 2015 Marcel Dierkes. All rights reserved.
//

import AppKit

/// Provides active and inactive icon images for the status item.
///
/// Uses a singleton `currentProvider` pattern: returns the custom provider
/// if all four icon files exist in the Documents directory, otherwise falls
/// back to the standard provider that loads from the asset catalog.
final class StatusItemImageProvider {
    /// An icon image representing the active state.
    let activeIconImage: NSImage

    /// An icon image representing the inactive state.
    let inactiveIconImage: NSImage

    /// Returns the current status item icon provider.
    ///
    /// Always returns the same instance during the lifetime of the app.
    /// Prefers the custom provider if custom icon files exist, otherwise
    /// uses the standard provider.
    static let currentProvider: StatusItemImageProvider = {
        customProvider ?? standardProvider
    }()

    /// Returns a menu bar icon provider for the built-in icon images.
    ///
    /// Requires `ActiveIcon` and `InactiveIcon` assets in the asset catalog.
    static let standardProvider: StatusItemImageProvider = {
        StatusItemImageProvider(
            activeIcon: NSImage.defaultActiveIconImage,
            inactiveIcon: NSImage.defaultInactiveIconImage
        )
    }()

    /// Returns a status item icon provider for custom active/inactive
    /// icon images from the application Documents directory.
    ///
    /// Returns `nil` if the required custom icon files do not exist.
    static let customProvider: StatusItemImageProvider? = {
        guard customIconImageFilesExist() else { return nil }
        return StatusItemImageProvider(
            activeIcon: NSImage.customActiveIconImage,
            inactiveIcon: NSImage.customInactiveIconImage
        )
    }()

    private init(activeIcon: NSImage, inactiveIcon: NSImage) {
        self.activeIconImage = activeIcon
        self.inactiveIconImage = inactiveIcon
    }
}