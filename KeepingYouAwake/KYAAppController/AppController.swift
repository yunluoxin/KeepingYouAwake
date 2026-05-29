//
//  AppController.swift
//  KeepingYouAwake
//
//  Created by Marcel Dierkes on 17.10.14.
//  Rewritten in Swift from KYAAppController.m.
//

import AppKit
import KYASleepWakeTimer
import KYADeviceInfo
import KYAApplicationEvents
import KYAApplicationSupport
import KYAStatusItemUI
import KYACommon
import KYAActivationDurations
import KYAUserNotifications

/// Central orchestrator: connects sleep/wake timer, status item,
/// device monitors, and event handler together.
final class AppController {
    let sleepWakeTimer = SleepWakeTimer()
    let statusItemController = StatusItemController()
    let menuController = ActivationDurationsMenuController()
    var menu: NSMenu!

    private var workspaceScheduledTimeInterval: TimeInterval = -1
    private var isBatteryOverrideEnabled = false

    // Notification observers
    private var observers: [NSObjectProtocol] = []
    private var workspaceObservers: [NSObjectProtocol] = []

    init() {
        configureStatusItemController()
        configureSleepWakeTimer()
        configureEventHandler()
        configureUserNotificationCenter()
        configureMainMenu()
        configureProcessMonitoring()
        registerNotifications()
    }

    deinit {
        let center = NotificationCenter.default
        for observer in observers {
            center.removeObserver(observer)
        }
        for observer in workspaceObservers {
            NSWorkspace.shared.notificationCenter.removeObserver(observer)
        }
    }

    // MARK: - Main Menu

    private func configureMainMenu() {
        menuController.onSelectDuration = { [weak self] duration in
            self?.handleDurationSelection(duration)
        }
        menuController.onGetFireDate = { [weak self] _ in
            self?.sleepWakeTimer.fireDate
        }
        menuController.onGetCurrentDuration = { [weak self] _ in
            guard let self, self.sleepWakeTimer.isScheduled else { return nil }
            return ActivationDuration(seconds: self.sleepWakeTimer.scheduledTimeInterval)
        }
    }

    // MARK: - Status Item

    private func configureStatusItemController() {
        statusItemController.dataSource = self
        statusItemController.delegate = self
    }

    // MARK: - Sleep Wake Timer

    private func configureSleepWakeTimer() {
        sleepWakeTimer.onActivate = { [weak self] _ in
            self?.statusItemController.appearance = .active
            self?.enableDevicePowerMonitoring()
        }
        sleepWakeTimer.onDeactivate = { [weak self] in
            self?.statusItemController.appearance = .inactive
            self?.disableDevicePowerMonitoring()
        }

        if UserDefaults.standard.kya_activateOnLaunch {
            activateTimer()
        }
    }

    private func activateTimer() {
        activateTimerWithTimeInterval(UserDefaults.standard.kya_defaultTimeInterval)
    }

    private func activateTimerWithTimeInterval(_ timeInterval: TimeInterval) {
        guard timeInterval >= 0 else { return }

        let defaults = UserDefaults.standard

        sleepWakeTimer.schedule(timeInterval: timeInterval) { [weak self] cancelled in
            // Post deactivation notification
            if #available(macOS 11.0, *) {
                let notification = ActivationUserNotification(fireDate: nil, activating: false)
                UserNotificationCenter.sharedCenter.postNotification(notification)
            }

            // Quit on timer expiration
            if !cancelled && defaults.kya_quitOnTimerExpirationEnabled {
                NSApplication.shared.terminate(nil)
            }
        }

