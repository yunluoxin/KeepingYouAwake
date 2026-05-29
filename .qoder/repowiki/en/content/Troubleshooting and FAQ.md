# Troubleshooting and FAQ

<cite>
**Referenced Files in This Document**
- [README.md](file://README.md)
- [AppMain.swift](file://KeepingYouAwake/AppMain.swift)
- [AppDelegate.swift](file://KYALauncher/AppDelegate.swift)
- [AppController.swift](file://KeepingYouAwake/KYAAppController/AppController.swift)
- [ActivationUserNotification.swift](file://KeepingYouAwake/KYAActivationUserNotification/ActivationUserNotification.swift)
- [BatterySettingsViewController.swift](file://KeepingYouAwake/Settings/KYABatterySettingsViewController/BatterySettingsViewController.swift)
- [v1.6.7beta1.md](file://docs/Versions/v1.6.7beta1.md)
- [2026-05-28-swift-appkit-rewrite-design.md](file://docs/superpowers/specs/2026-05-28-swift-appkit-rewrite-design.md)
- [AppUpdater.swift](file://KeepingYouAwake/KYAAppUpdater/AppUpdater.swift)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Installation Troubleshooting](#installation-troubleshooting)
3. [Runtime Errors and Behavior](#runtime-errors-and-behavior)
4. [Performance Issues](#performance-issues)
5. [Debugging Techniques](#debugging-techniques)
6. [Scenario-Specific Solutions](#scenario-specific-solutions)
7. [Frequently Asked Questions](#frequently-asked-questions)
8. [Conclusion](#conclusion)

## Introduction
This guide helps diagnose and resolve common issues with KeepingYouAwake on macOS. It covers installation problems, runtime behavior, performance, and debugging techniques. It also provides targeted solutions for MacBook closed-lid limitations, external display connectivity, and power management conflicts.

## Installation Troubleshooting
This section focuses on installation and initial setup issues users commonly encounter.

- Symptom: App does not appear in Applications folder or fails to open after download.
  - Verify the app is downloaded from the official release page referenced in the project’s README.
  - If downloaded from a third-party source, ensure the archive is not corrupted and the app is not blocked by macOS Gatekeeper.
  - To unblock, right-click the app and choose Open, or temporarily allow apps from “App Store and identified developers” in Security & Privacy preferences.
  - If the app opens but immediately quits, confirm your macOS version meets the minimum requirement noted in the README.

- Symptom: Permission errors when launching or enabling features.
  - Some macOS versions require explicit permission for menu bar agents and background activity. Reopen the app from Finder and approve any prompts.
  - If the app relies on external update feeds, ensure network access is permitted.

- Symptom: Compatibility issues with older macOS versions.
  - The README documents that version 1.6.2 is the last to support macOS Sierra (10.12), and version 1.5.2 supports macOS Yosemite (10.10) and El Capitan (10.11).
  - If you rely on older systems, use the appropriate legacy release.

- Symptom: Launch at login or background behavior not working.
  - The launcher app opens the main app and terminates itself. If the main app does not stay active, verify the system allows accessory applications to run in the background.

**Section sources**
- [README.md:1-45](file://README.md#L1-L45)
- [AppMain.swift:11-23](file://KeepingYouAwake/AppMain.swift#L11-L23)
- [AppDelegate.swift:13-25](file://KYALauncher/AppDelegate.swift#L13-L25)

## Runtime Errors and Behavior
This section explains common runtime behaviors and how to address them.

- Symptom: Sleep prevention does not take effect.
  - Confirm the app is active in the menu bar and the timer is scheduled. The central controller schedules the sleep-wake timer and updates the status item appearance accordingly.
  - If the app is already active, toggling the primary action will terminate the timer. Use the menu durations to re-activate.

- Symptom: Notifications not delivered or delayed.
  - Activation/deactivation notifications are posted conditionally on supported macOS versions. If notifications are not visible, ensure notification permissions are granted in System Settings > Notifications for the app.
  - The activation notification displays localized titles and bodies indicating whether sleep is being prevented indefinitely or until a specific time.

- Symptom: Battery monitoring unexpectedly disables sleep prevention.
  - When battery capacity drops below the configured threshold, the controller disables the timer automatically. Adjust the threshold in Settings > Battery to a higher value if needed.
  - Low Power Mode detection can also cause automatic deactivation when enabled on supported Macs.

- Symptom: External display connectivity not triggering activation.
  - A previous bug caused duplicate caffeinate tasks when an external display was connected. This was fixed in a beta release. Ensure you are using a recent version that includes the fix.
  - Mirrored displays are now treated as external displays internally, resolving earlier mirroring-related issues.

- Symptom: Menu bar icon not updating after URL scheme activation.
  - A bug where the menu bar icon did not reflect activation/deactivation via URL scheme was resolved in a beta release. Update to the latest version.

- Symptom: App quits unexpectedly after timer expiration.
  - If the quit-on-expiration setting is enabled, the app terminates automatically when the scheduled time elapses. Disable this setting in General settings if you want the app to remain running.

**Section sources**
- [AppController.swift:77-122](file://KeepingYouAwake/KYAAppController/AppController.swift#L77-L122)
- [AppController.swift:181-187](file://KeepingYouAwake/KYAAppController/AppController.swift#L181-L187)
- [AppController.swift:227-246](file://KeepingYouAwake/KYAAppController/AppController.swift#L227-L246)
- [ActivationUserNotification.swift:12-38](file://KeepingYouAwake/KYAActivationUserNotification/ActivationUserNotification.swift#L12-L38)
- [BatterySettingsViewController.swift:42-120](file://KeepingYouAwake/Settings/KYABatterySettingsViewController/BatterySettingsViewController.swift#L42-L120)
- [v1.6.7beta1.md:1-18](file://docs/Versions/v1.6.7beta1.md#L1-L18)

## Performance Issues
This section addresses performance-related concerns and optimization tips.

- CPU usage spikes during activation:
  - The controller enables power monitoring when activation starts and disables it on deactivation. If you notice elevated CPU usage, ensure the app is not continuously toggling activation/deactivation.
  - Reduce unnecessary background monitoring by disabling battery or Low Power Mode monitoring in Settings > Battery if you do not need automatic deactivation triggers.

- Memory management:
  - The controller removes observers and clears references in deinitialization. If you observe memory growth over time, restart the app to reset internal state.
  - Avoid keeping multiple timers active simultaneously; use the menu durations to schedule a single activation period.

- System resource conflicts:
  - Multiple caffeinate tasks can conflict. The external display fix prevents spawning multiple tasks when a display is connected. Keep the app updated to benefit from such fixes.
  - When Low Power Mode is enabled, the app automatically deactivates to conserve energy. This is expected behavior.

- Background activity and menu bar agent:
  - As an accessory app, the system may throttle background activity. If you experience delays, reopen the app from Finder to refresh its state.

**Section sources**
- [AppController.swift:43-51](file://KeepingYouAwake/KYAAppController/AppController.swift#L43-L51)
- [AppController.swift:202-225](file://KeepingYouAwake/KYAAppController/AppController.swift#L202-L225)
- [v1.6.7beta1.md:1-18](file://docs/Versions/v1.6.7beta1.md#L1-L18)

## Debugging Techniques
Use these techniques to investigate issues and gather diagnostic information.

- Console logs:
  - The project uses a unified logging system with categories and a global enable/disable switch. Logging can be toggled at runtime for debugging and disabled in release builds.
  - Use Console.app to filter logs by the app’s subsystem to capture relevant entries during activation/deactivation and power events.

- System diagnostics:
  - Check battery capacity and Low Power Mode status in System Settings > Battery. If the app deactivates unexpectedly, verify these settings.
  - Monitor external display connections and mirroring behavior, as these can trigger automatic activation/deactivation.

- Performance profiling:
  - Use Activity Monitor to observe CPU usage and energy impact while the app is active.
  - Use Instruments (Time Profiler) to identify hotspots during activation and power-monitoring callbacks.

- Localization and UI feedback:
  - If UI strings appear incorrect, ensure the app’s localization resources are intact. The project maintains localized strings across multiple languages.

- Update channel verification:
  - If you rely on updates, verify the selected update feed (release vs. pre-release) and ensure network access is permitted.

**Section sources**
- [2026-05-28-swift-appkit-rewrite-design.md:102-114](file://docs/superpowers/specs/2026-05-28-swift-appkit-rewrite-design.md#L102-L114)
- [AppUpdater.swift:15-44](file://KeepingYouAwake/KYAAppUpdater/AppUpdater.swift#L15-L44)

## Scenario-Specific Solutions
Targeted fixes for specific situations.

- MacBook with closed lid limitations:
  - The README explicitly states that preventing sleep on a MacBook with a closed lid is not supported due to macOS thermal and power policies. Use the app on desktop Macs or on a MacBook with the lid open.

- External display connectivity issues:
  - Ensure the app is updated to a version that includes the external display fixes. The documented beta addressed duplicate caffeinate tasks and mirroring not being treated as external display.

- Power management conflicts:
  - If Low Power Mode is enabled, the app will automatically deactivate. Enable Low Power Mode monitoring in Settings > Battery to align behavior with system settings.
  - Set a higher battery capacity threshold if frequent deactivation occurs during light usage.

- URL scheme activation not reflected in menu bar:
  - Update to a version that resolves the menu bar icon update issue when using URL scheme activation.

**Section sources**
- [README.md:19-21](file://README.md#L19-L21)
- [v1.6.7beta1.md:1-18](file://docs/Versions/v1.6.7beta1.md#L1-L18)
- [BatterySettingsViewController.swift:94-120](file://KeepingYouAwake/Settings/KYABatterySettingsViewController/BatterySettingsViewController.swift#L94-L120)

## Frequently Asked Questions
Common questions and concise answers grounded in the codebase and documentation.

- Q: Why does the app not prevent sleep on my MacBook with the lid closed?
  - A: macOS intentionally restricts sleep prevention on portable Macs with closed lids for thermal and power reasons. Use the app on desktop Macs or with the lid open.

- Q: How does the app handle Low Power Mode?
  - A: When Low Power Mode is enabled, the app automatically deactivates to conserve energy. You can enable Low Power Mode monitoring in Settings > Battery to reactivate automatically when the mode ends.

- Q: What happens when battery capacity falls below the threshold?
  - A: The app deactivates automatically to protect the battery. Adjust the threshold in Settings > Battery to a higher value if needed.

- Q: Why does the app quit after the timer expires?
  - A: If the quit-on-expiration setting is enabled, the app terminates automatically. Disable this option in General settings if you want the app to remain running.

- Q: Can I use the app on older macOS versions?
  - A: The README lists the last supported versions for legacy releases. Use the appropriate legacy version for macOS 10.10–10.12.

- Q: How do I enable notifications for activation/deactivation?
  - A: On supported macOS versions, the app requests notification permissions and posts activation/deactivation notifications. Ensure notifications are allowed in System Settings > Notifications.

- Q: How do I keep the app running in the background?
  - A: As an accessory app, macOS manages background activity. Reopen the app from Finder to refresh its state if it appears inactive.

**Section sources**
- [README.md:19-21](file://README.md#L19-L21)
- [AppController.swift:227-246](file://KeepingYouAwake/KYAAppController/AppController.swift#L227-L246)
- [BatterySettingsViewController.swift:42-120](file://KeepingYouAwake/Settings/KYABatterySettingsViewController/BatterySettingsViewController.swift#L42-L120)
- [README.md:31-35](file://README.md#L31-L35)
- [ActivationUserNotification.swift:12-38](file://KeepingYouAwake/KYAActivationUserNotification/ActivationUserNotification.swift#L12-L38)

## Conclusion
Most issues stem from macOS system-level constraints, power management, or outdated versions. Use the settings to align behavior with your environment, keep the app updated, and leverage logging and diagnostics to isolate problems. For MacBook closed-lid limitations and external display quirks, follow the scenario-specific solutions above.