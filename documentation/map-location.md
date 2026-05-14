# Aircraft Map Tracking Documentation

This document describes the implementation of the high-performance aircraft tracking system using MapLibre in Flutter.

## 1. GPS & Location Handling

The system uses a tiered approach to location fetching to ensure a smooth user experience regardless of signal quality or permissions.

### Location Sources
- **High-Accuracy GPS**: Used for the aircraft's real-time position. Fetched via `Geolocator`.
- **GeoIP Fallback**: Used ONLY for initial map centering (centering the camera on the user's general area) when GPS is not yet available or permission is denied.

### Providers
- `currentLocationProvider`: A one-time fetch used for initial map setup.
- `positionStreamProvider`: A continuous `StreamProvider` that listens for GPS updates. 
    - **Optimization**: It remains idle in `init` mode to prevent unnecessary permission prompts or background battery drain.

## 2. Map View States (`MapViewState`)

The map operates in four distinct modes, each with specific camera and UI behaviors.

| Mode | Camera Behavior | GPS Usage | Aircraft Icon |
| :--- | :--- | :--- | :--- |
| **`init`** | Static (Zoom 2-6) | GeoIP / Quiet GPS | Hidden |
| **`waitingForGps`** | Static | Active GPS Search | Hidden |
| **`overview`** | Static (North-up) | Real-time GPS | Visible & Moving |
| **`follow`** | Tracking | Real-time GPS | Visible & Centered |

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

### Interaction Resume (5s Timer)
If the user manually interacts with the map (pan/zoom/rotate) while in Follow Mode:
1. The automatic tracking is **paused**.
2. A `Timer` is started for **5 seconds**.
3. After 5 seconds of inactivity, the camera **snaps back** to the aircraft and tracking resumes.

### Programmatic Movement Handling
To prevent the map from thinking its own automatic movements are "user interactions," we use an `_isMovingProgrammatically` flag. This ensures the 5-second timer is only triggered by actual user gestures.

## 4. Platform-Specific Optimizations

### Web Rendering
- **Animation Safety**: Smooth camera animations are disabled during the `init` -> `overview` transition on Web. This prevents a known issue where simultaneous zoom/tilt/rotation changes can result in a temporary black screen.

### Android Stability
- **Texture Mode**: `androidTextureMode` is set to `true` to ensure UI overlays (buttons) remain visible on top of the native map view.
- **Symbol Loading**: The aircraft symbol is initialized explicitly after `onStyleLoaded` to guarantee the icon is rendered reliably on the native layer.

## 5. Safety Features
- **0,0 Filter**: The aircraft symbol GeoJSON is designed to return an empty feature collection if coordinates are `(0, 0)`. This prevents the "phantom aircraft" from appearing off the coast of Africa during initialization.
- **Quiet Permission Checks**: Initial location attempts use `requestPermission: false` to avoid annoying the user with system dialogs until they explicitly request tracking or the app is ready for high-accuracy mode.
