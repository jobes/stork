# Localization and Internationalization (i18n)

This document describes the internationalization setup and localization architecture of the Stork application.

---

## 1. System Overview

To provide a seamless experience for pilots globally, Stork supports multiple languages using Flutter's official `flutter_localizations` package. 

The localization engine translates all user-facing text, including:
- Settings and configuration menus
- Dialog titles and descriptions
- Widget labels and telemetry metrics
- Navigation and map controls
- Error and warning alerts

## 2. Configuration and Files

The localization source files are stored in the `lib/l10n` directory. The configuration is defined in the `l10n.yaml` file located in the project root.

### 2.1. Translation Files (.arb)
Stork uses Application Resource Bundle (`.arb`) files to store key-value translation pairs.

- **English (Base/Fallback)**: `lib/l10n/app_en.arb`
- **Slovak**: `lib/l10n/app_sk.arb`

### 2.2. Generated Dart Classes
During the build process, Flutter automatically generates Dart classes from the `.arb` files:
- `app_localizations.dart`: Contains the abstract `AppLocalizations` class.
- `app_localizations_en.dart`: The English concrete implementation.
- `app_localizations_sk.dart`: The Slovak concrete implementation.

## 3. Usage in the Application

All translated strings are accessed via the `AppLocalizations.of(context)` delegate. 

Example usage in a Flutter Widget:
```dart
Text(AppLocalizations.of(context)!.settingsFlightTitle)
```

## 4. Adding New Languages

To add a new language to Stork:
1. Create a new `.arb` file in the `lib/l10n/` directory (e.g., `app_de.arb` for German).
2. Copy the keys from `app_en.arb` and provide the translated strings.
3. Add the language code to the supported locales list in `main.dart` or the root `MaterialApp` configuration.
4. Run `flutter gen-l10n` (explicitly run this command after adding or modifying ARB files to ensure localization classes are properly regenerated, as this is the primary and reliable method for regenerating localization code).
