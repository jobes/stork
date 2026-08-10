# Stork

[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](LICENSE)

**Stork** is a high-performance aeronautical navigation (EFB) application for glider and aircraft pilots, built with Flutter. It combines offline vector mapping, real-time DroneCAN telemetry over CAN-over-IP, and live aeronautical data into a single cockpit tool. Stork targets **Android, iOS, Linux, macOS, Windows, and Web**.

## 🚀 Key Features

**Mapping & Navigation**
- **Vector Map Visualization** — seamless MapLibre-powered map with dynamic vector styles and sprites.
- **Offline Maps (PMTiles)** — offline-first mapping with PMTiles, a local HTTP tile server, and a reliable background download system with progress tracking and fault tolerance.
- **Aircraft Map Tracking** — Geolocator GPS integration with GeoIP fallbacks and map states (`init`, `waitingForGps`, `overview`, `follow`) with follow-mode snapping.
- **Course Line (Trend Vector)** — predictive course-line overlay projecting the aircraft's future trajectory.
- **Waypoint Navigation** — waypoint-based routing with dynamic ETA/ETE, reorderable legs, and auto-advance logic.

**Telemetry & Avionics**
- **DroneCAN Telemetry** — CAN-over-IP pipeline using the Cannelloni UDP protocol, mDNS service discovery, and dynamic node ID allocation (DNA), with native FFI bindings to `libcanard`.
- **VHF Radio Control & Monitoring** — DroneCAN radio protocol with an interactive control dialog, map overlay widget, and favorite frequency management.
- **Engine & Airspeed Telemetry** — ICE monitoring (RPM, fuel, oil pressure/temperature, CHT, EGT) with segmented gauges and threshold alarms, plus DroneCAN IndicatedAirspeed (IAS) decoding.
- **Variometer (VSI)** — barometric and GPS-based vertical speed estimation with linear-regression smoothing and EMA filtering.
- **Multi-Source Traffic** — live traffic aggregation from Open Glider Network (OGN), PureTrack SSE/WebSocket, and local GDL90 receivers (SafeSky/Stratux/SkyEcho 2).
- **Collision Avoidance System (CAS)** — 3D threat-volume evaluation with kinematic position prediction and thermal co-circling suppression.

**Flight Data & Aeronautical Information**
- **Black Box Flight Logging** — automated flight recording, delta-compressed SQLite persistence, background statistics, crash recovery, and GPX export.
- **Flight Duration & Distance Tracking** — automatic takeoff/landing detection and GPS-noise-filtered distance accumulation.
- **Active Airspaces (AUP/UUP)** — real-time airspace activity from Slovak LzPS and Czech ŘLP AUP portals with MapLibre highlight layers.
- **NOTAM Alerts** — NOTAMs fetched from the FAA API, decoded and expanded to English, rendered as map layers.
- **Aeronautical Metadata** — OpenAIP airport/airspace synchronization, cached in SQLite, queried on map tap.
- **Pilot & Aircraft Management** — pilot/aircraft profiles with JSON persistence, PIN security, and dashboard integration.
- **Altitude Resolution & Terrain Elevation** — Web Mercator terrain tiles with bilinear interpolation, LRU caching, and Auto-QNH calibration via a 2D Extended Kalman Filter.

**UX & Platform**
- **Customizable Widgets & Layouts** — draggable/resizable overlay widgets and map telemetry overlays.
- **Multi-language Support** — English and Slovak.
- **Cross-platform** — Android, iOS, Linux, macOS, Windows, and Web.

## 🛠️ Tech Stack

