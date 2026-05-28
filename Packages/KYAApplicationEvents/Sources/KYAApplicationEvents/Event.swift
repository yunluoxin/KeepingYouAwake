//
//  Event.swift
//  KYAApplicationEvents
//
//  Created by Marcel Dierkes on 01.04.15.
//  Copyright (c) 2015 Marcel Dierkes. All rights reserved.
//

/// Represents an event from a callback URL.
struct Event: Equatable, Hashable, CustomStringConvertible {
    /// The event name.
    let name: String

    /// Additional arguments from the callback URL.
    let arguments: [String: String]?

    var description: String {
        "Event { name: \(name), arguments: \(arguments ?? [:]) }"
    }
}