        // Post activation notification
        if #available(macOS 11.0, *) {
            let notification = ActivationUserNotification(
                fireDate: sleepWakeTimer.fireDate,
                activating: true
            )
            UserNotificationCenter.sharedCenter.postNotification(notification)
        }
    }

    func terminateTimer() {
        disableBatteryOverride()
        if sleepWakeTimer.isScheduled {
            sleepWakeTimer.invalidate()
        }
    }

    // MARK: - Event Handling

    private func configureEventHandler() {
        let eventHandler = EventHandler.defaultHandler

        eventHandler.registerAction(name: "activate") { [weak self] event in
            self?.handleActivateAction(event)
        }

        eventHandler.registerAction(name: "deactivate") { [weak self] _ in
            self?.terminateTimer()
            self?.statusItemController.appearance = .inactive
        }

        eventHandler.registerAction(name: "toggle") { [weak self] _ in
            self?.handlePrimaryAction()
        }
    }

    private func handleActivateAction(_ event: Event) {
        let parameters = event.arguments ?? [:]
        terminateTimer()

        if parameters.isEmpty {
            activateTimer()
            statusItemController.appearance = .active
        } else if let seconds = parameters["seconds"] {
            activateTimerWithTimeInterval(ceil(Double(seconds) ?? 0))
            statusItemController.appearance = .active
        } else if let minutes = parameters["minutes"] {
            activateTimerWithTimeInterval(ceil(Double(minutes) ?? 0) * 60)
            statusItemController.appearance = .active
        } else if let hours = parameters["hours"] {
            activateTimerWithTimeInterval(ceil(Double(hours) ?? 0) * 3600)
            statusItemController.appearance = .active
        } else {
            statusItemController.appearance = .inactive
        }
    }

    private func handlePrimaryAction() {
        if sleepWakeTimer.isScheduled {
            terminateTimer()
        } else {
            activateTimer()
        }
    }

    // MARK: - User Notification Center

    private func configureUserNotificationCenter() {
        if #available(macOS 11.0, *) {
            let center = UserNotificationCenter.sharedCenter
            center.requestAuthorizationIfUndetermined()
            center.clearAllDeliveredNotifications()
        }
    }

    // MARK: - Device Power Monitoring

    private func checkAndEnableBatteryOverride() {
        let batteryMonitor = Device.current.batteryMonitor
        let currentCapacity = batteryMonitor.currentCapacity
        let threshold = UserDefaults.standard.kya_batteryCapacityThreshold
        isBatteryOverrideEnabled = currentCapacity <= threshold
    }

    private func disableBatteryOverride() {
        isBatteryOverrideEnabled = false
    }

    private func enableDevicePowerMonitoring() {
        let device = Device.current
        let defaults = UserDefaults.standard

        checkAndEnableBatteryOverride()

        device.onChange = { [weak self] parameter in
            self?.handleDeviceParameterChange(parameter)
        }

        if defaults.kya_batteryCapacityThresholdEnabled {
            device.batteryMonitoringEnabled = true
        }
        if defaults.kya_lowPowerModeMonitoringEnabled {
            device.lowPowerModeMonitoringEnabled = true
        }
    }

    private func disableDevicePowerMonitoring() {
        let device = Device.current
        device.onChange = nil
        device.batteryMonitoringEnabled = false
        device.lowPowerModeMonitoringEnabled = false
    }

    private func handleDeviceParameterChange(_ parameter: DeviceParameter) {
        let defaults = UserDefaults.standard

        switch parameter {
        case .batteryCapacity:
            guard defaults.kya_batteryCapacityThresholdEnabled else { return }
            let threshold = defaults.kya_batteryCapacityThreshold
            let capacity = Device.current.batteryMonitor.currentCapacity
            if sleepWakeTimer.isScheduled && capacity <= threshold && !isBatteryOverrideEnabled {
                terminateTimer()
            }
        case .lowPowerMode:
            guard defaults.kya_lowPowerModeMonitoringEnabled else { return }
            if Device.current.lowPowerModeMonitor.isLowPowerModeEnabled && sleepWakeTimer.isScheduled {
                terminateTimer()
            }
        @unknown default:
            break
        }
    }

    // MARK: - Process Monitoring

    private func configureProcessMonitoring() {
        let device = Device.current

        // Wire the callback that fires when tracked processes start/exit
        device.onProcessMonitoringChange = { [weak self] in
            self?.handleProcessMonitoringChange()
        }

        // If process monitoring was enabled previously, start tracking
        if UserDefaults.standard.kya_processMonitoringEnabled {
            let names = parseProcessNames()
            if !names.isEmpty {
                device.processMonitor.trackedProcessNames = names
                device.processMonitoringEnabled = true
            }
        }

        // Observe UserDefaults changes for the process monitoring toggle
        let center = NotificationCenter.default
        observers.append(center.addObserver(
            forName: UserDefaults.didChangeNotification,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                self?.handleProcessMonitoringPreferenceChange()
            }
        ))
    }

    private func parseProcessNames() -> Set<String> {
        guard let namesString = UserDefaults.standard.kya_processNames else { return [] }
        let names = namesString
            .components(separatedBy: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Set(names)
    }

    private func handleProcessMonitoringPreferenceChange() {
        let defaults = UserDefaults.standard
        let device = Device.current

        let isEnabled = defaults.kya_processMonitoringEnabled
        if isEnabled {
            let names = parseProcessNames()
            guard !names.isEmpty else {
                // If monitoring is enabled but no names are set, disable it
                device.processMonitoringEnabled = false
                return
            }
            device.processMonitor.trackedProcessNames = names
            device.processMonitoringEnabled = true
        } else {
            // Unregister monitoring without changing timer state
            device.processMonitoringEnabled = false
        }
    }

    /// Called when tracked processes start or exit.
    /// Activates the timer when any tracked process is running;
    /// deactivates when all tracked processes have exited.
    private func handleProcessMonitoringChange() {
        let device = Device.current
        let hasRunningProcesses = !device.processMonitor.currentlyRunningProcessPaths.isEmpty

        if hasRunningProcesses {
            if !sleepWakeTimer.isScheduled {
                NSLog("[AppController] Process monitoring: activating timer")
                activateTimer()
            }
        } else {
            if sleepWakeTimer.isScheduled {
                NSLog("[AppController] Process monitoring: deactivating timer")
                terminateTimer()
            }
        }
    }

    // MARK: - Notifications

    private func registerNotifications() {
        let center = NotificationCenter.default

        observers.append(center.addObserver(
            forName: NSApplication.willFinishLaunchingNotification,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                EventHandler.defaultHandler.registerAsDefaultEventHandler()
            }
        ))

        observers.append(center.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                self?.handleScreenParametersChange()
            }
        ))

        observers.append(center.addObserver(
            forName: BatteryCapacityThreshold.didChangeNotification,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                if self?.sleepWakeTimer.isScheduled == true {
                    self?.terminateTimer()
                }
            }
        ))

        let workspaceCenter = NSWorkspace.shared.notificationCenter
        workspaceObservers.append(workspaceCenter.addObserver(
            forName: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                self?.handleWorkspaceSessionDidBecomeActive()
            }
        ))
        workspaceObservers.append(workspaceCenter.addObserver(
            forName: NSWorkspace.sessionDidResignActiveNotification,
            object: nil,
            queue: .main,
            using: { [weak self] _ in
                self?.handleWorkspaceSessionDidResignActive()
            }
        ))
    }

    private func handleScreenParametersChange() {
        guard UserDefaults.standard.kya_activateOnExternalDisplayConnectedEnabled else { return }
        let externalDisplays = DisplayParameters.numberOfExternalDisplays()

        if externalDisplays == 0 {
            if sleepWakeTimer.isScheduled { terminateTimer() }
        } else {
            if !sleepWakeTimer.isScheduled { activateTimer() }
        }
    }

    private func handleWorkspaceSessionDidBecomeActive() {
        let defaults = UserDefaults.standard
        if defaults.kya_deactivateOnUserSwitchEnabled && workspaceScheduledTimeInterval >= 0 {
            activateTimerWithTimeInterval(workspaceScheduledTimeInterval)
            workspaceScheduledTimeInterval = -1
        }
    }

    private func handleWorkspaceSessionDidResignActive() {
        let defaults = UserDefaults.standard
        if defaults.kya_deactivateOnUserSwitchEnabled && sleepWakeTimer.isScheduled {
            workspaceScheduledTimeInterval = sleepWakeTimer.scheduledTimeInterval
            terminateTimer()
        }
    }

    // MARK: - Duration Selection

    private func handleDurationSelection(_ duration: ActivationDuration) {
        terminateTimer()
        DispatchQueue.main.async { [weak self] in
            self?.activateTimerWithTimeInterval(duration.seconds)
        }
    }
}

// MARK: - StatusItemControllerDataSource

extension AppController: StatusItemControllerDataSource {
    func menuForStatusItemController(_ controller: StatusItemController) -> NSMenu? {
        menu
    }
}

// MARK: - StatusItemControllerDelegate

extension AppController: StatusItemControllerDelegate {
    func statusItemControllerShouldPerformPrimaryAction(_ controller: StatusItemController) {
        handlePrimaryAction()
    }
}