---
name: swift-appkit-rewrite
description: Full rewrite of KeepingYouAwake from Objective-C to pure Swift with AppKit (no SwiftUI), preserving macOS 10.13+ deployment target
type: project
---

# KeepingYouAwake Swift/AppKit Full Rewrite Design

## Overview

Rewrite the entire KeepingYouAwake macOS menu bar utility from Objective-C to **pure Swift** using **AppKit** (no SwiftUI). The app remains a menu bar agent (`LSUIElement = true`) that prevents Mac sleep by wrapping `/usr/bin/caffeinate`. All 8 SPM packages, the main app, and the launcher helper are rewritten entirely in Swift.

**Approach**: Layer-by-Layer, from foundation packages upward. No Obj-C interop needed since this is a full replacement in a separate worktree.

**Deployment target**: macOS 10.13+ (unchanged from current project). **Important**: This constrains API choices — `String(localized:)`, `os.Logger`, and `async/await` are unavailable at this deployment target. See API Availability section below.

**Swift version**: 5.9+ (matching current swift-tools-version in SPM packages).

**UI**: Programmatic AppKit — no XIBs, no Storyboards, no SwiftUI. All UI constructed in code using `NSStackView`, `NSGridView`, and Auto Layout constraints.

**Localization**: Keep `.xcstrings` format (preserving all 21 existing translations). Replace `KYA_L10N_*` macro system with `NSLocalizedString` wrapped in a Swift convenience namespace (`KYAL10n`). Note: `String(localized:)` requires macOS 13+ and cannot be used.

## API Availability Constraints (macOS 10.13+)

Several Swift APIs introduced in recent macOS versions are unavailable at the 10.13 deployment target. The rewrite must use backward-compatible alternatives:

| Modern Swift API | Min macOS | Backward-Compatible Replacement |
|---|---|---|
| `String(localized:key:table:)` | macOS 13 | `NSLocalizedString(_:, tableName:, bundle:, value:, comment:)` wrapped in a `KYAL10n` Swift namespace |
| `os.Logger(subsystem:, category:)` | macOS 11 | `os_log_create()` / `os_log_debug()` C functions via a Swift wrapper (available since macOS 10.12) |
| `async/await` concurrency | macOS 12 | Completion handlers / callback closures for 10.13-11; `@available(macOS 12, *)` async wrappers as convenience only |
| `@NSApplicationMain` (deprecated) | — | `@main` struct with `NSApplicationMain()` entry point (Swift 5.3+, works on all macOS) |
| `UNUserNotificationCenter` | macOS 11 | `@available(macOS 11, *)` gating with fallback to `NSUserNotificationCenter` (deprecated but available on 10.13-10.15) for older macOS |

**Core paths must work on macOS 10.13 without gating.** Where macOS 13+ APIs are used (`SMAppService`, `UNUserNotificationCenter`, etc.), provide a legacy fallback path using `@available(macOS 13, *)` checks, matching the existing pattern in `NSApplication+KYALaunchAtLogin`.

## Architecture Changes

### Communication Patterns

Replace Obj-C patterns with Swift-native alternatives:

| Obj-C Pattern | Swift Replacement | Scope |
|---|---|---|
| `NSNotificationCenter` posts (app-internal) | Callback closures | Cross-module change events |
| `NSNotificationCenter` posts (system) | Keep `NotificationCenter.default` | `NSProcessInfo.powerStateDidChangeNotification`, etc. |
| Delegates (custom protocols, not AppKit) | Closures | Feature-level communication |
| Delegates (AppKit protocols) | Keep delegates (`@objc` where needed) | `NSApplicationDelegate`, `NSMenuDelegate`, `NSWindowDelegate` |
| `KYA_L10N_*` macros | `KYAL10n` namespace wrapping `NSLocalizedString` | All UI strings |
| `Auto`/`AutoVar`/`AutoWeak` macros | Swift `let`/`var`/`weak var` type inference | All local variables |
| `KYA_EXPORT` macro | Swift `public` access modifier | All cross-module symbols |
| `KYALogCreateWithCategory()` | Swift wrapper around `os_log_create()`/`os_log_debug()` C functions | All logging |
| Internal package `*Log.h/.m` files | Eliminated — each package uses the `KYALog` Swift wrapper directly | All packages |

