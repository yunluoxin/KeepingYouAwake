//
//  EventHandler+DefaultEventHandler.swift
//  KYAApplicationEvents
//
//  Created by Marcel Dierkes on 09.05.22.
//

import AppKit
import ApplicationServices

extension EventHandler {
    /// Configures the event handler to be the default for the current
    /// application and prepares itself for handling incoming URL scheme events.
    func registerAsDefaultEventHandler() {
        NSAppleEventManager.shared().setEventHandler(
            self,
            andSelector: #selector(handleGetURLEvent(_:withReplyEvent:)),
            forEventClass: AEEventClass(kInternetEventClass),
            andEventID: AEEventID(kAEGetURL)
        )
    }

    @objc private func handleGetURLEvent(_ event: NSAppleEventDescriptor,
                                         withReplyEvent reply: NSAppleEventDescriptor) {
        let parameter = event.paramDescriptor(forKeyword: keyDirectObject)?.stringValue
        guard let urlString = parameter,
              let url = URL(string: urlString)
        else { return }

        handleEvent(url: url)
    }
}