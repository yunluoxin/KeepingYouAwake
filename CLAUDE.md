# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KeepingYouAwake is a macOS menu bar utility (v2.0.0) that prevents Macs from sleeping. It wraps `/usr/bin/caffeinate` and supports indefinite or timed activation. LSUIElement app — no dock icon.

This fork recently migrated from Objective-C to Swift. If logic seems unclear, check prior OC commits: `git log --oneline` then `git show <hash>:<path>`.

## Build & Test Commands

- **Build**: `xcodebuild build -workspace KeepingYouAwake.xcworkspace -scheme KeepingYouAwake`
- **Test all**: `make test` (uses workspace + scheme, logs to `build/KeepingYouAwake.log`)
- **Test with sanitizers**: `make test-with-sanitizers`
- **Test single package**: `swift test --package-path Packages/KYASleepWakeTimer`
- **Clean**: `make clean`

### Packaging

| Command | Channel | Output |
|---------|---------|--------|
| `make app` | Direct | `dist/KeepingYouAwake.app` |
| `make dmg` | Direct | `dist/KeepingYouAwake-2.0.0.dmg` |
| `make dist` | App Store | `dist/KeepingYouAwake-2.0.0.zip` |
| `make package` | Both | `.zip` (App Store) + `.dmg` (Direct) |

`make app` archives with the Direct scheme and extracts the signed `.app` without creating a DMG. `make dmg` uses the same build path but wraps the app in a DMG and removes the intermediate `.app`.

Build schemes: `KeepingYouAwake` (App Store), `KeepingYouAwake (Direct)` (direct distribution with hardcoded entitlements), `KeepingYouAwake Launcher` (login helper).

## Architecture

**AppController** (`KeepingYouAwake/KYAAppController/AppController.swift`) is the central orchestrator. It owns `SleepWakeTimer`, `StatusItemController`, `ActivationDurationsMenuController`, and wires device monitoring, URL scheme events (`keepingyouawake://`), and notifications together.

Activation priority: Process monitoring > External display > Activate on Launch.

### 8 Local SPM Packages (`Packages/`)

| Package | Role | Notes |
|---------|------|-------|
| KYACommon | Logging (`KYALog`) | Foundation; depends on CLogShim (os_log shim for 10.13 compat) |
| KYAApplicationSupport | UserDefaults keys, bundle version, launch-at-login, display params | Depends on KYACommon |
| KYAApplicationEvents | URL scheme event handler | Depends on KYACommon |
| KYAActivationDurations | Duration model & controller | Depends on KYACommon |
| KYASleepWakeTimer | **Core engine** — spawns `/usr/bin/caffeinate` | Depends on KYACommon, KYAApplicationSupport |
| KYADeviceInfo | Battery, Low Power Mode, process tracking | Depends on ClibprocShim (libproc C shim) |
| KYAStatusItemUI | Menu bar status item appearance & click handling | Depends on KYACommon, KYAApplicationSupport |
| KYAUserNotifications | User notification center abstraction | Depends on KYACommon |

C shims: **CLogShim** (os_log for macOS 10.13), **ClibprocShim** (libproc for PID enumeration).

### Main App Target (`KeepingYouAwake/`)

- `AppMain.swift` — Entry point (`@main`, programmatic launch)
- `KYAAppController/` — AppDelegate + AppController
- `KYAMainMenu/` — Programmatic menu bar menu builder
- `Settings/` — NSTabViewController with tabs: General, Duration, Battery, Advanced, About, Update (conditional)
- `UserDefaultsSetting.swift` — Bool setting model backed by UserDefaults
- All UI is programmatic (no NIBs/storyboards); uses **SnapKit** for Auto Layout
- Uses **Cocoa Bindings** (NSUserDefaultsController) for settings checkboxes/sliders
- Localization via `.xcstrings` string catalogs (21 languages)

## Key Technical Details

- **Caffeinate invocations**: indefinite = `caffeinate -di -w <PID>`, timed = `caffeinate -di -t <seconds> -w <PID>`
- **Sparkle** auto-update is conditional (`#if KYA_APP_UPDATER_ENABLED`), not always compiled
- **ProcessMonitor** uses a 3-layer monitoring strategy (check code in `KYADeviceInfo`)
- **ServiceManagement** (`SMAppService`) for Launch at Login on macOS 13+, with legacy fallback in `KYALauncher/`
- Deployment target: macOS 10.13, Swift 5.9