### Notification-to-Closure Mapping

Concrete replacement for each app-internal notification:

| Current Notification | Swift Replacement |
|---|---|
| `KYADeviceParameterDidChangeNotification` | `KYADevice.onChange` callback closure |
| `kKYABatteryCapacityThresholdDidChangeNotification` | `KYAAppController` directly calls battery settings VC callback, or `NotificationCenter.default` with a `Notification.Name` constant |
| `KYAActivationDurationsDidChangeNotification` | `KYAActivationDurationsController.onChangeDurations` callback closure |
| `NSProcessInfo.powerStateDidChangeNotification` | Keep `NotificationCenter.default` (system API) |
| System display change notifications | Keep `NotificationCenter.default` (system API) |

**Default rule**: Use closures for app-internal change events. Use `NotificationCenter.default` for system-provided notifications. Avoid `Combine` unless a specific subscriber needs reactive chaining (none of the current code does).

### Identifier Conventions

- **KYA prefix stays**: All classes, protocols, and constants use the `KYA` prefix (KeepingYouAwake), matching the existing convention.
- Swift naming conventions apply within the prefix (e.g., `KYASleepWakeTimer`, `KYABatteryMonitor`, not `KYA_sleepWakeTimer`).

### Delegate vs. Closure Rule

Use closures for all custom communication patterns. Keep delegates only where AppKit runtime requires them (`NSApplicationDelegate`, `NSMenuDelegate`, `NSWindowDelegate`, `NSStatusItem.button.target`). Specifically, `KYASleepWakeTimerDelegate` is replaced with closures (`onActivate`/`onDeactivate`) since it is not an AppKit protocol. No dual delegate+closure patterns — pick one and stick with it.

## Package Rewrite Order

Bottom-up, following dependency graph:

1. **KYACommon** (leaf, no deps)
2. **KYAApplicationSupport** (depends: KYACommon)
3. **KYADeviceInfo** (depends: KYACommon)
4. **KYAActivationDurations** (depends: KYACommon)
5. **KYAApplicationEvents** (depends: KYACommon)
6. **KYASleepWakeTimer** (depends: KYAApplicationSupport)
7. **KYAStatusItemUI** (depends: KYAApplicationSupport)
8. **KYAUserNotifications** (depends: KYACommon)
9. **Main App** (depends: all packages)
10. **KYALauncher** (standalone helper)

Each package is rewritten completely before moving to the next. Tests are rewritten alongside each package. Existing test coverage exists only for KYAActivationDurations, KYAApplicationSupport, and KYAApplicationEvents. New Swift test targets should be created for the remaining packages where testable logic exists (KYACommon, KYADeviceInfo, KYASleepWakeTimer, KYAStatusItemUI, KYAUserNotifications).

## Package Designs

### 1. KYACommon

**Current**: 4 headers + 1 .m (~64 lines). Contains `Auto`/`AutoVar`/`AutoWeak` macros, `KYA_EXPORT`, `KYALogCreateWithCategory`.

**Swift rewrite**: The macro system disappears entirely. Swift handles all of this natively:
- `Auto`/`AutoVar` → `let`/`var`
- `AutoWeak` → `weak var`
- `KYA_EXPORT` → Not needed (Swift module visibility is automatic with `public`)
- `KYALogCreateWithCategory()` → Swift wrapper around `os_log_create()` C function (available on macOS 10.12+, not the `os.Logger` struct which requires macOS 11+). Creates an `os_log_t` and provides convenience methods that call `os_log_debug()`, `os_log_info()`, `os_log_error()`.

**Result**: ~2 Swift files:
- `KYALog.swift` — convenience wrapper around C `os_log` functions with the app subsystem `"info.marcel-dierkes.KeepingYouAwake"`
- `KYACommon.swift` — any shared utility types/constants needed by other packages

The package becomes minimal. Other packages import `KYACommon` and use native Swift type inference + `KYALog` directly.

