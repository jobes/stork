# Waypoint Navigation System

This document describes the design, models, dynamic telemetry calculations, auto-advance logic, and UI components of Stork's point-to-point waypoint navigation system.

---

## 1. System Overview

Stork allows pilots to define a sequential flight path (route) composed of waypoints. Users can:
- Tap on aeronautical features on the map (such as airports, towns/places, or raw map coordinates) to open a bottom sheet and add points to the route.
- Track real-time progress along the route, showing distance, Estimated Time Enroute (ETE), and Estimated Time of Arrival (ETA) for each segment (leg) and for the overall destination.
- Reorder or delete waypoints on the fly.
- Activate or pause navigation tracking.

---

## 2. Architecture and Data Flow

The navigation feature is split into domain models, data repository, and reactive providers:

```mermaid
graph TD
    Map[Map Screen: Tap Feature] -->|Show Bottom Sheet| BS[MapFeaturesBottomSheet]
    BS -->|addPoint| NP[NavigationNotifier / Riverpod]
    
    NP -->|Save State| Repo[[NavigationRepository](../../lib/features/navigation/data/repositories/navigation_repository.dart)]
    Repo -->|Local Storage JSON| Storage[(Device Storage)]
    
    Tel[TelemetryProvider: Lat/Lon, Speed] -->|Check updates| Adv[[navigationAutoAdvanceProvider](../../lib/features/navigation/presentation/providers/navigation_provider.dart)]
    Adv -->|Auto-remove reached waypoints| NP
    
    NP -->|Re-calculate route| Calc[[NavigationCalculations](../../lib/features/navigation/domain/models/navigation_calculations.dart)]
    Calc -->|Expose calculations| NavUI[NavigationPage & Map Widget]
```

### 2.1. Domain Models
The navigation domain is built on three core classes:

1.  **[NavigationPoint](../../lib/features/navigation/domain/models/navigation_point.dart)**: Represents a single waypoint.
    *   `latitude` and `longitude`: The geographic location.
    *   `name`: The display label (e.g., airport name, ICAO code, place name, or coordinate string).
    *   `isAirport`: Flag identifying if the point is an airport (which shows specific airport icons in list items and menus).
2.  **[NavigationState](../../lib/features/navigation/domain/models/navigation_state.dart)**: The overall state of the navigation.
    *   `points`: The ordered list of active `NavigationPoint`s.
    *   `isActive`: A boolean indicating whether route tracking is active.
