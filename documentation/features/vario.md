# Variometer (Vertical Speed Indicator)

This document describes the variometer implementation used in Stork to compute and display the aircraft's vertical speed (rate of climb / sink).

---

## Overview

The variometer computes vertical speed from two possible sensor sources, with a strict fallback priority:

1. **Barometric pressure (primary)** — converts static air pressure to altitude via the barometric formula, then estimates the vertical speed.
2. **GPS altitude (fallback)** — uses GPS-reported MSL altitude when no pressure sensor is available.

Both paths use the same algorithmic pipeline: **sample buffering → linear regression → EMA output filtering**, with different parameters tuned to each source's noise characteristics.

---

## Algorithm Pipeline

```
Sensor data → Sample buffer → Linear regression → EMA filter → VarioState
```

### 1. Sample Buffer

Raw altitude values (derived from pressure or GPS) are time-tagged and stored in a FIFO ring buffer (`_AltitudeSample`). The buffer holds up to 60 samples — enough to cover the longest regression window with margin.

### 2. Linear Regression (Least-Squares Slope)

At each computation tick, the algorithm selects all samples falling within a sliding time window ending at `now`, then fits a straight line to the `(time, altitude)` pairs using ordinary least squares:

$$t_i = \text{sample time} - t_0 \quad\text{(seconds since first sample)}$$

$$n \sum t_i h_i - \sum t_i \sum h_i \over n \sum t_i^2 - (\sum t_i)^2$$

The slope of the fitted line is the raw vertical speed estimate.

Using multiple samples instead of a simple two-point difference dramatically reduces sensitivity to sensor noise — small random fluctuations cancel out, while the true trend is preserved.

### 3. Exponential Moving Average (EMA) Output Filter

The raw slope from the regression is passed through a first-order IIR low-pass filter (EMA):

$$\alpha = {\Delta t \over \tau + \Delta t}$$

$$v_{\text{filtered}} = (1 - \alpha) \cdot v_{\text{filtered}}^{\text{prev}} + \alpha \cdot v_{\text{raw}}$$

Where:
- $\Delta t$ = time since the last filter update (seconds)
- $\tau$ = time constant (seconds) — larger values = smoother output, more lag

This provides a second layer of smoothing specifically on the displayed output, independent of the regression window.

---

## Pressure-Based Vario (Primary)

| Parameter | Value | Rationale |
|---|---|---|
| Timer interval | 250 ms | Fast enough for 10+ samples in a 3 s window |
| Regression window | 3 s | Good noise rejection with ~0.5 s usable response |
| EMA time constant ($\tau$) | 1.0 s | Smooth but still responsive to thermal changes |
| Max sample gap | 10 s | Guards against stale data after app suspend |

The pressure vario runs on a `Timer.periodic` at 250 ms. On each tick, the current air pressure is read from `TelemetryState`, converted to altitude via `AviationMath.pressureToAltitudeMeters()` (US Standard Atmosphere), and appended to the sample buffer. The regression + EMA computation then runs immediately.

**QNH correction:** The altitude conversion uses the pilot-configured QNH from `appSettingsProvider`, defaulting to 1013.25 hPa.

### Benefits Over Two-Point Difference

The original implementation used a simple two-point difference:

$$v = {h_{\text{now}} - h_{t-\Delta t} \over \Delta t}$$

With $\Delta t = 500\ \text{ms}$, a $\pm 0.5\ \text{m}$ altitude noise spike produces a $\pm 1.0\ \text{m/s}$ vario spike — dominating the real thermal signal ($0.5\text{–}3\ \text{m/s}$). The multi-sample regression inherently averages out such noise.

---

## GPS-Based Vario (Fallback)

When no air pressure is available (`airPressure == null`), the vario falls back to GPS altitude. GPS altitude is inherently noisier ($\pm 3\text{–}10\ \text{m}$ typical), so the parameters are more conservative:

| Parameter | Value | Rationale |
|---|---|---|
| Regression window | 8 s | Longer window averages out GPS altitude noise |
| EMA time constant ($\tau$) | 2.5 s | Heavy filtering to damp remaining noise |
| Computation interval | 1 Hz (throttled) | No benefit from computing faster than GPS update rate |

The GPS vario buffers every incoming telemetry sample but only runs the regression + EMA computation once per second (throttled by `_gpsMinInterval`).

### Activation Conditions

GPS vario activates only when **all** of the following are true:

- `airPressure` is `null`
- `gpsAltitude` is not `null`
- `gpsVerticalAccuracy` is not `null` and $\le$ `maxGpsVerticalAccuracyMeters` (20 m)

---

## Shared EMA State

The `_filteredVario` and `_hasFilteredVario` state are shared between the pressure and GPS paths. This means:

- When switching from pressure to GPS mode (or vice versa), the EMA filter carries over the last filtered value, preventing output jumps.
- The `_lastFilterUpdate` timestamp is shared, so the EMA $\alpha$ calculation remains consistent.

---

## Guard: App Suspend

If the time since the last filter update ($\Delta t$) exceeds 10 seconds (e.g., the app was suspended by the OS), the computation is **skipped** — the filter state is preserved but not updated. This prevents a huge vertical speed spike when the app resumes and a large $\Delta t$ would produce a large $\alpha$ followed by a stale altitude reading.

---

## Display Formatting

In presentation widgets (`VarioTelemetryWidget`, `VarioDetailsDialog`), the vertical speed value is displayed with special handling for near-zero values:

- If `|v| < 0.05` → displayed as `0.0` (no sign)
- Otherwise → displayed as `+x.x` or `-x.x` (sign always shown)

This prevents the confusing `-0.0` or `+0.0` display that results from `toStringAsFixed(1)` rounding small negative values.

---

## Key Files

| File | Role |
|---|---|
| `lib/features/telemetry/presentation/providers/vario_provider.dart` | `VarioNotifier` — all computation logic |
| `lib/features/telemetry/domain/models/vario_state.dart` | `VarioState` — output state model |
| `lib/features/telemetry/presentation/widgets/vario_telemetry_widget.dart` | Map overlay widget |
| `lib/features/telemetry/presentation/dialogs/vario_details_dialog.dart` | Details dialog |
| `lib/core/utils/aviation_math.dart` | `pressureToAltitudeMeters()` utility |
