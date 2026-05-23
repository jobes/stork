# Customizable Overlay Widgets & Layout Architecture

This document describes the design and implementation of Stork's customizable overlay widget system, the generic draggable layout architecture, and the integrated speed telemetry alerts system with its multi-thumb threshold slider.

---

## 1. Generic Customizable Layout Architecture

To allow pilots and operators to tailor their telemetry dashboards, Stork features a **Customizable Overlay Widget System** implemented on top of the map view. Widgets are positioned as dynamic floaters that can be toggled into an interactive edit mode, dragged around the screen, and saved persistently.

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant DW as DraggableWidget
    participant MWW as MapWidgetWrapper
    participant ASN as AppSettingsNotifier
    participant SR as SettingsRepository
    participant Map as MapPage

    User->>DW: Pan Gesture (Drag Widget)
    DW->>DW: Local Bounds Clamping
    User->>DW: Release Drag (onPanEnd)
    DW->>MWW: onDragEnd(top, left)
    MWW->>ASN: updateWidgetPosition(widgetId, top, left)
    ASN->>SR: saveSettings(newSettings)
    SR-->>ASN: Persistent SharedPreferences Write
    ASN-->>MWW: State Stream Emits Update
    MWW-->>DW: Pass new constrained coordinates
    DW->>Map: Re-render at new location
```

### Component Structure

The architecture is divided into three layers to ensure separation of concerns:

1. **`DraggableWidget` (Presentation/Interaction)**
   - A standalone `StatefulWidget` managing touch gestures and physical viewport constraints.
   - It intercepts pan movements using `GestureDetector` and calculates pixel-based coordinate shifts.
   - Provides a premium visual indicator (moving scale effect, subtle opacity decay, and an edit-mode border with a multi-directional arrow icon) when the edit mode is active.

2. **`MapWidgetWrapper` (State Integration)**
   - A generic glue widget that acts as an adapter. It watches Riverpod's `appSettingsProvider` to determine:
     - Whether edit/move mode is active (`areWidgetsDraggable`).
     - The stored coordinates for its unique `widgetId`.
   - When a drag completes, it calls the `AppSettingsNotifier` to persist the new coordinates.

3. **`AppSettings` & Persistence (Domain/Data)**
   - Coordinates are modeled in `WidgetPosition` (containing double `top` and `left`).
   - The settings state contains `widgetPositions` modeled as a `Map<String, WidgetPosition>`, enabling an infinite number of independent overlay widgets to coexist.
   - The settings are automatically serialized to JSON and persisted locally.

---

## 2. Gesture Handling & Resizing Safety

Dragging elements on dynamic mobile viewports requires robust edge cases handling (e.g., orientation changes, screen resizing, and touch boundaries). Stork handles these issues with three layer-checks:

### Real-Time Local Clamping
During an active drag (`onPanUpdate`), positions are constrained instantly based on the widget's render dimensions and `MediaQuery` boundaries. This prevents the widget from sliding off-screen or disappearing under system status bars:
```dart
if (_left < 0) _left = 0;
if (_top < 0) _top = 0;
if (_left + size.width > screenSize.width) {
  _left = screenSize.width - size.width;
}
if (_top + size.height > screenSize.height) {
  _top = screenSize.height - size.height;
}
```

### Post-Frame Snap Correction
Since rendering sizes might not be fully initialized or may change dynamically, Stork registers a post-frame callback (`WidgetsBinding.instance.addPostFrameCallback`) after constraint updates to snap the widget safely back within the viewport boundaries and trigger a persistence update if boundaries were violated.

### Viewport Metrics Listener
`DraggableWidget` observes `WidgetsBindingObserver` and listens to `didChangeMetrics()`. When a screen rotation or device resizing occurs:
1. Active dragging coordinates are flagged as invalid.
2. Viewport dimensions are queried anew.
3. Coordinates are automatically re-clamped to fit the new viewport limits.
4. If edit mode is disabled, widgets snap back to their stored positions to prevent drifting.

---

## 3. Built-in Implementation: Telemetry & Alert States

The primary built-in implementation of this customizable system is the `SpeedTelemetryWidget`. However, the underlying domain logic (`ThresholdState` and `RangeThresholds`) is completely generic and designed to be reused for any scalar telemetry metric (e.g., engine temperature, battery voltage).

### Dynamic Connection States
The widget automatically adapts its interface depending on network status (`isConnected` from `cannelloniServiceProvider`) and GPS availability:

| Connection State | Primary Value | Subtitle/Label | Visual Badge |
| :--- | :--- | :--- | :--- |
| **Offline Mode** | Ground Speed (GS) | `"---"` (if missing) | *None* |
| **Connected (Both IAS & GS)** | Indicated Airspeed (IAS) | Ground Speed (GS) in km/h | *None* |
| **Connected (GS only)** | Ground Speed (GS) | GPS Speed | `"GPS ONLY"` (Yellow badge) |
| **Connected (IAS only)** | Indicated Airspeed (IAS) | no GPS signal | `"NO GPS"` (Red badge + satellite icon) |
| **Neither Available** | `"---"` | `"---"` | *None* |

### Alert Evaluation Logic
Avionics parameters need highly visible alerts when crossing critical boundaries. Telemetry metrics are evaluated into up to six generic `ThresholdState` alert regions. Because the boundaries are optional, states that don't apply to a specific metric (e.g. `inactive` for engine temperature) are simply omitted.

```dart
enum ThresholdState {
  inactive,       // Standby / speed below minimum noise floor
  minError,       // Dangerous stall condition (dangerously slow)
  minWarning,     // Approaching stall boundary
  operational,   // Safe flight envelope
  maxWarning,     // Overspeed caution
  maxError,       // Dangerous structural overspeed limits
}
```

```mermaid
grid-chart
    title Alert State Evaluation Mapping
    [0.0 to inactiveMax] : "inactive"
    [inactiveMax to minError] : "minError"
    [minError to minWarning] : "minWarning"
    [minWarning to maxWarning] : "operational"
    [maxWarning to maxError] : "maxWarning"
    [maxError to maxRange] : "maxError"
