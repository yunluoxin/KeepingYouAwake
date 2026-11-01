# KYASleepWakeTimer

The `KYASleepWakeTimer` holds an IOKit power assertion and allows preventing your Mac from going to sleep.

The assertion is held in-process via `ProcessInfo.beginActivity`. macOS 26 and later drop every power assertion when `powerd` restarts — they clear the whole assertion table without telling the holder — so on those systems the assertion is verified and restored every 10 seconds. Older systems keep the assertion for the lifetime of its holder and don't need the heartbeat.
