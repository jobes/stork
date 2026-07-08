# Airspeed Telemetry

This document describes the design, implementation, and visualization of indicated airspeed (IAS) telemetry within the Stork application.

---

## 1. Overview

The Airspeed Telemetry feature receives real-time indicated airspeed data from a pitot-static system via the DroneCAN CAN bus. The data is transmitted over UDP/IP using the Cannelloni protocol, parsed by the native C `libcanard` wrapper, and propagated to the reactive telemetry state for display on the map overlay.

---

## 2. DroneCAN Message: `IndicatedAirspeed`

### 2.1. DSDL Definition

The message `uavcan.equipment.air_data.IndicatedAirspeed` (ID `1021`) is defined in the standard DroneCAN namespace:

```
float16 indicated_airspeed              # m/s
float16 indicated_airspeed_variance     # (m/s)^2
```

| Field | Type | Unit | Description |
|-------|------|------|-------------|
| `indicated_airspeed` | `float16` | m/s | Indicated airspeed (IAS) from the pitot-static system |
| `indicated_airspeed_variance` | `float16` | (m/s)² | Variance estimate of the airspeed measurement |

### 2.2. Parser Implementation

The parser is implemented in [IndicatedAirspeed](../../lib/core/native/dronecan/indicated_airspeed.dart) — a Dart class implementing the `DroneCanMessage` interface:

- **Message ID**: `1021`
- **Signature**: `0x0A1892D72AB8945F`
- **Payload**: 4 bytes (2 × float16 half-precision IEEE 754)

```dart
factory IndicatedAirspeed.fromPayload(Uint8List payload) {
  final reader = BitReader(payload);
  final ias = reader.readFloat16();
  final variance = reader.readFloat16();
  return IndicatedAirspeed(
    indicatedAirspeed: ias,
    indicatedAirspeedVariance: variance,
  );
}
```

The payload is deserialised using the existing `BitReader` utility which handles IEEE 754 half-precision float (float16) decoding via its `readFloat16()` method, implemented using the `canardConvertFloat16ToNativeFloat` C function from `libcanard`.

### 2.3. Message Parsing Flow

```
CAN Bus → Cannelloni Bridge → UDP/IP → CannelloniService
    → stork_canard.c (libcanard) → Transfer Callback (Dart FFI)
    → IndicatedAirspeed.fromPayload() → TelemetryNotifier.updateAirSpeed()
```

1. The native C layer (`stork_canard.c`) reassembles multi-frame DroneCAN transfers and invokes the Dart transfer callback.
2. The `_storkCanardTransferCallback` in [CannelloniService](../../lib/core/services/cannelloni_service_io.dart) matches `dataTypeId == 1021` and calls `IndicatedAirspeed.fromPayload()`.
3. The parsed `indicatedAirspeed` value is forwarded to `TelemetryNotifier.updateAirSpeed()`.

---

## 3. Telemetry Processing & Decay Safety

### 3.1. Reactive State Updates

The [TelemetryNotifier](../../lib/features/telemetry/presentation/providers/telemetry_provider.dart) wraps `indicatedAirSpeed` in a `DecayableField<double>`:

```dart
late final DecayableField<double> _indicatedAirSpeed = DecayableField<double>(
  onChanged: (val) {
    state = val == null
        ? state.resetField(TelemetryField.indicatedAirSpeed)
        : state.copyWith(indicatedAirSpeed: TelemetryValue(val));
    _updateIsFlying();
  },
);
```

### 3.2. Decay Timeout

| Parameter | Timeout | Safety Rationale |
| :--- | :--- | :--- |
| **`indicatedAirSpeed`** | 1 second | Critical flight dynamic data; must expire immediately if lost. |

If no `IndicatedAirspeed` DroneCAN message is received within 1 second, the field value automatically decays to `null`, preventing the display of stale airspeed data.

### 3.3. Is-Flying Detection

When `indicatedAirSpeed` is updated, `TelemetryNotifier._updateIsFlying()` is called. This derives the aircraft's flight status by comparing both `indicatedAirSpeed` and `groundSpeed` against configurable thresholds — IAS contributes to detecting flight even when GPS ground speed is unavailable (e.g., when stationary on ground with engine running).

### 3.4. Fallback Behaviour

In the map's geojson course line builder ([GeojsonBuilder](../../lib/features/map/utils/geojson_builder.dart)), IAS serves as a fallback for GPS ground speed:

```dart
final speedMS = telemetry.groundSpeed ?? telemetry.indicatedAirSpeed ?? 0.0;
```

This ensures the projected course line remains meaningful even during GPS dropouts.

---

## 4. Visualization

### 4.1. Speed Telemetry Widget

The [SpeedTelemetryWidget](../../lib/features/telemetry/presentation/widgets/speed_telemetry_widget.dart) displays the current indicated airspeed on the map overlay. It uses `telemetryProvider.select((t) => t.indicatedAirSpeed)` for efficient reactive rebuilds.

The widget is draggable by the user (wrapped in `DraggableWidget` via `MapWidgetWrapper`).

### 4.2. Speed Details Dialog

The [SpeedDetailsDialog](../../lib/features/telemetry/presentation/components/speed_details_dialog.dart) provides a detailed view of all speed-related telemetry, including IAS, ground speed, and derived information. It uses the `BaseDetailsDialog` component for consistent frosted-glass styling.

### 4.3. Unit Conversion

Speed values are converted from m/s (SI, as received from DroneCAN) to the user's preferred unit (km/h, kts, or mph) via `AppSettings.speedUnit` in the presentation layer:

| Unit | Conversion | Use Case |
| :--- | :--- | :--- |
| **m/s** | — | Internal SI representation |
| **km/h** | × 3.6 | European aviation, road vehicles |
| **kts** | × 1.94384 | International aviation standard |
| **mph** | × 2.23694 | General aviation in some regions |

---

## 5. Testing

Parser unit tests (if present) are located in [test/core/native/dronecan](../../test/core/native/dronecan). The `IndicatedAirspeed.fromPayload()` method can be unit-tested with known byte sequences representing half-precision float16 values:

```dart
// Example: 1.0 m/s IAS, 0.0 variance
// float16(1.0) = 0b0011110000000000 = 0x3C00
// float16(0.0) = 0b0000000000000000 = 0x0000
// Payload (little-endian): [0x00, 0x3C, 0x00, 0x00]
final msg = IndicatedAirspeed.fromPayload(Uint8List([0x00, 0x3C, 0x00, 0x00]));
expect(msg.indicatedAirspeed, closeTo(1.0, 0.01));
```

---

## 6. Related Documentation

- [Telemetry and Network Architecture](../architecture/telemetry-architecture.md) — CAN-over-IP pipeline, Cannelloni service, decay safety
- [Course Line (Trend Vector)](course-line.md) — Course line projection using IAS as ground speed fallback
- [Engine Telemetry and Health Monitoring](engine-telemetry.md) — Related DroneCAN ICE telemetry
