# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

KeepingYouAwake is a macOS menu bar utility (v2.0.0) that prevents Macs from sleeping. It holds an IOKit power assertion in-process (`ProcessInfo.beginActivity`) and supports indefinite or timed activation. LSUIElement app — no dock icon.

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
| KYASleepWakeTimer | **Core engine** — holds an IOKit power assertion | Depends on KYACommon, KYAApplicationSupport |
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
- Localization via `.xcstrings` string catalogs (22 languages, `zh`=简体, `zh-Hant`=繁体)

## Master Switch vs. Activation State (语义分离)

两个正交状态，不要混淆：

- **主开关 `kya_enabled`**(UserDefaults,持久化,默认 `true`)= "真关"。OFF = 无防休眠断言、无进程/显示器/电量监听,app 运行但完全惰性,且跨重启保持。触发入口四处等价:status bar 左键、菜单 Disable/Enable、General 设置 checkbox、URL scheme `activate`/`deactivate`。
- **激活状态**(`sleepWakeTimer.isScheduled`,运行时)= 当前是否在防休眠,由设置驱动,**纯只读显示**,不是可操作的开关。
- **图标/菜单不持有状态**:`AppController.updateAppearance()` 统一派生三态 —— 主开关 OFF→`.disabled`(图标降透明度 0.35)、isScheduled→`.active`、否则→`.inactive`。菜单弹出前由 `MainMenuController`(NSMenuDelegate)刷新状态行与开关项。

`AppController.setEnabled(_:)` 是主开关的唯一入口,所有自动激活回调(进程/显示器/用户切换/电量)都有 `guard isEnabled`。

## Localization — 改文案必须同步 catalog

**命令行 `xcodebuild` 不会自动把新字符串提取进 `.xcstrings`**(只有 Xcode IDE 构建才会)。所以新增/修改任何 `NSLocalizedString` 后,**必须手动把 key 加进对应 `.xcstrings`**,否则运行时连英文都查不到。

- 运行时只有 `Localizable.strings` 和 `KYASettings.strings` 两个表会编译进 bundle。`Settings/*/mul.lproj/*.xcstrings` 里的 nib-ObjectID key(如 `zql-rZ-9xH.title`)**不会**被运行时代码查到 —— 代码里新增的字符串要用 `tableName: "Localizable"` 并加进 `Localizable.xcstrings`。
- 每个 key 需补齐全部 22 种语言。术语参照现有条目(如 zh "防止休眠"、zh-Hant "防止睡眠"、tooltip 用真实换行 `\n`)。
- 验证:build 后 `plutil -p <APP>/Contents/Resources/zh.lproj/Localizable.strings | grep <key>`。

## Key Technical Details

- **Power assertion**: `SleepWakeTimer` 进程内持有 `ProcessInfo.beginActivity` 断言 —— `.idleSystemSleepDisabled` 恒开;`kya_allowDisplaySleep == false` 时再加 `.idleDisplaySleepDisabled`。定时模式由 app 自己的 Timer 到 `fireDate` 释放。
- **powerd 重启会清空整个断言表**(macOS 27 上实测 8 天 57 次),且**不通知持有者** —— 断言会静默消失,app 进程却还活着。因此 `SleepWakeTimer` 每 10s 用 `IOPMCopyAssertionsByProcess` 自查自己 pid 下还有没有 `PreventUserIdleSystemSleep`,掉了就重建。**不要退回"进程活着 == 还在防休眠"的判断**,那是本 bug 的根源。
- **心跳只在 macOS 26+ 启用**(`SleepWakeTimer.isHeartbeatRequired`):更早的系统不会在 powerd 重启时清空断言表,心跳纯属浪费。实测单次自查 ≈ 0.14ms,10s 一次约 1.2s CPU/天(实测激活/停用 120s 的 CPU 增量无差异),不需要拉长间隔。
- **Sparkle** auto-update is conditional (`#if KYA_APP_UPDATER_ENABLED`), not always compiled
- **ProcessMonitor** uses a 3-layer monitoring strategy (check code in `KYADeviceInfo`)
- **ServiceManagement** (`SMAppService`) for Launch at Login on macOS 13+, with legacy fallback in `KYALauncher/`
- Deployment target: macOS 10.13, Swift 5.9