# Aircraft Map Tracking Documentation

This document describes the implementation of the high-performance aircraft tracking system using MapLibre in Flutter.

## 1. GPS & Location Handling

The system uses a tiered approach to location fetching to ensure a smooth user experience regardless of signal quality or permissions.

### Location Sources
- **High-Accuracy GPS**: Used for the aircraft's real-time position. Fetched via `Geolocator`.
- **GeoIP Fallback**: Used ONLY for initial map centering (centering the camera on the user's general area) when GPS is not yet available or permission is denied.

### Providers
- [currentLocationProvider](../../lib/core/services/location_provider.dart): A one-time fetch used for initial map setup.
- [geolocatorStreamProvider](../../lib/core/services/location_provider.dart): A single, persistent `Stream<Position>` from the OS, owned by a keepAlive notifier. Started explicitly via `GeolocatorStream.start()` when the map first needs a fix (permission granted / user enables tracking); never torn down afterwards. `gpsListener` (in `telemetry_provider.dart`) subscribes to it directly and feeds positions into the telemetry.

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

