# Localizations #

This folder is intended as export location for Xcode's *"Export for Localizations…"* feature.

## XLIFF ##

If you want to add a localization to KeepingYouAwake, please use these XLIFF files as reference, e.g. `de.xliff`. You can then import them in Xcode.

XLIFF files should be committed with any new translation and will be kept up-to-date during development.

## Scripts ##

This directory contains helper scripts to import/export localizations.

- `l10n-export.sh`: Exports all localizations
- `l10n-import.sh`: Imports all localizations from the `KeepingYouAwake` sub directory
- `l10n-update.sh`: Exports/Imports all translations
    - after the execution, all XLIFF files should be in sync
- `l10n-config.sh`: contains the list of translations in the `TRANSLATIONS` variable
    - please update this when you add translations

## Adding or changing strings in code ##

**Command-line `xcodebuild` does NOT extract new `NSLocalizedString` keys into the `.xcstrings` catalogs** (only building inside the Xcode IDE does). After adding or editing any user-facing string you must manually add the key — with all 22 languages — to the right catalog, otherwise even the English text is missing at runtime.

- Only `Localizable.strings` and `KYASettings.strings` are compiled into the bundle. The nib-ObjectID keys under `Settings/*/mul.lproj/*.xcstrings` are **not** looked up by code-created UI; new code strings should use `tableName: "Localizable"` and live in `KeepingYouAwake/Localizable.xcstrings`.
- Language tags: `zh` = 简体, `zh-Hant` = 繁体. Tooltips use a literal `\n` newline inside the key.
- Verify after building: `plutil -p <APP>/Contents/Resources/zh.lproj/Localizable.strings | grep <key>`.
