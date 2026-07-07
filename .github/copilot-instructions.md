# Stork — Project Guidelines

Stork is a Flutter aviation app (EFB) for glider/aircraft pilots.
Targets Android, iOS, Linux, macOS, Windows, and Web.

## Architecture

**Clean Architecture + Riverpod** — strictly three layers per feature: `data` → `domain` → `presentation`.

```
lib/
├── core/          # Shared infrastructure (router, theme, services, utils, providers)
└── features/
    └── <feature>/
        ├── data/          # Repository implementations, HTTP, SQLite, SharedPrefs
        ├── domain/        # Entities, value objects, repository interfaces
        └── presentation/
            ├── pages/
            ├── components/
            └── providers/  # Riverpod notifiers and providers
```

New features must follow this structure. Never mix layers (e.g., no HTTP calls in presentation).

See [documentation/](../documentation/README.md) for feature and architecture docs.

## State Management

Use **Riverpod with code generation** (`riverpod_generator`, `@riverpod` annotation).

- Mutable state → `@riverpod class MyNotifier extends _$MyNotifier` (generates `NotifierProvider`)
- Async init from a repository → `AsyncNotifier`
- One-time async operations → `@riverpod Future<T>` (generates `FutureProvider`)
- Session-persistent providers → `@Riverpod(keepAlive: true)`
- Use `Provider.select()` for selective rebuilds on specific fields

```dart
// Correct
@Riverpod(keepAlive: true)
class TelemetryNotifier extends _$TelemetryNotifier {
  @override
  TelemetryState build() => TelemetryState.initial();
}
```

Run `dart run build_runner build --delete-conflicting-outputs` after adding/changing `@riverpod` annotations.

## Dependency Injection

Riverpod providers are the DI container — no service locators, no `get_it`.

```dart
@riverpod
Future<SettingsRepository> settingsRepository(Ref ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return SettingsRepository(prefs);
}
```

Dependency flow: UI → Notifier (via `ref`) → Repository → Database / HTTP / SharedPreferences.

Platform-specific dependencies use conditional exports:
```dart
export 'database_service_web.dart'
    if (dart.library.io) 'database_service_io.dart';
```

## Domain Layer

Use **Freezed** for immutable entities and value objects:

```dart
@freezed
abstract class Flight with _$Flight {
  const factory Flight({
    required String uuid,
    required String name,
    @JsonKey(name: 'start_time') required DateTime startTime,
    DateTime? endTime,
  }) = _Flight;
  factory Flight.fromJson(Map<String, dynamic> json) => _$FlightFromJson(json);
}
```

Use **sealed classes** for operation results in notifiers:
```dart
sealed class SettingsUpdateResult {}
class SettingsUpdateSuccess extends SettingsUpdateResult {}
class SettingsUpdateFailure extends SettingsUpdateResult {
  final Object error;
}
```

## Data Layer

- **HTTP**: use `package:http` with 15-second timeouts; fall back to offline cache when available
- **SQLite**: via `sqlite3` (IO only); platform-specific via conditional export
- **SharedPreferences**: for user settings and persisted key-value data
- Repositories throw `StateError` / `FormatException` on failures; notifiers catch and handle

## Platform Guards

SQLite and any `dart:io` APIs are unavailable on Web. Guard all IO-only code:

```dart
import 'package:flutter/foundation.dart' show kIsWeb;

if (!kIsWeb) {
  // SQLite, file system, socket operations
}
```

Use conditional exports for platform-specific service implementations:
```dart
export 'database_service_web.dart'
    if (dart.library.io) 'database_service_io.dart';
```

## Navigation

GoRouter configured in `lib/core/router/app_router.dart`. Add all routes there.
Navigation is presentation-only — no routing logic in domain or data layers.

## Widget Type Selection

| Widget base | When to use |
|-------------|-------------|
| `ConsumerWidget` | Default for all pages and components that read Riverpod state |
| `ConsumerStatefulWidget` | Only when lifecycle hooks (`initState`, `dispose`, `didChangeDependencies`) are also needed |
| `StatefulWidget` | Only for purely ephemeral local UI state (drag position, animation, text field focus) that is never shared |