- **Framework**: [Flutter](https://flutter.dev)
- **State Management**: [Riverpod](https://riverpod.dev) with code generation (`riverpod_generator`)
- **Models**: [Freezed](https://pub.dev/packages/freezed) / [json_serializable](https://pub.dev/packages/json_serializable)
- **Navigation**: [GoRouter](https://pub.dev/packages/go_router)
- **Database**: [SQLite](https://pub.dev/packages/sqlite3) (via `sqlite3`), [SharedPreferences](https://pub.dev/packages/shared_preferences)
- **Maps**: [MapLibre](https://pub.dev/packages/maplibre), [PMTiles](https://pub.dev/packages/pmtiles), [vector_tile](https://pub.dev/packages/vector_tile)
- **Networking**: [http](https://pub.dev/packages/http), [flutter_dotenv](https://pub.dev/packages/flutter_dotenv), [multicast_dns](https://pub.dev/packages/multicast_dns)
- **Native**: FFI bindings to [libcanard](https://github.com/DroneCAN/libcanard) (DroneCAN), [ffi](https://pub.dev/packages/ffi)
- **Device**: [geolocator](https://pub.dev/packages/geolocator), [sensors_plus](https://pub.dev/packages/sensors_plus), [wakelock_plus](https://pub.dev/packages/wakelock_plus), [package_info_plus](https://pub.dev/packages/package_info_plus), [url_launcher](https://pub.dev/packages/url_launcher), [share_plus](https://pub.dev/packages/share_plus)
- **Testing**: [mocktail](https://pub.dev/packages/mocktail), [fake_async](https://pub.dev/packages/fake_async)

## 📚 Technical Documentation

Detailed technical documentation covering the system architecture, mathematical equations, and key features can be found in the [documentation](documentation/README.md) directory. Topics include the [telemetry & network architecture](documentation/architecture/telemetry-architecture.md), [altitude resolution & terrain](documentation/architecture/altitude-resolution-and-terrain.md), [local data storage](documentation/architecture/local-data-storage.md), and feature deep-dives (navigation, traffic, CAS, vario, VHF radio, black-box logging, and more).

## ⚙️ Getting Started

### Prerequisites

- Flutter SDK (latest stable version recommended)
- Android Studio / VS Code with Flutter extensions
- A C toolchain (for the native `libcanard` FFI bindings)

### Environment Setup

1.  **Environment Variables**: Create a `.env` file in the root directory (you can use `.env.example` as a template):
    ```bash
    cp .env.example .env
    ```
2.  **API Keys**: Set your keys in the `.env` file. `OPENAIP_API_KEY` is required for aeronautical data and map styles; `PURETRACK_KEY` enables the PureTrack traffic feed.
    ```env
    OPENAIP_API_KEY=your_key_here
    PURETRACK_KEY=your_puretrack_key_here
    ```

### Native Dependencies

This project uses `libcanard` as a Git submodule for parsing DroneCAN CAN frames via the Cannelloni bridge. When cloning the repository for the first time, you must initialize the submodules:
```bash
git submodule update --init --recursive
```

### Installation & Running

1.  **Fetch dependencies**:
    ```bash
    flutter pub get
    ```
2.  **Generate code** (for Riverpod, Freezed, and other generators):
    ```bash
    dart run build_runner build --delete-conflicting-outputs
    ```
3.  **Run the application**:
    ```bash
    flutter run
    ```

## 📂 Project Structure

The project follows **Clean Architecture with Riverpod**, strictly three layers per feature: `data` → `domain` → `presentation`.

```text
lib/
├── core/                    # Shared infrastructure (router, theme, services, native, providers)
│   ├── native/              # FFI bindings to libcanard (DroneCAN)
│   ├── router/              # GoRouter configuration
│   ├── services/            # Cannelloni, mDNS, DNA, location, terrain, tile download, styles
│   ├── theme/               # Light/dark Material themes
│   └── utils/               # Geo, aviation math, time, number formatting
└── features/
    ├── map/                 # Map rendering, aircraft tracking, aeronautical metadata, AUP/NOTAMs
    ├── telemetry/           # DroneCAN telemetry, vario, engine, airspeed, black box, traffic, VHF radio
    ├── navigation/          # Waypoint routing and navigation state
    ├── offline_maps/        # PMTiles offline region management and downloads
    └── settings/            # User preferences, pilot & aircraft profiles
```

- `src/native/`: Native C sources and the `libcanard` submodule.
- `assets/`: Vector styles, sprites, GeoJSON, fonts, and aircraft type icons.
- `documentation/`: Architecture and feature documentation.

## 📄 License

Stork is licensed under the **GNU General Public License v3.0 only (GPL-3.0-only)**.

You can redistribute it and/or modify it under the terms of version 3 of the GNU General Public License as published by the Free Software Foundation. **No later license versions apply** — the project is explicitly licensed under GPL v3 only (SPDX: `GPL-3.0-only`).

This program is distributed in the hope that it will be useful, but **WITHOUT ANY WARRANTY**; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the [LICENSE](LICENSE) file for the full license text.

> **Note:** The `src/native/libcanard` submodule is a third-party dependency and remains under its own license (MIT).