3.  **[NavigationLeg](../../lib/features/navigation/domain/models/navigation_leg.dart)**: Represents a segment of the flight route.
    *   `point`: The target waypoint.
    *   `legDistanceMeters`: The distance from the previous point (or aircraft's current location) to this waypoint.
    *   `legDuration`: ETE for this specific leg.
    *   `cumulativeDistanceMeters`: Total distance from the aircraft's current position to this waypoint.
    *   `cumulativeDuration`: Total ETE from the aircraft's current position to this waypoint.
    *   `eta`: Estimated Time of Arrival at this waypoint.

---

## 3. Dynamic Telemetry Calculations

When navigation is active, the system continuously calculates flight parameters via the [NavigationCalculations.calculate](../../lib/features/navigation/domain/models/navigation_calculations.dart) factory constructor.

### 3.1. Speed Source Resolution
The speed used to calculate travel times is resolved dynamically:
- **In-flight (Ground Speed)**: If the aircraft is flying (`telemetry.isFlying == true`) and GPS ground speed is available (`telemetry.groundSpeed != null && telemetry.groundSpeed > 0`), the system uses the real-time ground speed.
- **Pre-flight / Fallback (Average Speed)**: If the aircraft is stationary or GPS speed is unavailable, it falls back to the `averageSpeed` specified in `AppSettings` (default is 100 km/h or 27.78 m/s).

### 3.2. Calculations Sequence
1.  **Start Reference**: The calculations start from the aircraft's current coordinates (`currentLatitude`, `currentLongitude`).
2.  **Geographic Distance**: For each waypoint in the list, the distance from the last reference coordinate is computed using the Haversine formula via `GeoUtils.distanceBetween`.
3.  **Time Estimation (ETE)**:
    $$\text{legSecs} = \frac{\text{distance}}{\text{activeSpeedMs}}$$
4.  **Cumulative Accumulation**:
    *   $$\text{cumulativeDistance} = \sum \text{legDistance}$$
    *   $$\text{cumulativeDuration} = \sum \text{legDuration}$$
5.  **ETA Mapping**:
    $$\text{ETA} = \text{Current DateTime} + \text{cumulativeDuration}$$
6.  **Update reference**: The reference coordinate is updated to the current waypoint, and the loop repeats for the next point.

---

## 4. 60-Second Auto-Advance Logic

To prevent pilots from needing to manually clear waypoints in flight, the application features an automated waypoint advancement loop managed by the [navigationAutoAdvanceProvider](../../lib/features/navigation/presentation/providers/navigation_provider.dart).

### 4.1. Rules & Invariants
- The provider listens to the `telemetryProvider` stream.
- If the current GPS coordinates are valid, the route is active, and there are waypoints remaining, it checks the aircraft's proximity to the nearest waypoint.
- Rather than checking a static geographic radius (which can be missed at high speeds or offset wind angles), Stork checks **temporal proximity**.
- The time to the point is evaluated:
  $$\text{timeToPointSecs} = \frac{\text{accumulatedDistance}}{\text{activeSpeedMs}}$$
- If the travel time to a waypoint is **60.0 seconds or less**, the system triggers an auto-advance.

### 4.2. Batch Removal
If the aircraft flies close to multiple tightly spaced waypoints, the logic determines how many waypoints are within the 60-second window:
```dart
int removeCount = 0;
for (final p in navState.points) {
  accumulatedDistance += p.distanceTo(lastLat, lastLon);
  final timeToPointSecs = accumulatedDistance / activeSpeedMs;
  if (timeToPointSecs <= 60.0) {
    removeCount++;
    lastLat = p.latitude;
    lastLon = p.longitude;
  } else {
    break;
  }
}
```
If `removeCount > 0`, a batch removal is requested.

### 4.3. Concurrency Protection
To prevent overlapping auto-advance operations (since telemetry updates at 10Hz/50Hz, while database writes are asynchronous), the [NavigationNotifier](../../lib/features/navigation/presentation/providers/navigation_provider.dart) maintains an internal `_isAutoAdvancing` guard:
- During the asynchronous write, `_isAutoAdvancing` is set to `true`.
- Any subsequent proximity updates are ignored until the write completes and the state updates.

---

## 5. UI and Layout Integration

The navigation feature is exposed across three main UI views:

### 5.1. Navigation Details Page ([NavigationPage](../../lib/features/navigation/presentation/pages/navigation_page.dart))
Accessing this screen displays:
- **Status Dashboard**: A gradient header summary cards showing total distance, estimated total flight duration, active speed source, and navigation status (Active/Stopped).
- **Control Bar**: A play/stop action button to toggle active routing, and a sweep-delete button to clear the entire path.
- **Reorderable Waypoint Log**: Uses `ReorderableListView.builder` allowing users to drag waypoints to reorder the sequence. Individual waypoints can be deleted, and each list item displays its individual leg statistics alongside cumulative totals and ETAs.

### 5.2. Map Overlay Telemetry Widget ([NavigationTelemetryWidget](../../lib/features/navigation/presentation/widgets/navigation_telemetry_widget.dart))
When navigation is active, a floating overlay card is drawn on the map:
- **Single Waypoint**: Shows a flag icon with the ETE to the destination (e.g. `24 min`).
- **Multiple Waypoints**: Draws a split card:
  - Top segment shows a right arrow icon with the ETE to the **nearest waypoint**.
  - Bottom segment shows a flag icon with the ETE to the **final destination**.
- Tapping the overlay triggers a details dialog.

### 5.3. Navigation Details Dialog ([NavigationDetailsDialog](../../lib/features/navigation/presentation/dialogs/navigation_details_dialog.dart))
A glassmorphic popup containing:
- High-level progress metrics to the nearest waypoint and final destination (with ETAs).
- Active speed label.
- Scrollable list showing the sequence of waypoints, complete with sub-leg distances, durations, and snap ETA timestamps.