**Why**: Obj-C macros served to compensate for language limitations Swift doesn't have. Eliminating them simplifies every dependent package. Using C `os_log` functions (not `os.Logger`) preserves the macOS 10.13 deployment target. All internal `*Log.h/.m` files in other packages are eliminated — they just use the `KYALog` wrapper directly.

### 2. KYAApplicationSupport

**Current**: `NSUserDefaults+KYAKeys` (header + impl), `NSApplication+KYALaunchAtLogin` (header + impl), `NSBundle+KYAVersion` (header + impl), `KYADisplayParametersGetNumberOfExternalDisplays()` (header + impl), plus `KYAApplicationSupportLog.h/.m` and umbrella header.

**Swift rewrite**:
- `NSUserDefaults+KYAKeys` → `extension UserDefaults` with computed properties. Replace `KYA_GENERATE_BOOL_PROPERTY` macro with individual computed properties using `bool(forKey:)`/`set(_:forKey:)` pairs. The 12 `KYA_EXPORT NSString * const KYAUserDefaultsKey...` constants become `static let` constants in an enum namespace `KYAUserDefaultsKey` or are absorbed as string literals within each computed property.
- `NSApplication+KYALaunchAtLogin` → `extension NSApplication` using `ServiceManagement.SMAppService` via `@available(macOS 13, *)` checks, with legacy `SMLoginItemSetEnabled` fallback for older macOS (same pattern as existing Obj-C code).
- `NSBundle+KYAVersion` → `extension Bundle` with computed `versionString`, `buildNumber` properties.
- `KYADisplayParametersGetNumberOfExternalDisplays()` → Swift enum namespace `KYADisplayParameters` with static method `numberOfExternalDisplays` that calls `CGGetActiveDisplayList` (CoreGraphics C function) directly from Swift. This is a computed value (count of connected external displays with mirroring detection), not a persisted struct. Not `Codable`.
- `KYAApplicationSupportLog.h/.m` → Eliminated. Package uses `KYALog` from KYACommon directly.

**Result**: ~4-5 Swift files.

**Why**: Swift extensions and computed properties replace category methods and macros more cleanly. `KYADisplayParameters` is a C function that counts displays — it stays a function, not a struct.

### 3. KYADeviceInfo

**Current**: 12 files (headers + implementations, ~1,073 lines total). Contains `KYADevice`, `KYABatteryMonitor`, `KYALowPowerModeMonitor`, `KYAProcessMonitor` (all now organized in subdirectories with `+Private.h` headers).

**Swift rewrite**:
- **Common monitor pattern**: The three monitors (`Battery`, `LowPowerMode`, `Process`) share identical structure (register/unregister, handler callback, main-queue dispatch). In Swift, define a `KYAMonitor` protocol with `register()`, `unregister()`, and an `onChange` callback. Each monitor implements this protocol.
- `KYABatteryMonitor` → Swift class implementing `KYAMonitor`. Uses `NotificationCenter.default` for `NSProcessInfo.powerStateDidChangeNotification` (this is a system notification, keep it).
- `KYALowPowerModeMonitor` → Swift class implementing `KYAMonitor`. Same system notification pattern.
- `KYAProcessMonitor` → Swift class implementing `KYAMonitor`. Uses `Darwin.libproc` C interop (`proc_listallpids`, `proc_pidpath`) via Swift's C bridging or a small C shim. `DispatchSourceProcess` works directly in Swift. The three-layer hybrid model (polling → identification → exit detection) translates directly.
- `KYADevice` → Swift singleton with `currentDevice` static property. Manages all monitors. Replaces `KYADeviceParameterDidChangeNotification` with an `onChange` callback closure. `KYADeviceParameterProcess` constant and other parameter constants become Swift enum cases or `String` constants.

**KYAProcessMonitor C interop**: The `libproc.h` functions (`proc_listallpids`, `proc_pidpath`) are C functions available on Darwin. In Swift, they can be called directly after `import Darwin` (if Swift can auto-discover the declarations) or via a small C shim file (`libproc_shim.c` + `libproc_shim.h`) in the KYADeviceInfo package if needed. No Obj-C needed.

