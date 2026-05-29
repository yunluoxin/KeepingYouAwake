//
//  NSImage+StatusItemImage.swift
//  KYAStatusItemUI
//
//  Created by Marcel Dierkes on 30.04.22.
//

import AppKit

extension NSImage {
    /// The asset catalog name for the built-in active icon.
    static let defaultActiveIconImageName: NSImage.Name = "ActiveIcon"

    /// The asset catalog name for the built-in inactive icon.
    static let defaultInactiveIconImageName: NSImage.Name = "InactiveIcon"

    /// Loads the default active icon image from the asset catalog.
    static var defaultActiveIconImage: NSImage {
        let image = NSImage(named: defaultActiveIconImageName)!
        image.isTemplate = true
        image.backgroundColor = .white
        return image
    }

    /// Loads the default inactive icon image from the asset catalog.
    static var defaultInactiveIconImage: NSImage {
        let image = NSImage(named: defaultInactiveIconImageName)!
        image.isTemplate = true
        return image
    }

    /// Loads a custom active icon image from the Documents directory,
    /// including the @2x retina representation if available.
    static var customActiveIconImage: NSImage {
        customIconNamed(defaultActiveIconImageName)
    }

    /// Loads a custom inactive icon image from the Documents directory,
    /// including the @2x retina representation if available.
    static var customInactiveIconImage: NSImage {
        customIconNamed(defaultInactiveIconImageName)
    }

    // MARK: - Private

    /// Loads a custom icon image by name from the Documents directory with retina support.
    private static func customIconNamed(_ imageName: NSImage.Name) -> NSImage {
        precondition(!imageName.isEmpty, "imageName must not be empty")

        let fileURL = URL.iconImageFileURL(withName: imageName, isRetinaIcon: false)
        guard let image = NSImage(contentsOf: fileURL) else {
            preconditionFailure("Could not load custom icon image at \(fileURL.path)")
        }
        image.isTemplate = true

        // Load and add the @2x retina representation if available.
        let retinaFileURL = URL.iconImageFileURL(withName: imageName, isRetinaIcon: true)
        if let retinaRep = NSImageRep(contentsOf: retinaFileURL) {
            image.addRepresentation(retinaRep)
        }

        return image
    }
}