Never use `StatefulWidget` to manage state that should survive widget rebuilds or be shared — use Riverpod instead.

## Riverpod Usage Rules

- `ref.watch(...)` — **only inside `build()`**; subscribes and triggers rebuilds
- `ref.read(...)` — **only inside methods and callbacks**; one-time synchronous read
- `ref.listen(...)` — side effects in response to state changes, also inside `build()`
- Never pass `BuildContext` into a notifier or repository — notifiers must not depend on the widget tree

## UI Design Consistency

All UI must follow the established visual language — do not introduce new dialog or overlay styles.

### Dialogs

All dialogs must use `BaseDetailsDialog` from `lib/features/map/presentation/components/dialogs/base_details_dialog.dart`. This enforces:
- Frosted glass appearance (`BackdropFilter` + blur)
- Rounded corners (radius 24), consistent padding
- Dark/light theme support via `Theme.of(context).brightness`
- Draggable via the embedded `DraggableOverlay` — **all dialogs are movable by the user**

Expose dialogs as standalone functions, not widgets:
```dart
void showMyDialog(BuildContext context, WidgetRef ref) {
  showDialog(
    context: context,
    builder: (_) => BaseDetailsDialog(
      titleText: 'Title',
      icon: Icons.info_outline,
      child: ...,
    ),
  );
}
```

Never use raw `AlertDialog` or `SimpleDialog` — always go through `BaseDetailsDialog`.

### Map Overlays

Telemetry widgets and other map overlays must use `DraggableWidget` (via `MapWidgetWrapper`) so users can reposition them freely on the map.

### Theme

Always respect dark/light mode — use `Theme.of(context)` colour tokens, never hard-coded colours. Where custom colours are needed (e.g., status indicators), provide both dark and light variants.

## Naming Conventions

| Element | Convention | Example |
|---------|-----------|---------|
| Files | snake_case | `airport_metadata_provider.dart` |
| Classes | PascalCase | `AirportMetadata`, `SettingsRepository` |
| Private members | `_camelCase` | `_memoryCache` |
| DB columns | snake_case | `downloaded_at`, `min_lat` |
| Enum values | camelCase | `TelemetryField.groundSpeed` |

Semantic suffixes are mandatory:
- `*Repository` — data access layer
- `*Service` — core services (`DatabaseService`, `CannelloniService`)
- `*State` — state models (`TelemetryState`, `NavigationState`)
- `*Notifier` — Riverpod notifier classes
- `*Provider` — Riverpod provider variables (auto-generated)

## Error Handling

- **Domain layer**: throw exceptions, do not catch (let them propagate)
- **Data layer**: catch, log with `debugPrint`, reset to defaults when possible
- **Presentation layer**: use `AsyncValue.hasError` / `.isLoading`; expose sealed result types to UI

Never swallow errors silently in the data layer without logging.

## Localization

All user-visible strings must use `AppLocalizations.of(context)!.<key>`.
Add keys to both `lib/l10n/app_en.arb` and `lib/l10n/app_sk.arb`.
Run `flutter gen-l10n` after editing `.arb` files.

See [documentation/architecture/localization.md](../documentation/architecture/localization.md).

## Testing

Mirror `lib/` structure under `test/`. Use `mocktail` for mocks, `fake_async` for async tests.

```
test/
├── core/
└── features/
    └── <feature>/
```

Unit-test repositories and notifiers independently. Widget tests for complex UI components.

## Code Generation

After modifying annotated files, always regenerate:

```bash
dart run build_runner build --delete-conflicting-outputs
```

Generated files (`*.g.dart`, `*.freezed.dart`) are committed to the repository.

## After Every Change

After completing any code changes, always:

1. **Format** changed Dart files:
   ```bash
   dart format <changed_file.dart>
   ```
2. **Analyse** the project and fix all errors before finishing:
   ```bash
   dart analyze
   ```

Do not consider a task complete if `dart analyze` reports errors.
