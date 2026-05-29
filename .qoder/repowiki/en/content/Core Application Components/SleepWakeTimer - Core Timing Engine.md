# SleepWakeTimer - Core Timing Engine

<cite>
**Referenced Files in This Document**
- [SleepWakeTimer.swift](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift)
- [AppController.swift](file://KeepingYouAwake/KYAAppController/AppController.swift)
- [SleepWakeTimerTests.swift](file://Packages/KYASleepWakeTimer/Tests/KYASleepWakeTimerTests/SleepWakeTimerTests.swift)
- [ActivationDurationsMenuController.swift](file://KeepingYouAwake/KYAActivationDurationsMenuController/ActivationDurationsMenuController.swift)
- [ActivationUserNotification.swift](file://KeepingYouAwake/KYAActivationUserNotification/ActivationUserNotification.swift)
- [AdvancedSettingsViewController.swift](file://KeepingYouAwake/Settings/KYAAdvancedSettingsViewController/AdvancedSettingsViewController.swift)
- [BatterySettingsViewController.swift](file://KeepingYouAwake/Settings/KYABatterySettingsViewController/BatterySettingsViewController.swift)
- [KYAL10n.swift](file://KeepingYouAwake/KYAL10n.swift)
</cite>

## Table of Contents
1. [Introduction](#introduction)
2. [Project Structure](#project-structure)
3. [Core Components](#core-components)
4. [Architecture Overview](#architecture-overview)
5. [Detailed Component Analysis](#detailed-component-analysis)
6. [Dependency Analysis](#dependency-analysis)
7. [Performance Considerations](#performance-considerations)
8. [Troubleshooting Guide](#troubleshooting-guide)
9. [Conclusion](#conclusion)

## Introduction
SleepWakeTimer is the core timing engine responsible for macOS sleep prevention functionality in KeepingYouAwake. It serves as a Swift wrapper around Apple's `caffeinate` command-line utility, managing system sleep prevention through process spawning and lifecycle callbacks. The component provides a clean, callback-based interface for activation and deactivation events while handling the complexities of macOS power management integration.

The timer operates in two primary modes: indefinite mode (timeInterval = 0) for continuous sleep prevention, and timed mode (timeInterval > 0) for temporary sleep prevention with automatic expiration. It integrates deeply with macOS power management APIs and provides comprehensive state tracking for reliable operation.

## Project Structure
The SleepWakeTimer component is organized within a dedicated Swift package that encapsulates all timing-related functionality. The package follows a modular architecture with clear separation of concerns between the timer logic, process management, and callback systems.

```mermaid
graph TB
subgraph "Package Structure"
SWT[SleepWakeTimer Package]
Sources[Sources/KYASleepWakeTimer]
Tests[Tests/KYASleepWakeTimerTests]
end
subgraph "Core Module"
TimerClass[SleepWakeTimer.swift]
Constants[indefiniteTimeInterval]
Callbacks[Callback System]
end
subgraph "Integration Layer"
AppController[Integration with AppController]
MenuController[Duration Menu Integration]
Notifications[User Notification System]
end
subgraph "Testing Framework"
UnitTests[Test Coverage]
Mocks[Test Utilities]
end
SWT --> Sources
Sources --> TimerClass
Sources --> Constants
Sources --> Callbacks
SWT --> Tests
Tests --> UnitTests
Tests --> Mocks
TimerClass --> AppController
TimerClass --> MenuController
TimerClass --> Notifications
```

**Diagram sources**
- [SleepWakeTimer.swift:1-191](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L1-L191)
- [AppController.swift:1-352](file://KeepingYouAwake/KYAAppController/AppController.swift#L1-L352)

**Section sources**
- [SleepWakeTimer.swift:1-191](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L1-L191)
- [AppController.swift:1-352](file://KeepingYouAwake/KYAAppController/AppController.swift#L1-L352)

## Core Components

### SleepWakeTimer Class Architecture
The SleepWakeTimer class implements a robust timer management system with comprehensive state tracking and callback mechanisms. The class maintains four primary callback points: onActivate, onDeactivate, and a completion block that receives cancellation status.

```mermaid
classDiagram
class SleepWakeTimer {
+TimeInterval fireDate
+TimeInterval scheduledTimeInterval
+Bool isScheduled
+TimeInterval indefiniteTimeInterval
+onActivate : ((TimeInterval) -> Void)?
+onDeactivate : (() -> Void)?
+completionBlock : ((Bool) -> Void)?
-Process caffeinateProcess
-NSObjectProtocol terminationObserver
+init()
+schedule(timeInterval : TimeInterval, completion : ((Bool) -> Void)?)
+invalidate()
-spawnCaffeinateProcess(forTimeInterval : TimeInterval)
-terminateCaffeinateProcess()
-handleTermination(cancelled : Bool)
-caffeinateArguments(forTimeInterval : TimeInterval) [internal]
}
class Process {
+URL executableURL
+String[] arguments
+Bool isRunning
+Void terminationHandler
+Void run()
+Void terminate()
}
class NotificationCenter {
+addObserver(forName : Notification.Name, object : Any?, queue : OperationQueue?, using : (Notification) -> Void) NSObjectProtocol
+removeObserver(NSObjectProtocol)
}
SleepWakeTimer --> Process : "manages"
SleepWakeTimer --> NotificationCenter : "observes"
```

**Diagram sources**
- [SleepWakeTimer.swift:24-191](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L24-L191)

### Timer Scheduling Mechanism
The scheduling system operates through a sophisticated process spawning mechanism that leverages macOS's built-in `caffeinate` utility. The system supports both indefinite and timed scheduling modes with precise fire date calculation.

```mermaid
sequenceDiagram
participant Client as "Client Code"
participant Timer as "SleepWakeTimer"
participant Process as "Process"
participant Caffeinate as "caffeinate"
participant Callback as "Callbacks"
Client->>Timer : schedule(timeInterval, completion)
Timer->>Timer : onActivate?(timeInterval)
Timer->>Timer : calculate fireDate
Timer->>Timer : spawnCaffeinateProcess()
Timer->>Process : new Process()
Timer->>Process : set executableURL
Timer->>Process : set arguments
Timer->>Process : set terminationHandler
Timer->>Process : run()
Process->>Caffeinate : launch with arguments
Caffeinate-->>Process : process started
Process-->>Timer : terminationHandler called
Timer->>Timer : handleTermination(cancelled)
Timer->>Callback : completion?(cancelled)
Timer->>Callback : onDeactivate?()
Callback-->>Client : completion callback
```

**Diagram sources**
- [SleepWakeTimer.swift:78-112](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L78-L112)
- [SleepWakeTimer.swift:146-165](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L146-L165)

**Section sources**
- [SleepWakeTimer.swift:24-191](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L24-L191)

## Architecture Overview

### System Integration Architecture
The SleepWakeTimer integrates with multiple system components to provide comprehensive sleep prevention functionality. The architecture ensures minimal overhead while maintaining robust system integration.

```mermaid
graph TB
subgraph "Application Layer"
AppController[AppController]
MenuController[ActivationDurationsMenuController]
SettingsControllers[Settings Controllers]
end
subgraph "Timing Engine Layer"
SleepWakeTimer[SleepWakeTimer]
CallbackSystem[Callback System]
StateManager[State Management]
end
subgraph "System Integration Layer"
Caffeinate[caffeinate Process]
PowerManagement[macOS Power Management]
UserNotifications[User Notification Center]
end
subgraph "Configuration Layer"
UserDefaults[UserDefaults]
DeviceMonitoring[Device Monitoring]
BatteryThreshold[Battery Threshold]
end
AppController --> SleepWakeTimer
AppController --> MenuController
AppController --> SettingsControllers
SleepWakeTimer --> CallbackSystem
SleepWakeTimer --> StateManager
SleepWakeTimer --> Caffeinate
SleepWakeTimer --> PowerManagement
SleepWakeTimer --> UserNotifications
AppController --> UserDefaults
AppController --> DeviceMonitoring
DeviceMonitoring --> BatteryThreshold
UserNotifications --> UserDefaults
```

**Diagram sources**
- [AppController.swift:21-90](file://KeepingYouAwake/KYAAppController/AppController.swift#L21-L90)
- [SleepWakeTimer.swift:18-57](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L18-L57)

### Fire Date Calculation Algorithm
The fire date calculation system implements precise timestamp computation for timed scheduling modes. The algorithm handles both absolute and relative time calculations with appropriate tolerance for system timing variations.

```mermaid
flowchart TD
Start([Schedule Request]) --> ValidateInput["Validate timeInterval >= 0"]
ValidateInput --> InputValid{"timeInterval == 0?"}
InputValid --> |Yes| SetIndefinite["Set fireDate = nil<br/>scheduledTimeInterval = 0"]
InputValid --> |No| CalculateTimestamp["Calculate fireDate = now + timeInterval"]
CalculateTimestamp --> ValidateRange["Validate timestamp range"]
ValidateRange --> RangeValid{"Within acceptable range?"}
RangeValid --> |Yes| SetTimed["Set fireDate<br/>scheduledTimeInterval = timeInterval"]
RangeValid --> |No| AdjustTimestamp["Adjust timestamp to acceptable range"]
AdjustTimestamp --> SetTimed
SetIndefinite --> SpawnProcess["Spawn caffeinate process"]
SetTimed --> SpawnProcess
SpawnProcess --> SetupCallbacks["Setup completion and termination callbacks"]
SetupCallbacks --> Complete([Schedule Complete])
```

**Diagram sources**
- [SleepWakeTimer.swift:98-102](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L98-L102)

**Section sources**
- [SleepWakeTimer.swift:78-103](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L78-L103)

## Detailed Component Analysis

### Timer State Management
The SleepWakeTimer maintains comprehensive state tracking through four key properties: `fireDate`, `scheduledTimeInterval`, `isScheduled`, and `completionBlock`. These properties provide external visibility into the timer's current state while maintaining internal consistency.

```mermaid
stateDiagram-v2
[*] --> Idle
Idle --> Scheduled : schedule()
Scheduled --> Running : process spawned
Running --> Completed : natural expiration
Running --> Cancelled : invalidate()
Completed --> Idle : cleanup complete
Cancelled --> Idle : cleanup complete
note right of Scheduled : fireDate calculated<br/>scheduledTimeInterval set
note right of Running : caffeinate process<br/>active monitoring
note right of Completed : completion called<br/>cancelled = false
note right of Cancelled : completion called<br/>cancelled = true
```

**Diagram sources**
- [SleepWakeTimer.swift:42-51](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L42-L51)
- [SleepWakeTimer.swift:173-190](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L173-L190)

### Callback-Based Architecture
The callback system provides three distinct callback points for different lifecycle events: `onActivate`, `onDeactivate`, and the completion block. Each callback serves a specific purpose in the timer lifecycle management.

```mermaid
sequenceDiagram
participant Timer as "SleepWakeTimer"
participant App as "AppController"
participant Completion as "Completion Block"
participant UI as "UI Updates"
Timer->>App : onActivate?(scheduledTimeInterval)
App->>UI : statusItemController.appearance = .active
App->>App : enableDevicePowerMonitoring()
Note over Timer : Process runs until expiration or cancellation
Timer->>Completion : completion?(cancelled)
Timer->>App : onDeactivate?()
App->>UI : statusItemController.appearance = .inactive
App->>App : disableDevicePowerMonitoring()
Note over Timer,Completion : State cleanup and resource release
```

**Diagram sources**
- [SleepWakeTimer.swift:27-30](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L27-L30)
- [AppController.swift:78-85](file://KeepingYouAwake/KYAAppController/AppController.swift#L78-L85)

**Section sources**
- [SleepWakeTimer.swift:26-51](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L26-L51)
- [AppController.swift:77-85](file://KeepingYouAwake/KYAAppController/AppController.swift#L77-L85)

### Caffeinate Process Integration
The process integration layer manages the spawning and lifecycle of `caffeinate` processes with comprehensive error handling and cleanup procedures. The system supports both indefinite and timed operation modes through appropriate argument construction.

```mermaid
flowchart TD
ScheduleRequest[Schedule Request] --> BuildArgs["Build caffeinate arguments"]
BuildArgs --> CheckDisplayFlag{"allowDisplaySleep?"}
CheckDisplayFlag --> |Yes| AddIFlag["Add -i flag"]
CheckDisplayFlag --> |No| AddDIFlag["Add -di flag"]
AddIFlag --> CheckTimeout{"timeInterval != 0?"}
AddDIFlag --> CheckTimeout
CheckTimeout --> |Yes| AddTFlag["Add -t flag with seconds"]
CheckTimeout --> |No| SkipTimeout["Skip timeout flag"]
AddTFlag --> AddWFlag["Add -w flag with PID"]
SkipTimeout --> AddWFlag
AddWFlag --> SpawnProcess["Spawn process"]
SpawnProcess --> MonitorProcess["Monitor process lifecycle"]
MonitorProcess --> ProcessComplete{"Process terminated"}
ProcessComplete --> |Normal| HandleNormal["Handle normal completion"]
ProcessComplete --> |Cancelled| HandleCancelled["Handle manual cancellation"]
HandleNormal --> Cleanup["Cleanup resources"]
HandleCancelled --> Cleanup
Cleanup --> CallCallbacks["Call completion and deactivation callbacks"]
```

**Diagram sources**
- [SleepWakeTimer.swift:120-144](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L120-L144)
- [SleepWakeTimer.swift:146-165](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L146-L165)

**Section sources**
- [SleepWakeTimer.swift:115-165](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L115-L165)

### Integration with AppController
The AppController serves as the central orchestrator that integrates SleepWakeTimer with the broader application ecosystem. The integration includes menu system coordination, user notification handling, and device monitoring capabilities.

```mermaid
classDiagram
class AppController {
+SleepWakeTimer sleepWakeTimer
+StatusItemController statusItemController
+ActivationDurationsMenuController menuController
+configureSleepWakeTimer()
+activateTimer()
+terminateTimer()
+handleDurationSelection(ActivationDuration)
+handlePrimaryAction()
}
class SleepWakeTimer {
+onActivate : ((TimeInterval) -> Void)?
+onDeactivate : (() -> Void)?
+schedule(timeInterval : TimeInterval, completion : ((Bool) -> Void)?)
+invalidate()
}
class ActivationDurationsMenuController {
+onSelectDuration : ((ActivationDuration) -> Void)?
+onGetFireDate : ((ActivationDurationsMenuController) -> Date?)?
+menu : NSMenu
}
AppController --> SleepWakeTimer : "manages"
AppController --> ActivationDurationsMenuController : "coordinates"
SleepWakeTimer --> AppController : "callback target"
ActivationDurationsMenuController --> AppController : "duration selection"
```

**Diagram sources**
- [AppController.swift:21-352](file://KeepingYouAwake/KYAAppController/AppController.swift#L21-L352)
- [ActivationDurationsMenuController.swift:15-126](file://KeepingYouAwake/KYAActivationDurationsMenuController/ActivationDurationsMenuController.swift#L15-L126)

**Section sources**
- [AppController.swift:77-122](file://KeepingYouAwake/KYAAppController/AppController.swift#L77-L122)
- [ActivationDurationsMenuController.swift:15-38](file://KeepingYouAwake/KYAActivationDurationsMenuController/ActivationDurationsMenuController.swift#L15-L38)

## Dependency Analysis

### Component Dependencies
The SleepWakeTimer component maintains focused dependencies on system frameworks and internal utilities, ensuring modularity and testability.

```mermaid
graph TB
subgraph "External Dependencies"
Foundation[Foundation Framework]
AppKit[AppKit Framework]
Process[Process Class]
Date[Date Class]
UserDefaults[UserDefaults]
end
subgraph "Internal Dependencies"
KYACommon[KYACommon Logging]
KYAApplicationSupport[KYAApplicationSupport]
UserNotificationCenter[UserNotificationCenter]
end
subgraph "SleepWakeTimer"
TimerClass[SleepWakeTimer]
ProcessManager[Process Management]
CallbackSystem[Callback System]
StateTracking[State Tracking]
end
TimerClass --> Foundation
TimerClass --> AppKit
TimerClass --> Process
TimerClass --> Date
TimerClass --> UserDefaults
TimerClass --> KYACommon
TimerClass --> KYAApplicationSupport
TimerClass --> UserNotificationCenter
ProcessManager --> Process
ProcessManager --> Date
CallbackSystem --> TimerClass
StateTracking --> TimerClass
```

**Diagram sources**
- [SleepWakeTimer.swift:8-11](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L8-L11)
- [SleepWakeTimer.swift:57](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L57)

### Integration Points with System APIs
The component integrates with several macOS system APIs for comprehensive power management functionality.

| Integration Point | Purpose | Implementation |
|------------------|---------|----------------|
| `caffeinate` Process | System sleep prevention | Process spawning with arguments |
| `NSApplication.willTerminateNotification` | Graceful shutdown cleanup | Observer registration |
| `UserNotificationCenter` | User notifications | macOS 11.0+ notification posting |
| `UserDefaults` | Configuration persistence | Boolean flags and thresholds |
| `Device Monitoring` | Battery and power state | Low power mode and capacity monitoring |

**Section sources**
- [SleepWakeTimer.swift:59-74](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L59-L74)
- [AppController.swift:181-187](file://KeepingYouAwake/KYAAppController/AppController.swift#L181-L187)

## Performance Considerations

### Process Management Efficiency
The timer implementation optimizes resource usage through efficient process management and minimal overhead. The system spawns a single `caffeinate` process per activation and cleans up resources upon completion or cancellation.

### Memory Management
The component employs weak references in callback closures to prevent retain cycles and ensure proper memory cleanup. The design pattern prevents memory leaks while maintaining functional integrity.

### Callback Execution Strategy
All callbacks execute on the main queue to ensure thread safety and UI consistency. This approach prevents race conditions while maintaining responsive user interface updates.

## Troubleshooting Guide

### Common Error Scenarios

#### Process Launch Failures
When the `caffeinate` process fails to launch, the system logs an error and triggers immediate deactivation. Common causes include permission issues or system resource constraints.

**Detection**: Error logging in `handleTermination(cancelled: true)` with process launch exceptions.

#### State Inconsistencies
The system includes safeguards against state inconsistencies through careful state management and cleanup procedures. Double-calling of completion blocks is prevented through state reset.

**Detection**: Test coverage for completion block invocation frequency and state reset verification.

#### Configuration Conflicts
Conflicting user preferences can cause unexpected behavior. The system validates input parameters and gracefully handles invalid configurations.

**Detection**: Input validation in `activateTimerWithTimeInterval` and preference checking in AppController.

### Debugging Strategies

#### Logging Integration
The component uses the unified logging system (`KYALog`) for comprehensive debugging information. Logs capture activation attempts, process lifecycle events, and error conditions.

#### Test Coverage
Extensive unit tests validate core functionality including argument construction, state management, and callback behavior. Tests cover both positive and negative scenarios.

**Section sources**
- [SleepWakeTimer.swift:162-164](file://Packages/KYASleepWakeTimer/Sources/KYASleepWakeTimer/SleepWakeTimer.swift#L162-L164)
- [SleepWakeTimerTests.swift:133-146](file://Packages/KYASleepWakeTimer/Tests/KYASleepWakeTimerTests/SleepWakeTimerTests.swift#L133-L146)

## Conclusion

The SleepWakeTimer component represents a sophisticated yet elegant solution for macOS sleep prevention functionality. Through its integration with `caffeinate`, comprehensive callback system, and robust state management, it provides reliable and efficient sleep prevention capabilities.

The component's architecture demonstrates excellent separation of concerns, with clear boundaries between process management, callback handling, and state tracking. The integration with AppController and other system components creates a cohesive timing workflow that responds appropriately to user actions and system events.

Key strengths of the implementation include:
- **Reliable Process Management**: Efficient `caffeinate` process spawning with comprehensive error handling
- **Flexible Scheduling**: Support for both indefinite and timed operation modes
- **Robust Callback System**: Three-tier callback architecture for comprehensive lifecycle management
- **System Integration**: Deep integration with macOS power management and notification systems
- **Comprehensive Testing**: Extensive test coverage ensuring reliability across scenarios

The component successfully balances functionality with simplicity, providing developers with a clean interface while handling the complexities of system-level sleep prevention. Its modular design and clear dependencies make it maintainable and extensible for future enhancements.