**Result**: ~5-6 Swift files for monitors + `KYADevice.swift` + `KYAMonitor.swift` protocol + optional C shim.

**Why**: The protocol consolidation eliminates boilerplate repetition across the three monitors, which is the most obvious benefit of Swift over Obj-C for this pattern.

### 4. KYAActivationDurations

**Current**: `KYAActivationDuration` (Obj-C++ with C++17 chrono, `.mm` file), `KYAActivationDurationsController`, `NSUserDefaults+KYADefaultTimeInterval`, plus `KYAActivationDurationsLog.h/.m`.

**Swift rewrite**:
- `KYAActivationDuration` **Obj-C++ → Pure Swift**: Replace C++ `chrono`/`calendar` arithmetic with `Foundation.Calendar` and `DateComponents`. The duration model becomes a Swift struct conforming to `Codable`, `Equatable`, `Comparable`. All time arithmetic uses `Calendar.date(byAdding:)` and `DateComponents`.
- `KYAActivationDurationsController` → Swift class managing the duration list, `UserDefaults` persistence, and change notifications. Replace `KYAActivationDurationsDidChangeNotification` with an `onChangeDurations` callback closure.
- `NSUserDefaults+KYADefaultTimeInterval` → Swift extension on `UserDefaults` with a computed property for the default time interval (absorbed into the `KYAApplicationSupport` UserDefaults extension, or kept within the `KYAActivationDurationsController`).
- `KYAActivationDurationsLog.h/.m` → Eliminated. Uses `KYALog` from KYACommon.

**Result**: Eliminates the `.mm` file, C++17 requirement, and all `*Log` boilerplate entirely. ~4 Swift files.

**Why**: C++ was used for its `chrono` library, which Swift/Foundation replaces completely. No reason to maintain Obj-C++ complexity.

### 5. KYAApplicationEvents

**Current**: `KYAEventHandler`, `KYAEvent` (model class with `name`/`arguments`, conforming to `NSCopying`), `KYAEventHandler+KYADefaultEventHandler` (category providing default URL scheme handler).

**Swift rewrite**:
- `KYAEventHandler` → Swift class handling `keepingyouawake://` URL scheme events. Parse URLs with `URLComponents` (far cleaner in Swift than `NSURL` dictionary-based parsing). Actions: `activate`, `deactivate`, `toggle` with duration parameters.
- `KYAEvent` → Swift struct with `name: String` and `arguments: [String: String]?` properties, conforming to `Equatable` and `Hashable` (replaces Obj-C `NSCopying` conformance).
- `KYAEventHandler+KYADefaultEventHandler` → Swift extension on `KYAEventHandler` providing the default URL scheme handler registration method.

**Result**: 3 Swift files. Much cleaner URL handling in Swift.

### 6. KYASleepWakeTimer

**Current**: 1 header + 1 .m (~163 lines). Contains `KYASleepWakeTimer` wrapping `/usr/bin/caffeinate`.

**Swift rewrite**:
- `KYASleepWakeTimer` → Swift class wrapping `Process` (Swift name for `NSTask`) to run `/usr/bin/caffeinate` with `-di`/`-i` flags.
- **Communication**: Replace `KYASleepWakeTimerDelegate` protocol with closures: `onActivate: (() -> Void)?` and `onDeactivate: (() -> Void)?`. No delegate protocol — closures only, consistent with the architecture rule.
- `KYASleepWakeTimeIntervalIndefinite` → Swift constant or sentinel value (e.g., `TimeInterval.infinity` or a special case).

**Result**: ~2 Swift files.

### 7. KYAStatusItemUI

**Current**: `KYAStatusItemController`, `KYAStatusItemImageProvider`, `KYAStatusItemControllerDataSource`/`Delegate` protocols, `NSImage+KYAStatusItemImage` (category), `NSURL+KYAStatusItemImage` (category), `KYAStatusItemImageProvider+Private.h`, `KYAStatusItemUILocalizedStrings.h`.

