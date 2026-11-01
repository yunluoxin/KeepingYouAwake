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
    let mainMenuController = MainMenuController()
    var menu: NSMenu! {
        didSet {
            // Refresh the dynamic items (status line, toggle, activate)
            // each time the menu is about to be shown.
            menu.delegate = mainMenuController
        }
    }

    private var workspaceScheduledTimeInterval: TimeInterval = -1
    private var isBatteryOverrideEnabled = false

    /// The persistent master switch. When false the app is fully inert:
    /// no sleep wake timer and no process/display/battery monitoring.
    /// Backed by UserDefaults so a real "off" survives relaunch.
    private var isEnabled: Bool {
        get { UserDefaults.standard.kya_enabled }
        set { UserDefaults.standard.kya_enabled = newValue }
    }

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

        mainMenuController.isEnabled = { [weak self] in self?.isEnabled ?? true }
        mainMenuController.isActive = { [weak self] in self?.sleepWakeTimer.isScheduled ?? false }
        mainMenuController.activationReason = { [weak self] in self?.currentActivationReason() }
    }

    /// A short human-readable reason describing why sleep is currently being
    /// prevented, derived from the highest-priority active trigger.
    private func currentActivationReason() -> String? {
        let device = Device.current
        let defaults = UserDefaults.standard

        if defaults.kya_processMonitoringEnabled,
           device.isProcessMonitoringEnabled,
           let processName = firstRunningTrackedProcessName() {
            return processName
        }
        if defaults.kya_activateOnExternalDisplayConnectedEnabled,
           DisplayParameters.numberOfExternalDisplays() > 0 {
            return NSLocalizedString("External Display", tableName: "Localizable", bundle: .main, value: "External Display", comment: "External Display")
        }
        return nil
    }

    // MARK: - Status Item

    private func configureStatusItemController() {
        statusItemController.dataSource = self
        statusItemController.delegate = self
    }

    // MARK: - Sleep Wake Timer

    private func configureSleepWakeTimer() {
        sleepWakeTimer.onActivate = { [weak self] _ in
            self?.enableDevicePowerMonitoring()
            // schedule() fires onActivate BEFORE the power assertion is
            // created, so isScheduled is still false here. Set the icon
            // directly instead of deriving it from isScheduled.
            self?.setAppearance(active: true)
        }
        sleepWakeTimer.onDeactivate = { [weak self] in
            self?.disableDevicePowerMonitoring()
            // The power assertion is already released here, so isScheduled is
            // false and derivation is safe.
            self?.updateAppearance()
        }
    }

    /// Sets the icon for a known activation change, honoring the master switch.
    private func setAppearance(active: Bool) {
        if !isEnabled {
            statusItemController.appearance = .disabled
        } else {
            statusItemController.appearance = active ? .active : .inactive
        }
    }

    /// Derives the status item appearance from the two orthogonal states:
    /// the master switch (isEnabled) and the current activation state
    /// (sleepWakeTimer.isScheduled). The icon never holds state of its own.
    private func updateAppearance() {
        if !isEnabled {
            statusItemController.appearance = .disabled
        } else if sleepWakeTimer.isScheduled {
            statusItemController.appearance = .active
        } else {
            statusItemController.appearance = .inactive
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
            self?.setEnabled(false)
        }

        eventHandler.registerAction(name: "toggle") { [weak self] _ in
            self?.handlePrimaryAction()
        }
    }

    /// Sets the persistent master switch and applies its side effects.
    /// OFF: stop the timer and tear down every monitor (fully inert).
    /// ON:  restore monitoring and let activation conditions take priority.
    private func setEnabled(_ enabled: Bool) {
        isEnabled = enabled
        if enabled {
            enableAllMonitoring()
            evaluateConditionsAndActivate()
        } else {
            terminateTimer()
            disableAllMonitoring()
        }
        updateAppearance()
    }

    private func handleActivateAction(_ event: Event) {
        let parameters = event.arguments ?? [:]

        if parameters.isEmpty {
            // Master switch ON, then let conditions drive activation.
            setEnabled(true)
        } else if let seconds = parameters["seconds"] {
            isEnabled = true
            terminateTimer()
            activateTimerWithTimeInterval(ceil(Double(seconds) ?? 0))
            updateAppearance()
        } else if let minutes = parameters["minutes"] {
            isEnabled = true
            terminateTimer()
            activateTimerWithTimeInterval(ceil(Double(minutes) ?? 0) * 60)
            updateAppearance()
        } else if let hours = parameters["hours"] {
            isEnabled = true
            terminateTimer()
            activateTimerWithTimeInterval(ceil(Double(hours) ?? 0) * 3600)
            updateAppearance()
        } else {
            updateAppearance()
        }
    }

    /// Left-click on the status item: toggle the persistent master switch.
    /// This is the single, unambiguous "real off" / "real on" control.
    private func handlePrimaryAction() {
        setEnabled(!isEnabled)
    }

    /// Public entry point for the menu's Disable/Enable item.
    func toggleMasterSwitch() {
        setEnabled(!isEnabled)
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

    private func enableAllMonitoring() {
        let device = Device.current
        let defaults = UserDefaults.standard

        // Process monitoring
        if defaults.kya_processMonitoringEnabled {
            let names = parseProcessNames()
            if !names.isEmpty {
                device.processMonitor.trackedProcessNames = names
                device.processMonitoringEnabled = true
            }
        }

        enableDevicePowerMonitoring()
    }

    private func disableAllMonitoring() {
        disableDevicePowerMonitoring()
        Device.current.processMonitoringEnabled = false
    }

    private func evaluateConditionsAndActivate() {
        if anyActivationConditionMet() {
            activateTimerWithTimeInterval(indefiniteTimeInterval)
        } else {
            activateTimer()
        }
    }

    /// Returns whether any auto-activation condition is currently met.
    private func anyActivationConditionMet() -> Bool {
        let defaults = UserDefaults.standard
        let device = Device.current

        // Process monitoring condition
        if defaults.kya_processMonitoringEnabled && device.isProcessMonitoringEnabled {
            if !device.processMonitor.currentlyRunningProcessPaths.isEmpty {
                return true
            }
        }

        // External display condition
        if defaults.kya_activateOnExternalDisplayConnectedEnabled {
            if DisplayParameters.numberOfExternalDisplays() > 0 {
                return true
            }
        }

        return false
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

        // If process monitoring was enabled previously, start tracking.
        // Skip entirely when the master switch is off so launch stays inert.
        if isEnabled, UserDefaults.standard.kya_processMonitoringEnabled {
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

        // Evaluate activation conditions after all monitoring is configured
        handlePostConfigurationActivation()
    }

    /// Evaluates whether to activate the timer after launch based on current conditions.
    /// Priority: process monitoring > external display > Activate on Launch preference.
    private func handlePostConfigurationActivation() {
        // Master switch off: the app stays fully inert on launch.
        guard isEnabled else {
            updateAppearance()
            return
        }

        let defaults = UserDefaults.standard
        let device = Device.current

        // If process monitoring is enabled, let it drive activation
        if defaults.kya_processMonitoringEnabled && device.isProcessMonitoringEnabled {
            let runningProcesses = device.processMonitor.currentlyRunningProcessPaths
            if !runningProcesses.isEmpty {
                NSLog("[AppController] Activating on launch due to running processes")
                activateTimerWithTimeInterval(indefiniteTimeInterval)
            }
            // If no processes are running, wait for process monitoring callback
            return
        }

        // Check external display condition
        if defaults.kya_activateOnExternalDisplayConnectedEnabled {
            let externalDisplays = DisplayParameters.numberOfExternalDisplays()
            if externalDisplays > 0 {
                NSLog("[AppController] Activating on launch due to external display")
                activateTimerWithTimeInterval(indefiniteTimeInterval)
                return
            }
        }

        // Fall back to Activate on Launch preference
        if defaults.kya_activateOnLaunch {
            NSLog("[AppController] Activating on launch per user preference")
            activateTimer()
        }
    }

    private func parseProcessNames() -> Set<String> {
        guard let namesString = UserDefaults.standard.kya_processNames else { return [] }
        let names = namesString
            .components(separatedBy: CharacterSet(charactersIn: ",\n"))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        return Set(names)
    }

    /// Returns the display name of the first tracked running process, used as
    /// the human-readable reason for the status menu (e.g. "caffeinate").
    /// Prefers the user's configured listener name when it matches; otherwise
    /// falls back to the executable's last path component.
    private func firstRunningTrackedProcessName() -> String? {
        let paths = Device.current.processMonitor.currentlyRunningProcessPaths
        guard let path = paths.first else { return nil }

        let configuredNames = parseProcessNames()
        let components = path.split(separator: "/").map { String($0) }
        if let exactMatch = configuredNames.first(where: { components.contains($0) }) {
            return exactMatch
        }
        return components.last
    }

    private func handleProcessMonitoringPreferenceChange() {
        // The master switch overrides the process-monitoring preference.
        guard isEnabled else {
            Device.current.processMonitoringEnabled = false
            return
        }
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
        guard isEnabled else { return }
        let device = Device.current
        let hasRunningProcesses = !device.processMonitor.currentlyRunningProcessPaths.isEmpty

        if hasRunningProcesses {
            if !sleepWakeTimer.isScheduled {
                NSLog("[AppController] Process monitoring: activating timer indefinitely")
                enableAllMonitoring()
                activateTimerWithTimeInterval(indefiniteTimeInterval)
            } else if sleepWakeTimer.scheduledTimeInterval > 0 {
                // A finite timer is running; conditions take priority → switch to indefinite
                NSLog("[AppController] Process monitoring: overriding finite timer with indefinite")
                terminateTimer()
                activateTimerWithTimeInterval(indefiniteTimeInterval)
            }
        } else {
            if sleepWakeTimer.isScheduled && !anyActivationConditionMet() {
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
        guard isEnabled else { return }
        guard UserDefaults.standard.kya_activateOnExternalDisplayConnectedEnabled else { return }
        let externalDisplays = DisplayParameters.numberOfExternalDisplays()

        if externalDisplays == 0 {
            if sleepWakeTimer.isScheduled && !anyActivationConditionMet() {
                terminateTimer()
            }
        } else {
            if !sleepWakeTimer.isScheduled {
                enableAllMonitoring()
                activateTimerWithTimeInterval(indefiniteTimeInterval)
            } else if sleepWakeTimer.scheduledTimeInterval > 0 {
                // A finite timer is running; conditions take priority → switch to indefinite
                NSLog("[AppController] External display: overriding finite timer with indefinite")
                terminateTimer()
                activateTimerWithTimeInterval(indefiniteTimeInterval)
            }
        }
    }

    private func handleWorkspaceSessionDidBecomeActive() {
        guard isEnabled else { return }
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
        // Choosing an explicit duration is an intent to be active: turn the
        // master switch on and activate, letting conditions keep priority.
        isEnabled = true
        terminateTimer()
        enableAllMonitoring()
        DispatchQueue.main.async { [weak self] in
            self?.activateTimerWithTimeInterval(duration.seconds)
            self?.updateAppearance()
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