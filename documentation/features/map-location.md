# Aircraft Map Tracking Documentation

This document describes the implementation of the high-performance aircraft tracking system using MapLibre in Flutter.

## 1. GPS & Location Handling

The system uses a tiered approach to location fetching to ensure a smooth user experience regardless of signal quality or permissions.

### Location Sources
- **High-Accuracy GPS**: Used for the aircraft's real-time position. Fetched via `Geolocator`.
- **GeoIP Fallback**: Used ONLY for initial map centering (centering the camera on the user's general area) when GPS is not yet available or permission is denied.

### Providers
- [currentLocationProvider](../../lib/core/services/location_provider.dart): A one-time fetch used for initial map setup.
- [geolocatorStreamProvider](../../lib/core/services/location_provider.dart): A single, persistent `Stream<Position>` from the OS, owned by a keepAlive notifier. Started explicitly via `GeolocatorStream.start()` when the map first needs a fix (permission granted / user enables tracking); never torn down afterwards. `gpsListener` (in `telemetry_provider.dart`) subscribes to it directly and feeds positions into the telemetry. Its state also carries a `GeolocatorStreamStatus` (`GeolocatorStreamOk` / `GeolocatorStreamFailed`), so OS stream failures are observable instead of silently swallowed.

### Failure Handling
- **OS stream failures are exposed**: when the native geolocator stream reports an error, `GeolocatorStream` sets `GeolocatorStreamFailed` (with the error and stack trace) in its state — any UI can watch it to present a "GPS lost" indicator.
- **`gpsListener` handling**: it reads the stable stream once (so status changes never duplicate the subscription) and `ref.listen`s to the status to detect and log failures.
- **Automatic recovery**: after an error the notifier re-subscribes to the OS stream after 5 s; the first delivered position clears the failure status back to `GeolocatorStreamOk`.

### Battery Optimizations
- **No GPS in `init` mode**: The native stream is only started once GPS is actually enabled (explicit `GeolocatorStream.start()` from the GPS toggle / auto-start), so no location permission prompt or background battery drain happens before that.
- **Low-power mode while DroneCAN GPS is active**: `GeolocatorStream.setDroneCanActive(true)` downgrades the phone stream to `lowest` accuracy / 100 km distance filter / 10 s interval (MSL off) whenever a DroneCAN GPS is the active source — its emissions are ignored anyway, so this only saves battery. The high-accuracy mode (`bestForNavigation` / 1 s) is restored automatically 5 s after the last valid DroneCAN fix. Switching restarts are serialised and the old subscription is awaited before re-creating, so the OS stream is never left dead.

## 2. Map View States ([MapViewState](../../lib/features/telemetry/domain/models/map_view_state.dart))

The map operates in four distinct modes, each with specific camera and UI behaviors.

| Mode | Camera Behavior | GPS Usage | Aircraft Icon |
| :--- | :--- | :--- | :--- |
| **`init`** | Configurable via settings (`mapDefaultZoom`) — default 6.0 | GeoIP / Quiet GPS | Hidden |
| **`waitingForGps`** | Static | Active GPS Search | Hidden |
| **`overview`** | Configurable via settings (`mapOverviewZoom`) — default 10.0 | Real-time GPS | Visible & Moving |
| **`follow`** | Configurable via settings (`mapFollowZoom`) — default 12.0 | Real-time GPS | Visible & Centered |

### State Transitions
1. **Startup**: Enters `init`. Centers camera via IP.
2. **Auto-Start**: If GPS permission is already granted, it automatically transitions to `waitingForGps`.
3. **Fix Acquired**: Once a real GPS coordinate is received, state transitions to `overview`.
4. **Manual Toggle**: User can switch between `overview` and `follow` using the GPS button.

## 3. "Follow Mode" Logic

The Follow Mode is designed to be intelligent and non-intrusive.

### Auto-Tracking
In this mode, the camera automatically:
- Centers on the aircraft's latitude/longitude.
- Rotates to match the aircraft's **Heading** (bearing).
- Applies a **Tilt** (pitch) of 60° for a pseudo-3D perspective.
- Adjusts **Zoom** to a configurable level (`mapFollowZoom`, default 12.0).

### Interaction Resume (5s Timer)
If the user manually interacts with the map (pan/zoom/rotate) while in Follow Mode:
1. The automatic tracking is **paused**.
2. A `Timer` is started for **5 seconds**.
3. After 5 seconds of inactivity, the camera **snaps back** to the aircraft and tracking resumes.

### Programmatic Movement Handling
To prevent the map from thinking its own automatic movements are "user interactions," we use an `isMovingProgrammatically` flag inside the [MapCamera](../../lib/features/map/presentation/providers/map_camera_provider.dart) class. This ensures the 5-second timer is only triggered by actual user gestures.

## 4. Platform-Specific Optimizations

### Web Rendering
- **Animation Safety**: Smooth camera animations are disabled during the `init` -> `overview` transition on Web. This prevents a known issue where simultaneous zoom/tilt/rotation changes can result in a temporary black screen.

### Android Stability
- **Texture Mode**: `androidTextureMode` is set to `true` to ensure UI overlays (buttons) remain visible on top of the native map view.
- **Symbol Loading**: The aircraft symbol is initialized explicitly after `onStyleLoaded` to guarantee the icon is rendered reliably on the native layer.

## 5. Safety Features
- **0,0 Filter**: The aircraft symbol GeoJSON is designed to return an empty feature collection if coordinates are `(0, 0)`. This prevents the "phantom aircraft" from appearing off the coast of Africa during initialization.
- **Quiet Permission Checks**: Initial location attempts use `requestPermission: false` to avoid annoying the user with system dialogs until they explicitly request tracking or the app is ready for high-accuracy mode.

## 6. Compass Bar UI & Rendering Workaround

The map screen features a custom horizontal scrolling compass tape ([CompassBar](../../lib/features/map/presentation/components/controls/compass_bar.dart)) that represents the aircraft's current heading.

### High-Contrast Label Outline
To maintain legibility against a variety of map background colors, the cardinal direction labels (N, E, S, W) and degree markers require a high-contrast shadow/outline.

### Flutter Text Shadow Rendering Bug
During fast canvas translations/repaints (e.g., when rotating the device/map), standard Flutter text shadows (`TextStyle(shadows: [...])`) can suffer from a rendering caching bug under hardware acceleration (Skia/Impeller). This bug results in the shadows remaining static/frozen on the screen while the foreground letters move.

To resolve this and ensure perfect visual synchrony, the outline is painted manually:
1. The label is first painted 4 times in the computed shadow/outline color at small diagonal offsets (`-offset`, `+offset` in X and Y directions) scaled by the current font scale factor.
2. The main foreground label is then painted on top at the exact target coordinates.

This manual double-painting approach produces a crisp border/outline around the characters that is guaranteed to animate smoothly without caching artifacts.


## 7. Map Status Indicator

The map shows a small status indicator in the top control row, immediately to
the left of the GPS button
([MapAlertIndicator](../../lib/features/map/presentation/components/controls/map_alert_indicator.dart)).
When every monitored system is healthy it is a quiet, translucent shield. When
something needs attention it grows into a large high-contrast badge — red for
`critical`, amber for `warning`, blue for `info` — with a soft pulsing glow and
an expanding ring for anything that needs action, so the condition is impossible
to overlook in flight. Both light and dark palettes are defined in
`map_alert_indicator.dart`, and the quiet state keeps a 48 dp tap target even
though it looks small. The active states also provide at least 48 dp. The badge
stays active until the condition clears or a more
important condition takes over. The condition itself is not written on the map;
tapping the badge opens the explanation, and the semantics label announces it to
screen readers.

`critical` alerts pulse strongest; `warning` alerts pulse gently; `info` alerts
are static. The pulse is a smooth breathing animation rather than a hard blink,
and it is disabled when the OS accessibility setting "remove animations" is on
(the static badge keeps full contrast).

Only the most important active condition is shown at a time. The most severe
condition wins; conditions of the same severity are ranked by their declaration
order in [map_alert.dart](../../lib/features/map/presentation/models/map_alert.dart),
so a warning can never hide a critical condition and an informational hint can
never hide a warning. A new condition only has to be inserted at the right place
among conditions of equal severity. The declaration order groups: map style, GPS
permission/location services, GPS stream, GPS fix, telemetry link, altitude,
stale telemetry, traffic source, airspace data, terrain, offline maps, DroneCAN
GPS fallback, internet and altitude-source change.

Each signal owns a small provider and [MapAlerts](../../lib/features/map/presentation/providers/map_alerts_provider.dart)
only composes them, tracks how long each condition has been active and drives a
single 1 Hz ticker. The ticker runs for as long as the indicator is mounted,
because a grace period must keep maturing after the event that started it (a
lost link produces no further events); a tick only reads providers and OS
location polling is gated separately, so an idle map stays cheap. Telemetry
packets do not trigger recomputation — the health providers notify only when
their state actually changes. The pure time-based decisions
(`evaluateGpsFixHealth`, `isTelemetryStale`,
`evaluateTrafficSourceUnavailable`, `evaluateTerrainUnavailable`,
`mostImportantAlert`) are unit-tested directly.

Tapping the indicator opens [BaseDetailsDialog](../../lib/features/map/presentation/components/dialogs/base_details_dialog.dart)
with an explanation and start time for each active condition, in priority order.

Signals used by the indicator:

| Condition | Source |
| :--- | :--- |
| GPS permission / services | [LocationAccess](../../lib/core/providers/location_access_provider.dart) (reported while using device GPS, with a 5 s refresh while GPS is requested or an access problem remains) |
| GPS stream failure | `geolocatorStreamProvider.status` (`GeolocatorStreamFailed`, reported while using device GPS) |
| GPS fix lost / no fix | [GpsHealth](../../lib/features/telemetry/presentation/providers/gps_health_provider.dart) reading `TelemetryState.gpsLastFixAt` (12 s stale, 20 s without a first fix) |
| DroneCAN GPS fallback | [GpsHealth](../../lib/features/telemetry/presentation/providers/gps_health_provider.dart) (shown after a device GPS fix arrives within 30 s of losing DroneCAN GPS) |
| Telemetry link / stale data | [TelemetryLinkHealth](../../lib/features/telemetry/presentation/providers/telemetry_link_health_provider.dart) (Cannelloni socket state and received packets, with a 10 s startup grace, 3 s loss confirmation and 20 s stale threshold) |
| Traffic / collision warnings | [TrafficSourceHealth](../../lib/features/telemetry/presentation/providers/traffic_source_health_provider.dart) (OGN socket, successful PureTrack poll within 15 s, GDL90 heartbeat. Loss is reported in flight after a previously available source goes offline and no source recovers within 30 s) |
| Internet | `connectivity_plus` via [NetworkLinkAvailability](../../lib/core/providers/connectivity_provider.dart) — interface-level only (a captive portal still counts as online), reported after a 10 s grace and as `info` because offline flight is normal |
| Airspace activity | `airspaceDataStatusProvider` (failed FIRs; a real fetch failure is more relevant than the missing link) |
| Terrain / altitude | [AltitudeHealth](../../lib/features/telemetry/presentation/providers/altitude_health_provider.dart) on top of `aglProvider` (`terrainElevation`, `AltitudeSource`, 5 s terrain grace) |
| Offline maps | `offlineMapsProvider.hasError` |
