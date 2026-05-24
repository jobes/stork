# Course Line Technical Documentation

This document outlines the technical implementation of the predictive course line (trend vector) feature in the Stork application's map view.

## Overview

The Course Line feature is designed to visualize the aircraft's predicted flight path directly on the MapLibre map. The line is dynamically calculated and drawn to show the exact geographic trajectory the aircraft will cover based on its current heading and speed. 

## Key Components

### 1. Data Source and Telemetry Integration
The calculation relies on live data provided by the `TelemetryState`:
- **Current Position:** `telemetry.latitude` and `telemetry.longitude`.
- **Heading:** `telemetry.heading` (geographic bearing).
- **Speed:** The distance of the projected flight path is primarily based on GPS speed (`telemetry.speed`). If GPS speed is unavailable or reads as zero, the system seamlessly falls back to the indicated airspeed (`telemetry.indicatedAirSpeed`).

The course line is conditionally rendered **only when the aircraft is moving** (`telemetry.isFlying == true`). If the speed drops below the user-defined `inactiveMax` threshold, the line is removed from the map to reduce visual clutter when stationary or taxiing.

### 2. Map Rendering Engine
The drawing logic is handled within the `map_camera_provider.dart`.
The `_getCourseLineGeoJson` method is responsible for generating the line geometry. It recalculates the path whenever a relevant telemetry event (position, speed, or heading change) or settings update occurs, ensuring the trend vector smoothly follows the aircraft's trajectory.

The line is generated as a `GeoJSON` `FeatureCollection` composed of individual `LineString` segments. Each segment is assigned an `"isEven": true/false` property.

#### Layer Composition in MapLibre
A key aeronautical design requirement is alternating black and white segments with a continuous black border. Because MapLibre does not natively support multi-color alternating dash arrays within a single layer property, the visual effect is achieved by superimposing **two distinct map layers**:

1. **`course-line-border` (Base Layer):** A thicker black line (width: 5) drawn across all segments. This provides the continuous black background and creates the visual border for the whole path. It also serves as the solid black fill for even segments.
2. **`course-line-white` (Top Layer):** A thinner white line (width: 3) utilizing a data-driven filter `['==', 'isEven', false]`. This layer renders white only on odd segments. Placed exactly over the base layer, it leaves a 1-pixel black border visible on the edges, perfectly creating the illusion of a white segment with a black outline.

### 3. User Configuration
The feature is deeply integrated with the `AppSettings` module, allowing users to tweak its appearance in real-time without restarting the map:
- **`courseLineSegmentsCount`:** Sets the number of predicted segments (default: 5).
- **`courseLineSegmentDuration`:** Sets the temporal length of each segment in seconds (default: 60 seconds).

Using the default configuration, the map displays a 5-minute prediction of the flight path, clearly divided into 1-minute intervals.

### 4. Geographic Mathematics
The mathematical foundation of the trajectory projection is encapsulated within the `GeoUtils` class (`lib/core/utils/geo_utils.dart`).
Specifically, the `calculateDestination()` method leverages the **Haversine formula** to project destination coordinates across the spherical surface of the Earth (using a mean radius of 6371 km). This guarantees high geographic accuracy, properly accounting for earth curvature over long predictive distances.
