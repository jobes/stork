# Changelog

All notable changes to **Stork** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- Initial public release of Stork, the EFB application for glider and aircraft pilots.

Highlights:

- Vector map visualization (MapLibre) with dynamic styles and sprites.
- Offline maps via PMTiles with background download and fault tolerance.
- DroneCAN telemetry over CAN-over-IP (Cannelloni) with native FFI bindings to `libcanard`.
- VHF radio control & monitoring over DroneCAN.
- Engine and airspeed telemetry with segmented gauges and threshold alarms.
- Variometer (VSI) with linear-regression smoothing and EMA filtering.
- Multi-source traffic aggregation (OGN, PureTrack, GDL90).
- Collision Avoidance System (CAS) with kinematic prediction.
- Black box flight logging with SQLite persistence and GPX export.
- Active airspaces (AUP/UUP) from Slovak LzPS and Czech ŘLP AUP portals.
- NOTAM alerts from the FAA API.
- OpenAIP aeronautical metadata synchronization.
- Pilot & aircraft management with JSON persistence and PIN security.
- Altitude resolution & terrain elevation with Auto-QNH calibration.
- Customizable draggable/resizable overlay widgets.
- English and Slovak localization.