```

### Alert Aesthetics & Micro-Animations
To notify pilots without cluttering the screen, state changes animate smoothly (300ms transitions):
- **Glassmorphism**: Built using a nested `BackdropFilter` with `sigmaX: 10, sigmaY: 10` and light/dark variable translucent alphas.
- **Dynamic Shadows & Glows**: Active warnings or errors render intense glowing backlights based on the `ThresholdStateExtension` color mapping (e.g., orange glow for warnings, red glow for errors).
- **Constant Borders**: The border changes color between warning stages based on `ThresholdStateExtension`, but maintains a **constant width (2.0px)**. This prevents layout shifting and screen jittering when moving between thresholds.

---

## 4. Range Thresholds Safety & Boundary Assertions

To guarantee mathematical consistency in safety settings (e.g., warning levels cannot be set higher than error levels), the `RangeThresholds` domain model enforces strict invariants at runtime.

### Boundary Constraints
Instead of relying on compile-time Freezed `@Assert` annotations, `RangeThresholds` validation is performed in the custom factory constructor `RangeThresholds(...)`. If the provided thresholds are out of order, the factory throws an `ArgumentError`.

Specifically, the validation ensures that safety thresholds are logically sorted:
- `minError` <= `minWarning` (minError vs minWarning)
- `maxWarning` <= `maxError` (maxWarning vs maxError)
- `minError` <= `maxError` (minError vs maxError)
- `inactiveMax` <= `minError` (inactiveMax vs minError)

Example validation checks within the factory constructor:
```dart
if (minError != null && minWarning != null && minError > minWarning) {
  throw ArgumentError('minWarning cannot be less than minError');
}
if (inactiveMax != null && minError != null && inactiveMax > minError) {
  throw ArgumentError('inactiveMax cannot be greater than minError');
}
```

For the complete list of validation conditions and exact error messages, please refer directly to the factory implementation in [range_thresholds.dart](file:///home/vjoba/Develop/stork/lib/features/settings/domain/range_thresholds.dart).

### Settings Clamping and Cascading Sanitization
When the maximum slider scale (`flightSpeedMaxRange`) is updated, the `AppSettingsNotifier` performs a cascading clamping routine to sanitize all warning boundaries automatically. This prevents any out-of-bounds assertions from throwing runtime exceptions:

```dart
final newMaxError = (thresholds.maxError ?? 125.0).clamp(0.0, normalizedMaxRange).roundToDouble();
final newMaxWarning = (thresholds.maxWarning ?? 110.0).clamp(0.0, newMaxError).roundToDouble();
final newMinWarning = (thresholds.minWarning ?? 75.0).clamp(0.0, newMaxWarning).roundToDouble();
final newMinError = (thresholds.minError ?? 60.0).clamp(0.0, newMinWarning).roundToDouble();
final newInactiveMax = (thresholds.inactiveMax ?? 10.0).clamp(0.0, newMinError).roundToDouble();
```

---

## 5. ThresholdsSlider & Custom Painting

The boundaries are configured in settings using a custom-engineered **`ThresholdsSlider`** component. Because native Flutter sliders only support single or double-range inputs, Stork utilizes a custom multi-thumb paint widget.

### Touch Interception & Stacked Dragging Logic
The slider receives a `List<double>` representing the thumbs and an `evaluate` function to dynamically determine the track colors. It manages user interactions using a `GestureDetector`:
1. **Pan Start (`onPanStart`)**: Translates the touch point `dx` into a fraction of the slider's track width. It finds the closest thumb to the touch event.
2. **Pan Update (`onPanUpdate` & Dynamic Transfer)**: Modifies the value of the active thumb. A critical UX challenge with range sliders is when multiple thumbs overlap (stack). Stork solves this seamlessly:
   - Instead of strictly clamping the thumb and trapping it, Stork analyzes the drag direction.
   - If dragging right while stacked, it dynamically transfers the `_activeThumbIndex` to the rightmost thumb in the overlapping group.
   - If dragging left, it transfers control to the leftmost thumb.
   - This allows users to intuitively "push" neighboring thumbs or separate overlapping thumbs without getting stuck.
3. **Pan End (`onPanEnd`)**: Releases the active thumb selection and updates persistent settings.

### Visual Representation (`_MultiThumbPainter`)
The custom painter dynamically renders the track as variable-sized color blocks representing the safety regions:

- **Dynamic Region Colors**: Instead of a hardcoded color array, the painter samples the midpoint of each segment and calls the provided `evaluate()` function to determine the correct color using `ThresholdStateExtension`. This allows the slider to support 4 thumbs, 5 thumbs, or any generic number.
- **Overlapping Prevention**: Text labels for the 5 thumbs alternate above and below the slider bar (even index thumbs draw text above the track, odd index thumbs draw text below). This keeps values readable even when thresholds are closely configured.
- **Active Glow Paint**: The active thumb increases in radius (from `10.0px` to `14.0px`) and switches text to bold to provide micro-interaction feedback.

---

## 6. Split Settings Page Navigation

To accommodate the growing configuration settings without cluttering the screen, the settings panel has been reorganized. The central `SettingsPage` now acts as a high-level list routing to three specialized sub-panels:

```mermaid
graph TD
    A[SettingsPage] --> B[GatewaySettingsPage]
    A --> C[MapSettingsPage]
    A --> D[FlightSettingsPage]

    B --> B1[Auto-select toggle]
    B --> B2[Device dropdown selector]

    C --> C1[Font size slider]
    C --> C2[Default zoom level]
    C --> C3[Overview zoom level]
    C --> C4[Follow mode zoom level]
    C --> C5[Widgets Draggable toggle]
    C --> C6[Reset Layout button]

    D --> D1[ThresholdsSlider limit editor]
    D --> D2[Help modal legend overlay]
    D --> D3[NumberInput max range editor]
```

---

## 7. Performance & Stability Considerations

- **Selective Riverpod Watches**: In `MapWidgetWrapper`, rather than watching the entire `appSettingsProvider` which would rebuild the widget on any change (e.g. font sizes, IP settings), we select only the specific fields required:
  ```dart
  final isDraggable = ref.watch(appSettingsProvider.select((s) => s.value?.areWidgetsDraggable ?? false));
  final position = ref.watch(appSettingsProvider.select((s) => s.value?.widgetPositions[widgetId]));
  ```
- **Clamped Repaint Boundaries**: The custom thresholds painter implements `shouldRepaint` strictly to prevent redundant CPU cycles during general page scrolling:
  ```dart
  @override
  bool shouldRepaint(covariant _MultiThumbPainter oldDelegate) {
    return !listEquals(oldDelegate.values, values) ||
        oldDelegate.evaluate != evaluate ||
        oldDelegate.activeThumbIndex != activeThumbIndex;
  }
  ```
- **Immersive Mode Stability**: While dragging or rendering customizable widgets, `SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky)` keeps system task bars hidden, ensuring the interactive drag bounding boxes align perfectly with physical glass dimensions.
