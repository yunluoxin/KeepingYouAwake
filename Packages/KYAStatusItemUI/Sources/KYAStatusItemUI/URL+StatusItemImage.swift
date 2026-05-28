//
//  URL+StatusItemImage.swift
//  KYAStatusItemUI
//
//  Created by Marcel Dierkes on 30.04.22.
//

import AppKit
import Foundation

extension URL {
    /// The user's Documents directory URL.
    static var documentsDirectoryURL: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last!
    }

    /// Constructs an icon image file URL from an image name with optional @2x retina suffix.
    ///
    /// - Parameters:
    ///   - imageName: The base image name (e.g. "ActiveIcon").
    ///   - isRetinaIcon: Whether to append the @2x suffix.
    /// - Returns: A file URL in the Documents directory pointing to the PNG file.
    static func iconImageFileURL(withName imageName: String, isRetinaIcon: Bool) -> URL {
        precondition(!imageName.isEmpty, "imageName must not be empty")
        let suffix = isRetinaIcon ? "@2x" : ""
        let composedName = "\(imageName)\(suffix).png"
        return documentsDirectoryURL.appendingPathComponent(composedName)
    }
}

/// Checks whether a custom icon image file exists in the Documents directory.
///
/// - Parameters:
///   - imageName: The base image name to look for.
///   - isRetinaIcon: Whether to check the @2x variant.
/// - Returns: `true` if the file exists at the expected path.
func customIconImageFileExists(_ imageName: String, isRetinaIcon: Bool) -> Bool {
    precondition(!imageName.isEmpty, "imageName must not be empty")
    let fileURL = URL.iconImageFileURL(withName: imageName, isRetinaIcon: isRetinaIcon)
    return FileManager.default.fileExists(atPath: fileURL.path)
}

/// Checks whether all four custom icon image files (standard + @2x for active and inactive) exist.
func customIconImageFilesExist() -> Bool {
    let activeName = NSImage.defaultActiveIconImageName
    let inactiveName = NSImage.defaultInactiveIconImageName
    return customIconImageFileExists(activeName, isRetinaIcon: false)
        && customIconImageFileExists(activeName, isRetinaIcon: true)
        && customIconImageFileExists(inactiveName, isRetinaIcon: false)
        && customIconImageFileExists(inactiveName, isRetinaIcon: true)
}