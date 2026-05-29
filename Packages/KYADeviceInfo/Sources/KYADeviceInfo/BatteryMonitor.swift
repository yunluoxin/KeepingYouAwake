//
//  BatteryMonitor.swift
//  KYADeviceInfo
//
//  Created by Marcel Dierkes on 2026-05-28.
//  Rewritten from KYABatteryMonitor.m
//

import CoreFoundation
import Foundation
import IOKit.ps

/// Sentinel value indicating battery capacity is unavailable.
public let batteryCapacityUnavailable: CGFloat = -1.0

/// The battery state of the device.
public enum BatteryState: UInt {
    /// The battery state cannot be determined.
    case unknown = 0
    /// The device is not plugged into power; the battery is discharging.
    case unplugged
    /// The device is plugged into power and the battery is charging (< 100%).
    case charging
    /// The device is plugged into power and the battery is fully charged.
    case full
}

/// Monitors the status of the device's internal battery.
public final class BatteryMonitor: Monitor {
    /// Whether the current device has a built-in battery.
    public var hasBattery: Bool {
        guard let info = powerSourceInfo else { return false }
        let batteryType = info[kIOPSTypeKey as String] as? String
        return batteryType == kIOPSInternalBatteryType
    }

    /// The current battery charging level, or `batteryCapacityUnavailable`.
    public var currentCapacity: CGFloat {
        guard let info = powerSourceInfo else { return batteryCapacityUnavailable }
        let capacity = info[kIOPSCurrentCapacityKey as String] as? NSNumber
        guard let capacity else { return batteryCapacityUnavailable }
        return CGFloat(capacity.floatValue)
    }

    /// The current battery state.
    public var state: BatteryState {
        guard let info = powerSourceInfo else { return .unknown }
        let powerSourceState = info[kIOPSPowerSourceStateKey as String] as? String

        if powerSourceState == kIOPSBatteryPowerValue {
            return .unplugged
        } else if powerSourceState == kIOPSACPowerValue {
            let charging = info[kIOPSIsChargingKey as String] as? NSNumber
            if charging?.boolValue == true {
                return .charging
            }
            let charged = info[kIOPSIsChargedKey as String] as? NSNumber
            if charged?.boolValue == true {
                return .full
            }
        }
        return .unknown
    }

    // MARK: - Monitor Protocol

    /// Whether the battery monitor is registered for capacity change notifications.
    public var isRegistered: Bool {
        runLoopSource != nil
    }

    /// Registers for battery capacity change notifications.
    public func register() {
        guard runLoopSource == nil else { return }

        let context = Unmanaged.passUnretained(self).toOpaque()
        let source = IOPSNotificationCreateRunLoopSource(
            { context in
                guard let context else { return }
                let monitor = Unmanaged<BatteryMonitor>.fromOpaque(context).takeUnretainedValue()
                monitor.handleCapacityChange()
            },
            context
        ).takeRetainedValue()
        CFRunLoopAddSource(CFRunLoopGetCurrent(), source, .defaultMode)
        runLoopSource = source
    }

    /// Unregisters from battery capacity change notifications.
    public func unregister() {
        guard let source = runLoopSource else { return }
        CFRunLoopRemoveSource(CFRunLoopGetCurrent(), source, .defaultMode)
        runLoopSource = nil
    }

    /// Called when the power source changes. Invokes `onCapacityChange` on the main queue.
    public var onCapacityChange: ((CGFloat) -> Void)?

    // MARK: - Private

    private var runLoopSource: CFRunLoopSource?

    private func handleCapacityChange() {
        let capacity = currentCapacity
        guard let handler = onCapacityChange else { return }
        DispatchQueue.main.async {
            handler(capacity)
        }
    }

    /// Reads the first internal battery power source description from IOKit.
    /// The dictionary returned by IOPSGetPowerSourceDescription is tied to the
    /// blob's lifetime, so we copy it into an independent NSDictionary.
    private var powerSourceInfo: NSDictionary? {
        guard let blob = IOPSCopyPowerSourcesInfo() else { return nil }
        // blob is +1 from IOPSCopyPowerSourcesInfo; we'll release it ourselves.
        let blobRef = blob.takeRetainedValue()

        guard let sources = IOPSCopyPowerSourcesList(blobRef) else {
            return nil
        }
        let sourcesList = sources.takeRetainedValue() as CFArray

        guard CFArrayGetCount(sourcesList) > 0 else { return nil }

        let sourceID = (sourcesList as NSArray)[0] as AnyObject
        // IOPSGetPowerSourceDescription returns an unretained reference embedded
        // in the blob. Use takeUnretainedValue() and copy it so it survives
        // past the blob's lifetime.
        guard let desc = IOPSGetPowerSourceDescription(blobRef, sourceID) else {
            return nil
        }
        // IOPSGetPowerSourceDescription returns a reference inside the blob.
        // Use takeUnretainedValue() and copy to make it independent of blob lifetime.
        let result = NSDictionary(dictionary: desc.takeUnretainedValue() as! [AnyHashable: Any])
        return result
    }

    deinit {
        unregister()
    }
}