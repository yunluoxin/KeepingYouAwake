//
//  EventHandler.swift
//  KYAApplicationEvents
//
//  Created by Marcel Dierkes on 31.03.15.
//  Copyright (c) 2015 Marcel Dierkes. All rights reserved.
//

import Foundation
import os
import KYACommon

/// Handles URL scheme events by dispatching registered action blocks.
final class EventHandler {
    /// Returns the default event handler singleton.
    static let defaultHandler = EventHandler()

    private let eventQueue = DispatchQueue(
        label: "info.marcel-dierkes.KeepingYouAwake.EventQueue"
    )
    private var actions: [String: (Event) -> Void] = [:]
    private let log: OSLog = KYALog.shared.log(for: "ApplicationEvents")

    /// Registers a block that will be executed when an event with
    /// the supplied name is handled.
    ///
    /// - Parameters:
    ///   - name: An action identifier
    ///   - block: A block executed when the event is handled
    func registerAction(name: String, block: @escaping (Event) -> Void) {
        actions[name] = block
    }

    /// Removes the registered action and block with the supplied name.
    ///
    /// - Parameter name: An action identifier
    func removeAction(name: String) {
        actions.removeValue(forKey: name)
    }

    /// Parses a callback URL and dispatches the matching registered action.
    ///
    /// The URL's last path component is used as the event name.
    /// Query items are collected as event arguments.
    ///
    /// - Parameter url: A callback URL
    func handleEvent(url: URL?) {
        guard let url else { return }

        eventQueue.async { [weak self] in
            guard let self else { return }

            let event = self.eventFromURL(url)
            guard let block = self.actions[event.name] else { return }

            KYALog.shared.debug("Handling event: \(event.description) for URL: \(url.absoluteString)")

            DispatchQueue.main.sync {
                block(event)
            }
        }
    }

    /// Parses a URL into an `Event`.
    private func eventFromURL(_ url: URL) -> Event {
        let name = url.lastPathComponent

        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let queryItems = components.queryItems, !queryItems.isEmpty
        else {
            return Event(name: name, arguments: nil)
        }

        var arguments: [String: String] = [:]
        for item in queryItems {
            arguments[item.name] = item.value ?? ""
        }

        return Event(name: name, arguments: arguments)
    }
}