**Swift rewrite**:
- `KYAStatusItemController` → Swift class managing `NSStatusItem`. Programmatic menu construction — no XIB for the menu. `KYAStatusItemControllerDataSource` and `KYAStatusItemControllerDelegate` become Swift protocols. `@objc` annotation needed where `NSMenuDelegate` expects Obj-C messaging.
- `KYAStatusItemImageProvider` → Swift class providing active/inactive icon images. Supports custom icon loading from URLs (same feature).
- `NSImage+KYAStatusItemImage` → Swift extension on `NSImage` for status item rendering and template image preparation.
- `NSURL+KYAStatusItemImage` → Swift extension on `URL` for loading custom menu bar icons from file URLs.
- `KYAStatusItemUILocalizedStrings` → Eliminated. Replaced by `KYAL10n` namespace wrapping `NSLocalizedString`.

**Result**: ~5-6 Swift files. `@objc` annotations only where AppKit runtime requires them.

### 8. KYAUserNotifications

**Current**: `KYAUserNotificationCenter`, `KYAUserNotification` (base class), `NSDate+RemainingTime` (category), `NSURL+KYAUserNotificationCenter` (category), `NSWorkspace+KYAUserNotificationCenter` (category).

**Swift rewrite**:
- `KYAUserNotificationCenter` → Swift class using `UNUserNotificationCenter` via `@available(macOS 11, *)` gating, with `NSUserNotificationCenter` fallback for macOS 10.13-10.15. Permission requests use completion handlers (not async/await, which requires macOS 12+).
- `KYAUserNotification` → Swift class with `identifier`, `title`, `subtitle`, `bodyText`, `userInfo` properties and localized setter convenience methods. Subclassable (used by `KYAActivationUserNotification` in main app).
- `NSDate+RemainingTime` → Swift extension on `Date` with `localizedRemainingTime` and `localizedRemainingTimeWithoutPhrase` computed properties using `DateComponentsFormatter`.
- `NSURL+KYAUserNotificationCenter` → Swift extension on `URL` with static `notificationSettingsURL` property pointing to System Settings pane.
- `NSWorkspace+KYAUserNotificationCenter` → Swift extension on `NSWorkspace` with `openNotificationSettings(completion:)` method for opening System Settings.

**Result**: ~5-6 Swift files.

### 9. Main App

**Current**: 23 headers + 22 .m (~2,261 lines). Central controller: `KYAAppController` (604 lines).

**Swift rewrite**:

**App Controller & Delegate**:
- `KYAAppController` → Swift class orchestrating all subsystems. Replace NSNotificationCenter wiring with direct callbacks per the notification-to-closure mapping. Programmatic menu construction for the status bar dropdown menu (all menu items built in code, matching current feature set).
- `KYAAppDelegate` → Swift `NSApplicationDelegate` implementation (requires `@objc`). Handles Sparkle updater init (conditional on Direct scheme via `#if KYA_APP_UPDATER_ENABLED`), `applicationShouldHandleReopen:` for settings window.
- `KYAAppUpdater` → Swift class conditionally compiled with `#if KYA_APP_UPDATER_ENABLED`. Wraps `SPUUpdater` from Sparkle (Obj-C library, accessed via Clang module import bridge). The conditional compilation flag remains as a Swift compilation condition.

**Entry Point**:
- `main.m` → Remove entirely. Use a `@main` struct that sets up `NSApplication` programmatically (since there is no NIB to load):
  ```swift
  @main
  struct KYAAppMain {
      static func main() {
          let app = NSApplication.shared
          let delegate = KYAAppDelegate()
          app.delegate = delegate
          app.mainMenu = KYAMainMenuBuilder.build()
          app.run()
      }
  }
  ```
  This approach works because: (1) no `MainMenu.xib` exists, so the menu must be built before `run()`; (2) `NSApplicationMain()` requires a NIB/storyboard argument and would leave `mainMenu` nil without one. The `KYAMainMenuBuilder.build()` call constructs the menu before `NSApp.run()` enters the event loop.

**Main Menu**:
- `KYAMainMenu` → Swift module with `KYAMainMenuBuilder` class (or `KYACreateMainMenu()` function) that programmatically constructs the app's `NSApplication.mainMenu`. Builds Quit, Settings, and duration submenu items. **The `MainMenu.xib` is deleted.** The `Configuration.xcconfig` key `INFOPLIST_KEY_NSMainNibFile = MainMenu` is removed, since the main menu is no longer loaded from a NIB.

