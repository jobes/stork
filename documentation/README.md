# Stork Technical Documentation Index

Welcome to the technical documentation for **Stork**, a high-performance aeronautical navigation application. This index organizes the documentation files by category to help developers and maintainers understand the system architecture and features.

---

## 🏛️ System Architecture

Documents in this section cover the core infrastructure, networking protocols, hardware integration, and mathematical systems that power the application.

*   [Telemetry and Network Architecture](architecture/telemetry-architecture.md)
    *   *Details the CAN-over-IP telemetry pipeline using the Cannelloni UDP protocol, Multicast DNS (mDNS) service discovery, Dynamic Node ID Allocation (DNA), native C bindings (`libcanard`), Telemetry State decay safety, and DroneCAN service request/response pattern for VHF radio control.*
*   [Altitude Resolution and Terrain Elevation](architecture/altitude-resolution-and-terrain.md)
    *   *Outlines how altitude is dynamically resolved from multiple physical/virtual sources, Web Mercator projection mechanics for zoom level 12 terrain tiles, Mapzen Terrarium PNG decoding, bilinear interpolation, LRU tile caching, and ground/in-flight Auto-QNH calibration (via a 2D Extended Kalman Filter).*
*   [Local Data Storage and Database Architecture](architecture/local-data-storage.md)
    *   *Covers the SQLite database schema (offline regions, map tiles, and OpenAIP metadata), indexing optimizations, batch transaction management, and conditional platform support (native SQLite vs Web stubs).*
*   [Localization and Internationalization](architecture/localization.md)
    *   *Describes the application resource bundle (`.arb`) setup and code generation for multi-language support.*

---

## 🚀 Key Features

Documents in this section detail user-facing features, overlay widgets, custom canvas painting, and reactive states.

*   [Waypoint Navigation System](features/navigation.md)
    *   *Explains how waypoint-based routing works, including dynamic ETA/ETE calculations, custom path legs, reorderable lists, manual controls, and the auto-advance logic that moves to the next waypoint when travel time is $\le 60.0$ seconds.*
*   [Flight Duration and Distance Tracking](features/flight-duration-tracking.md)
    *   *Describes block-time telemetry tracking which automatically detects takeoff and landing, accumulates flight distances using geographic mathematics while filtering out GPS noise, and exposes the time/distance readouts via dedicated widgets.*
*   [Black Box Flight Logging and GPX Export](features/black-box-logging.md)
    *   *Details the automated flight recording system, delta-compressed sqlite persistence, background isolate-based statistics computation, crash recovery procedures, and GPX track exporter.*
*   [Course Line (Trend Vector)](features/course-line.md)
    *   *Covers the predictive course line rendering utilizing layered MapLibre sources (black/white dashes with black border outline) to project the aircraft's future trajectory based on speed, heading, and settings configurations.*
*   [Customizable Widgets and Layouts](features/customizable-widgets-layout.md)
    *   *Details the draggable/resizable overlay widgets, viewport metrics updates, the speed alarm range boundaries model, multi-thumb thresholds slider painting, and settings navigation.*
*   [Aircraft Map Tracking and Location States](features/map-location.md)
    *   *Explains Geolocator GPS integration, GeoIP fallbacks, map state transitions (`init`, `waitingForGps`, `overview`, `follow`), follow-mode snapping with user interaction delay timers, and platform-specific rendering optimizations (Android/Web).*
*   [Offline Maps Base](features/offline-maps.md)
    *   *Describes the offline-first architecture with PMTiles, tile local caching proxies using an embedded local HTTP server, dynamic MapLibre style rewriting, and openAIP country-based metadata fetching/syncing.*
*   [Aeronautical Metadata and Map Interaction](features/aeronautical-metadata.md)
    *   *Explains how OpenAIP airport and airspace metadata is synchronized, cached in the local SQLite database, queried on map tap coordinates, and presented in the interactive details dialogs.*
*   [NOTAM (Notice to Airmen) Alerts](features/notams.md)
    *   *Describes how NOTAMs are fetched from the FAA API, decoded and expanded from contractions to English, managed through performance-optimized Riverpod providers, rendered as map layers with mathematical circle polygon projection, and controlled with user hide mechanisms.*
*   [Settings and Configuration](features/settings.md)
    *   *Details the settings architecture, encompassing the domain models (units, range thresholds, cannelloni devices) and the modular user interface.*
*   [Pilot and Aircraft Management](features/pilot-and-aircraft-management.md)
    *   *Covers pilot and aircraft profile structures, CRUD repositories, JSON-based persistence, SQL time-based statistics calculations, optional PIN security, and dashboard integration.*
*   [Engine Telemetry and Health Monitoring](features/engine-telemetry.md)
    *   *Details DroneCAN-based ICE (Internal Combustion Engine) monitoring, including RPM, fuel tank status, oil pressure/temperature, CHT, EGT, dynamic overlay widgets, custom segmented gauges, and threshold alarm logic.*
*   [VHF Radio Control and Monitoring](features/vhf-radio.md)
*   [Variometer (Vertical Speed Indicator)](features/vario.md)
    *   *Documents the barometric and GPS-based vertical speed estimation pipeline with linear regression smoothing, EMA output filtering, and the fallback logic between pressure and GPS sources. Covers noise rejection strategy, display formatting, and all tunable parameters.*
    *   *Describes the VHF radio DroneCAN protocol (FastStatus, FullStatus, Control service), the interactive radio control dialog with quick/advanced modes, the map overlay telemetry widget, nearby frequency discovery, and persistent favorite frequencies management.*