**Settings Window** (Programmatic AppKit):

Replace all XIBs with programmatic view construction:

| VC | Current XIB | Swift Implementation |
|---|---|---|
| `KYAGeneralSettingsViewController` | .xib | Programmatic `NSView` with checkboxes (launch at login, etc.) |
| `KYAAdvancedSettingsViewController` | .xib | Programmatic `NSView` — battery threshold, process monitoring, display params |
| `KYABatterySettingsViewController` | .xib | Programmatic `NSView` — battery auto-deactivation settings |
| `KYADurationSettingsViewController` | .xib | Programmatic `NSView` with `NSTableView` for duration list |
| `KYAAddDurationViewController` | .xib | Programmatic `NSView` / modal sheet with text fields for hours/minutes/seconds |
| `KYADurationCell` | .xib | Programmatic `NSTableCellView` subclass (all subviews: textLabel, defaultLabel created in code) |
| `KYAAboutSettingsViewController` | .xib | Programmatic `NSView` — app info, version, credits |
| `KYAUpdateSettingsViewController` | .xib | Programmatic `NSView` — Sparkle update settings (Direct scheme only) |

- `KYASettingsWindow` → Swift `NSWindow` subclass with toolbar segment control and `NSTabView` for in-window tab switching. This recreates the current app's UX pattern (toolbar buttons to switch between tabs within a single window), not macOS native window tabs (`NSWindowTabGroup` which groups separate windows in the title bar).
- `KYASettingsContentViewController` → Swift base class for settings tab VCs, providing common layout helpers.
- Layout uses `NSStackView`, `NSGridView`, `NSLayoutConstraint` — all in code.

**Supporting Types in Main App**:
- `KYAActivationUserNotification` → Swift subclass of `KYAUserNotification` (from the KYAUserNotifications package) with `init(fireDate:, activating:)`. Encapsulates notification content for timer activation/deactivation events.
- `KYAActivationDuration+KYALocalizedTitle` → Swift extension on `KYAActivationDuration` providing a `localizedTitle` computed property using `KYAL10n`.
- `KYABatteryCapacityThreshold` → Swift value type (struct or simple wrapper) for the battery capacity threshold setting. The `kKYABatteryCapacityThresholdDidChangeNotification` constant is replaced with either a direct callback or a `Notification.Name` static constant used with `NotificationCenter.default` (since this is an in-app notification between the advanced settings VC and the battery monitor logic, a closure is preferred but `Notification.Name` is acceptable if multiple listeners exist).
- `KYAUserDefaultsSetting` → Swift struct with `title: String`, `key: String`, `value: Bool` computed property (reads/writes `UserDefaults.standard`), and `reset()` method. Simple model for checkbox settings rows in the advanced settings VC. Not a property wrapper — it's a UI model type.

**Localization in Main App**:
- `KYALocalizedStrings.h/.m` → Remove entirely. Replace all 62 `KYA_L10N_*` `#define` macros with a `KYAL10n` Swift enum namespace wrapping `NSLocalizedString`. Example:
  ```swift
  enum KYAL10n {
      static let ok = NSLocalizedString("KYA_L10N_OK", tableName: "Localizable", bundle: .main, value: "OK", comment: "")
      static let cancel = NSLocalizedString("KYA_L10N_CANCEL", tableName: "Localizable", bundle: .main, value: "Cancel", comment: "")
  }
  ```
  This preserves the existing `.xcstrings` key structure (the keys `KYA_L10N_OK`, etc. remain unchanged in the JSON, so all 21 translations are preserved without needing to rename keys).

- `KYASettingsLocalizedStrings` → Nested `KYAL10n.Settings` enum with a separate `tableName: "KYASettings"` and `bundle: .main`. Example: `KYAL10n.Settings.advanced`.

- **Package-level localization**: Strings originating from SPM packages (e.g., KYAStatusItemUI tooltip strings) use `bundle: .module` in their `NSLocalizedString` calls (SPM provides `Bundle.module` for package resources). Each package that has localized strings defines its own `KYAL10n`-style namespace using `Bundle.module`. Package-level localization header files (like `KYAStatusItemUILocalizedStrings.h`) are eliminated — replaced by Swift namespaces with `Bundle.module`.
- All `.xcstrings` files stay in their current format and location. The `.xcstrings` files are: main `Localizable.xcstrings`, `KYASettings.xcstrings`, and per-VC `.xcstrings` files in each settings directory. The key structure within the JSON is preserved — `KYA_L10N_*` macro names become `NSLocalizedString` key strings, but their values don't change.

**Result**: ~25-30 Swift files for the main app. All XIBs deleted (including `MainMenu.xib` and all settings VC XIBs).

### 10. KYALauncher

**Current**: 1 header + 2 .m (~55 lines), `MainMenu.xib`, `Info.plist` (with `LSBackgroundOnly = true`), `KYALauncher.entitlements`, `AppIcon.icon` directory.

**Swift rewrite**:
- `main.swift` → Background-only app using `NSApplication.run()` without a NIB.
- `MainMenu.xib` → Deleted. `Info.plist` key `NSMainNibFile` is removed. The Swift app entry point uses `NSApplication.run()` without loading a NIB.
- Entitlements, `LSBackgroundOnly = true` plist key, and icon assets remain unchanged.
- If Swift runtime embedding requires additional entitlements for App Store distribution, update the entitlements accordingly. For direct distribution, the Swift runtime is embedded in the app bundle automatically.

**Result**: ~1-2 Swift files.

## Build System Changes

1. **SPM Package.swift files**: All 8 packages change from Obj-C targets (`.m`/`.h` sources, `publicHeadersPath`) to Swift targets (`.swift` sources, no `publicHeadersPath`). The `cxxLanguageStandard: .cxx17` setting is eliminated. For KYADeviceInfo's optional libproc C shim: if needed, add a separate `ClibprocShim` C target (`type: .regular`, sources: `["Sources/ClibprocShim/libproc_shim.c"]`) that the Swift target depends on. This is the standard SPM pattern for mixed C/Swift packages — the C target compiles independently and the Swift target links against it.
2. **Xcode project (`project.pbxproj`)**: Remove all `.m`/`.h` file references, add all `.swift` file references. Remove C++ build settings. Add Swift build settings (`SWIFT_VERSION = 5.9`, `SWIFT_OPTIMIZATION_LEVEL`). Update scheme configurations to reference Swift targets. Remove all XIB references (MainMenu.xib, all settings VC XIBs, KYADurationCell.xib). Remove NIB-related Info.plist generation keys.
3. **Makefile**: Largely unchanged — same build/test/dist commands, same xcbeautify piping. May need minor adjustments for Swift-specific warnings or test output format.
4. **Configuration.xcconfig**: `MACOSX_DEPLOYMENT_TARGET = 10.13` stays. Add `SWIFT_VERSION = 5.9`. Remove `INFOPLIST_KEY_NSMainNibFILE = MainMenu` (main menu is now built programmatically). Remove Obj-C-only settings.
5. **Sparkle**: Remains an external Obj-C SPM dependency. Swift calls it via the automatic Clang module import bridge. The conditional compilation flag `KYA_APP_UPDATER_ENABLED` stays as a Swift compilation condition (`#if KYA_APP_UPDATER_ENABLED`).
6. **Two distribution schemes** remain: App Store (sandboxed, no Sparkle) and Direct (sandboxed + Sparkle).

## Key Implementation Notes

### C Interop (libproc)

`KYAProcessMonitor` uses `proc_listallpids()` and `proc_pidpath()` from `<libproc.h>`. These are Darwin C functions, accessible in Swift via:
- Direct call after `import Darwin` (if Swift can auto-discover the header)
- Or a small C shim file (`libproc_shim.c` + `libproc_shim.h`) in the KYADeviceInfo package if needed for function declarations that Swift can't auto-import

This is the only place where C interop may be required. It does not require Obj-C.

### AppKit @objc Requirements

Some AppKit protocols require `@objc` dispatch for the Objective-C runtime. Swift classes implementing these need `@objc` annotations on protocol-conforming methods. This is standard Swift/AppKit practice and does not introduce Obj-C code — it's just a runtime annotation.

**@objc Needed For**:
- `NSApplicationDelegate` methods (`applicationDidFinishLaunching`, `applicationShouldHandleReopen`, etc.)
- `NSMenuDelegate` methods
- `NSWindowDelegate` methods
- Any class registered as `NSStatusItem.button.target`
- `UNUserNotificationCenterDelegate` methods

**@objc NOT Needed For**:
- Internal Swift-only classes (monitors, controllers, models)
- Protocol implementations used only within Swift code
- Closure-based communication patterns

### Sparkle Integration

Sparkle is an Obj-C library. Swift imports it via Clang module bridging. The `SPUUpdater` and related classes are accessible from Swift as if they were native. `KYAAppUpdater` wraps `SPUUpdater` and is conditionally compiled with `#if KYA_APP_UPDATER_ENABLED` (matching the Direct scheme). The App Store scheme does not include Sparkle or this wrapper.

## Tests

Each package's test suite is rewritten in Swift alongside the package. Test patterns:

| Obj-C Test Pattern | Swift Replacement |
|---|---|---|
| `XCTestCase` subclass | `XCTestCase` subclass (same framework, Swift API) |
| `@testMethod` | `func test...() throws` (Swift async test support) |
| `XCTAssertEqualObjects` | `XCTAssertEqual` (Swift value types) |
| Manual `@setUp`/`@tearDown` | `override func setUp()` / `tearDown()` |

Existing test coverage exists only for KYAActivationDurations, KYAApplicationSupport, and KYAApplicationEvents. The remaining 5 packages (KYACommon, KYADeviceInfo, KYASleepWakeTimer, KYAStatusItemUI, KYAUserNotifications) have no existing test targets. New Swift test targets should be created for these packages where testable logic exists.

The Makefile's `test` and `test-with-sanitizers` targets remain functional with Swift test targets.

## Success Criteria

1. All 8 SPM packages compile and pass tests in Swift
2. Main app builds and runs as a menu bar agent (LSUIElement) on macOS 10.13+
3. All features preserved: caffeinate wrapper, battery monitoring, LPM auto-deactivation, process monitoring, duration scheduling, URL scheme handling, notifications, launch-at-login
4. Settings window with 6 tabs, all programmatic AppKit (no XIBs)
5. Programmatic menu bar dropdown menu (no XIB, no MainMenu.xib)
6. All 21 localizations preserved in `.xcstrings` format (key structure unchanged)
7. Two distribution schemes: App Store and Direct (with Sparkle)
8. Zero Obj-C source files in the project (excluding Sparkle dependency and optional libproc C shim)
9. macOS 10.13+ deployment target maintained
10. Makefile targets (`test`, `dist`, `l10n-update`) functional

## Risks and Mitigations

| Risk | Mitigation |
|---|---|
| C++ chrono behavior not exactly replicated in Foundation | Test `KYAActivationDuration` thoroughly with edge cases (months with variable days, leap years, etc.) — Swift `Calendar` handles these correctly |
| `libproc` C interop complications | Write a thin C shim if Swift can't auto-import; this is a well-known Darwin bridging pattern |
| AppKit programmatic UI is verbose | Use layout helper extensions on `NSView` for common patterns (stack view with spacing, grid view alignment) |
| macOS 10.13 API availability constraints | Use `NSLocalizedString` not `String(localized:)`, `os_log` C functions not `os.Logger`, completion handlers not async/await. Use `@available(macOS 11/13, *)` checks with fallbacks for newer APIs |
| Sparkle Obj-C interop | Standard Swift/Clang module import — no issues expected |
| `KYA_L10N_*` key preservation in `.xcstrings` | Use existing macro names as `NSLocalizedString` keys (e.g., key `"KYA_L10N_OK"`), so all 21 translations are preserved without renaming |
| Swift runtime embedding on macOS 10.13 | Swift runtime is automatically embedded in the app bundle for deployment targets below macOS 12. App Store and direct distribution both handle this correctly |