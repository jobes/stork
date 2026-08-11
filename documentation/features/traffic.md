# Multi-Source Traffic Monitoring and Live Beaconing Technical Documentation

This document describes the network protocols, APRS/SSE/UDP telemetry decoding, Open Glider Network (OGN) Device Database integration, PureTrack integration, GDL90 (SafeSky/Stratux) UDP receiver integration, background Isolate-based live beaconing, canonical ID deduplication, Riverpod state management, map rendering, trajectory projection, and UI components for **Traffic System** in the Stork application.

---

## 1. System Overview

Stork integrates live aircraft traffic tracking from multiple telemetry networks — **Open Glider Network (OGN)** APRS, **PureTrack** SSE/WebSocket stream, and **GDL90** local UDP receivers (SafeSky, Stratux, SkyEcho 2, …) — and bidirectional position sharing. The application receives live telemetry for surrounding gliders, tow planes, helicopters, paragliders, and powered aircraft across all sources, aggregates and deduplicates aircraft targets in real time, while optionally broadcasting the pilot's own position to enhance situational awareness and collision avoidance.

```mermaid
graph TD
    subgraph Network Layer
        OGNServer[aprs.glidernet.org:14580]
        DDBServer[ddb.glidernet.org]
        PureTrackAuth[puretrack.io API Auth]
        PureTrackStream[puretrack.io SSE Stream]
        GDL90Rx[GDL90 UDP Broadcast<br/>SafeSky / Stratux / SkyEcho 2]
    end

    subgraph Stork Telemetry Data Pipeline
        InboundConn[[OgnInboundConnection]] -->|Raw APRS Lines| OgnService[[OgnAprsService]]
        OgnService -->|APRS Packets| Aggregator[[TrafficAggregator]]
        
        PureTrackAuthService[[PuretrackAuthService]] -->|JWT Token| PureTrackStreamService[[PuretrackStreamService]]
        PureTrackStreamService -->|PureTrack Packets| Aggregator

        Gdl90Service[[Gdl90Service]] -->|GDL90 Messages| Gdl90Decoder[[Gdl90Decoder]]
        Gdl90Decoder -->|Gdl90Targets| Aggregator

        Aggregator -->|Deduplicate via CanonicalId| TrafficNotifier[[trafficProvider]]
        TrafficNotifier -->|Request Metadata| OgnService
        OgnService -->|REST HTTP Query| DDBServer
    end

    GDL90Rx -->|UDP :4000| Gdl90Service

    subgraph Stork Outbound Pipeline
        Telemetry[[Telemetry Provider]] -->|Position & Vario| OutboundMgr[[OgnOutboundManager]]
        OutboundMgr -->|Spawns| OutboundIsolate[[OgnOutboundIsolate]]
        OutboundIsolate -->|Encoded APRS Packet| OGNServer
    end

    subgraph State & Filtering
        TrafficNotifier -->|Unified Traffic Map| FilteredProvider[[filteredTraffic Provider]]
        Settings[[appSettingsProvider]] -->|Distance Limits| FilteredProvider
    end

    subgraph Map & Presentation Layer
        FilteredProvider -->|Watch Traffic| MapCamera[[MapCamera Provider]]
        MapCamera -->|Update GeoJSON| MapSource[traffic-source]
        MapSource -->|Render Icons| MapLayer[traffic-layer / symbol]
        MapSource -->|Render Uncertainty| PossibleLayer[traffic-possible-layer]
        
        MapLayer -->|Tap Feature| ClickHandler[handleMapEvent]
        ClickHandler -->|Open Dialog| Dialog[TrafficDetailsDialog]
    end

    OGNServer -->|TCP APRS Stream| InboundConn
    PureTrackStream -->|SSE / WebSockets| PureTrackStreamService
    MapCamera -->|Viewport Bounds| TrafficNotifier
    TrafficNotifier -->|#filter a/latN/lonW/latS/lonE| InboundConn
    TrafficNotifier -->|#filter a/latN/lonW/latS/lonE| PureTrackStreamService
```

---

## 2. Telemetry Ingest & Viewport Filtering

### 2.1. OGN APRS Inbound Connection
The class [OgnInboundConnection](../../lib/features/telemetry/data/ogn_aprs_service.dart#L280) manages an active TCP socket connection to the OGN APRS core servers:
*   **Host & Port:** `aprs.glidernet.org:14580`
*   **Authentication Handshake:** Upon connection, the socket sends:
    ```text
    user anonymous pass -1 vers storknav 1.0\r\n
    ```
*   **Stream Processing:** Decodes UTF-8 byte streams into raw line frames using `LineSplitter()`.
*   **Reconnection Logic:** Handles disconnects and socket errors gracefully. The provider [trafficProvider](../../lib/features/telemetry/presentation/providers/traffic_provider.dart) schedules reconnections using an exponential backoff strategy (retrying every 2s up to 30s).

### 2.2. PureTrack Service Integration & Streaming
Stork integrates PureTrack live tracking via [PuretrackAuthService](../../lib/features/telemetry/data/puretrack_auth_service.dart) and [PuretrackStreamService](../../lib/features/telemetry/data/puretrack_stream_service.dart).

*   **Authentication & Token Management:**
    *   [PuretrackAuthService](../../lib/features/telemetry/data/puretrack_auth_service.dart) manages REST API authentication, login credential validation, token caching, invalidation, and session freshness checks.
    *   If authentication is required or credentials expire, [PureTrackAuthBanner](../../lib/features/telemetry/presentation/widgets/puretrack_auth_banner.dart) displays an interactive alert in the UI for re-authentication.
    *   `PuretrackAuthService` manages HTTP client ownership cleanly, preserving external client instances on `dispose()`.
*   **SSE / WebSocket Stream Handling:**
    *   [PuretrackStreamService](../../lib/features/telemetry/data/puretrack_stream_service.dart) connects using a JWT token to stream real-time JSON packets.
    *   Incoming packets are parsed into [PureTrackPacket](../../lib/features/telemetry/data/puretrack_stream_service.dart) objects with robust numeric parsing capability (handling numbers, strings, and missing values safely).

### 2.3. Dynamic Spatial Viewport Filtering
To minimize cellular data usage and server overhead, Stork dynamically updates server-side APRS and SSE filters so that only aircraft within or near the active map viewport are received from both networks.

*   **Filter Command Format:** `#filter a/latN/lonW/latS/lonE` (specifying North, West, South, and East bounding limits in decimal degrees formatted to 4 decimal places).
*   **Update Triggers:**
    1.  **Immediate Shift Trigger:** Sent instantly if the camera center shifts by more than $1500\text{ m}$ (`kOgnFilterSignificantShiftMeters`) or if more than $15\text{ s}$ (`kOgnFilterMaxUnsentDuration`) have passed since the last filter update.
    2.  **Debounced Panning Trigger:** Uses a trailing $1\text{ s}$ debounce timer (`kOgnFilterDebounceDuration`) for minor manual panning or zooming interactions.

### 2.4. GDL90 UDP Receiver (SafeSky / Stratux / SkyEcho 2)
Unlike OGN and PureTrack, GDL90 is not a network service — it is a **local UDP broadcast** emitted by ADS-B / FLARM receivers that implement the GDL90 protocol (e.g. SafeSky, Stratux, SkyEcho 2). Stork listens on the configured UDP port and decodes the datagrams locally, so no cellular data is used.

*   **Socket Binding:** [Gdl90Service](../../lib/features/telemetry/data/gdl90_service.dart) binds a `RawDatagramSocket` on `gdl90BindIp` (default `0.0.0.0`) and `gdl90UdpPort` (default `4000`) with `reuseAddress`/`reusePort` enabled so the port can be shared with other receivers. UDP sockets are unavailable on Web (`kIsWeb` guard), so GDL90 is a native-only feature.
*   **Lifecycle:** The service is started exactly once via `start()` (which always schedules the expiry timer and binds the socket), then reconfigured via `updateConfig()` (which rebinds only when `enabled`, `host`, or `port` actually change). The orchestration lives in `applyGdl90Settings` in [gdl90_provider.dart](../../lib/features/telemetry/presentation/providers/gdl90_provider.dart) and is unit-tested without a socket.
*   **Target Expiry:** The service maintains its own in-memory target map with a periodic $5\text{ s}$ purge timer. A target is dropped when `Gdl90Target.isExpired()` reports that more than `gdl90TargetExpirySeconds` (default $60\text{ s}$, configurable $10\text{–}300\text{ s}$) have elapsed since its last report. Because this expiry is much shorter than the aggregator's $15\text{-minute}$ stale purge, dropped GDL90 targets are actively removed from the traffic aggregator (see §3.3).
*   **Heartbeat & Receiver Status:** Every successfully decoded datagram records a heartbeat timestamp. `gdl90HeartbeatActiveProvider` emits `true` while a heartbeat was received within the last $10\text{ s}$ (polled every second and re-emitted on each heartbeat), driving the live receiver status indicator in settings.

---

## 3. Data Parsing, Multi-Source Aggregation & Deduplication

### 3.1. APRS, PureTrack & GDL90 Telemetry Decoding
*   **APRS Decoding:** Raw APRS lines are parsed by `parseAprsLine` in [OgnAprsService](../../lib/features/telemetry/data/ogn_aprs_service.dart#L429), extracting callsign, UTC timestamp, high-precision coordinates, altitude, ground speed, heading, and OGN commentary flags (stealth, no-tracking, aircraft type, vertical speed).
*   **PureTrack Decoding:** Stream JSON objects are decoded in [PuretrackStreamService](../../lib/features/telemetry/data/puretrack_stream_service.dart), mapping PureTrack telemetry fields (latitude, longitude, altitude, speed, track, vertical speed, aircraft category) into standardized values.
*   **GDL90 Decoding:** Raw UDP datagrams are fed through [Gdl90Decoder](../../lib/features/telemetry/data/gdl90_decoder.dart), an incremental stateful parser that handles HDLC-style byte stuffing (`0x7E` flags, `0x7D` escape) and validates each frame's CRC16-CCITT FCS before dispatching on the message ID:
    *   `0x00` **Heartbeat** — GPS/UTC validity flags and a 15-bit time stamp.
    *   `0x14` **Traffic Report** — 24-bit ICAO address, 24-bit lat/lon ($180/2^{23}$ °/LSB), 12-bit altitude (25 ft/LSB, $-1000$ ft offset, `0xFFF` = invalid), 12-bit ground speed (knots, `0xFFF` = invalid), 12-bit vertical speed (64 ft/min/LSB, sign-extended, `0x800` = unavailable), 8-bit track ($360/256$ °/LSB), 8-bit emitter category, and an 8-char space-padded callsign.
    *   `0x0A` **Ownship Report** — decoded with the same layout but deliberately excluded from traffic targets (the own aircraft must never appear on the map).
    *   FCS validation is tolerant of both byte orders and of the non-reflected `0x1021` variant used by SafeSky; heartbeat frames that carry extra trailing status bytes fall back to structural validation so a valid receiver is never misjudged as inactive. The clock is injectable (`Gdl90Decoder({now})`) for deterministic testing.

### 3.2. Multi-Source Aircraft Domain Model (`TrafficAircraft`)
Parsed traffic from all networks is unified into the [TrafficAircraft](../../lib/features/telemetry/domain/models/traffic_aircraft.dart) domain model:
*   `id`: Canonical unique identifier.
*   `callsign`: Raw callsign or tail number.
*   `registration`, `aircraftModel`, `cn`: Resolved aircraft metadata.
*   `icaoHex`: ICAO 24-bit hex address (always set for GDL90 targets; set for OGN and PureTrack when their identifier is ICAO-like) — the key used for cross-source deduplication.
*   `latitude`, `longitude`, `altitude`: Current position and MSL altitude in meters.
*   `altitudeValid`, `speedValid`, `verticalSpeedValid`: Validity flags (default `true`) propagated from GDL90's `0xFFF`/`0x800` unavailable markers. The aggregator preserves a previously known value when an incoming field is marked invalid, and the details dialog renders `-` for invalid fields.
*   `track`, `groundSpeed`, `verticalSpeed`: Kinematic vectors.
*   `aircraftType`: Integer category code mapped via `AircraftType.fromOgnCode(code)` for OGN, `AircraftType.fromPureTrackType(code)` for PureTrack, and `AircraftType.fromGdl90EmitterCategory(code)` for GDL90.
*   `sources`: Set of source names currently reporting the aircraft (e.g. `{'ogn', 'gdl90'}`).
*   `activeSource`: Source of the latest accepted position update.
*   `lastSeen`: UTC timestamp of the last packet.
*   `isAnonymous`: Privacy flag.

### 3.3. Canonical ID Resolution, ICAO Merge & Deduplication
Because the same physical aircraft can be reported simultaneously by OGN, PureTrack, and GDL90, Stork uses [CanonicalId](../../lib/features/telemetry/domain/utils/canonical_id.dart) and [TrafficAggregator](../../lib/features/telemetry/domain/repositories/traffic_aggregator.dart) to deduplicate aircraft targets:
*   **Canonical Keys:** Merges records based on matching registration, contest number, or hardware hex ID.
*   **Cross-Source ICAO Merge:** When an incoming target carries an `icaoHex` (GDL90 always does — its ID *is* the ICAO address), the aggregator scans for an existing target from another source with the same ICAO (e.g. an OGN FLARM entry `FLRDDA5E6` for the same physical aircraft as GDL90 `166752`). On a match, the new report is merged into the existing entry **under its existing key**, so the aircraft never appears twice on the map. The merged entry keeps the previously known canonical ID and adds the new source to its `sources` set.
*   **T_sent Position Arbitration:** Only reports with a strictly newer `lastSeen` update position and dynamic fields; older or duplicate reports only refresh metadata. When a newer report marks a field invalid, the previously known value is preserved.
*   **Source-Specific Purge:** `purgeSource(source)` removes a source from all targets (and deletes targets with no remaining sources) when OGN/PureTrack/GDL90 is disabled or logged out.
*   **ICAO-Specific Purge:** `purgeSourceFromIcao(source, icaoHex)` removes a source from a single aircraft — used so a GDL90 target dropped by the service's $60\text{ s}$ expiry does not linger on the map until the much longer aggregator stale-purge. The traffic provider diffs `_knownGdl90Ids` on every emission and purges dropped IDs.
*   **History Cleanup:** When stale targets are evicted (targets inactive for $> 10\text{--}15\text{ minutes}$) or purged, `TrafficAggregator` purges evicted canonical IDs from `_trackHistories` to prevent memory leaks.
*   **Computed Fields:** `updateComputedFields` applies turn-rate/circling analysis by the stored canonical key (the existing key on ICAO merges), so computed fields always reach the merged entry.

---

## 4. OGN Device Database (DDB) Integration

Because raw telemetry packets carry limited identification, Stork asynchronously queries the official Open Glider Network Device Database (DDB) to resolve tail numbers and aircraft models.

### 4.1. DDB Query Mechanics
*   **Endpoint:** `https://ddb.glidernet.org/download/?j=1&device_id=ID1,ID2,...`
*   **HTTP Method:** GET request with batch comma-separated device IDs.
*   **User-Agent:** `stork-aprs-app/1.0.0 (https://github.com/vjoba/stork)`
*   **Caching:** Resolved entries are stored in an in-memory `_ddbCache` dictionary in [OgnAprsService](../../lib/features/telemetry/data/ogn_aprs_service.dart#L368) to eliminate redundant network fetches.

### 4.2. Resolved Fields
*   `registration`: Tail number (e.g. `OM-1234`).
*   `aircraft_model` $\rightarrow$ `aircraftModel`: Type designation (e.g. `Discus 2c`, `WT9 Dynamic`).
*   `cn`: Glider competition / contest number (e.g. `77`).

---

## 5. Outbound Tracking (Live Position Broadcast)

Stork supports broadcasting the pilot's own telemetry to the OGN APRS network so other aircraft and ground tracking stations (e.g. LiveTrack24, OGN Viewer) can see the aircraft.

```mermaid
sequenceDiagram
    participant UI as Main UI Thread
    participant Prov as Telemetry Provider
    participant Mgr as OgnOutboundManager
    participant Iso as OgnOutboundIsolate
    participant Net as aprs.glidernet.org:14580

    UI->>Mgr: start(callsign, ognId, aircraftType)
    Mgr->>Iso: Isolate.spawn()
    Iso->>Net: TCP Connect
    Iso->>Net: user anonymous pass -1...
    loop Every 30 seconds
        Iso->>Net: # keepalive
    end
    loop Every 3 seconds (when isFlying == true)
        Prov->>Mgr: Telemetry (Lat, Lon, Alt, Speed, Heading, VS)
        Mgr->>Iso: sendPosition(...)
        Iso->>Iso: Encode APRS Packet (DMS, Knots, Feet, +VSfpm)
        Iso->>Net: Send APRS Line
    end
    UI->>Mgr: stop()
    Mgr->>Iso: Send 'stop' & kill isolate
    Iso->>Net: Close Socket
```

### 5.1. Background Isolate Architecture
To eliminate UI frame drops caused by socket network operations, live position broadcasting runs entirely within a dedicated background Dart `Isolate`:
*   [OgnOutboundIsolate](../../lib/features/telemetry/data/ogn_aprs_service.dart#L96): Manages the background TCP socket, performs format conversion, sends periodic `# keepalive\r\n` pings every $30\text{ s}$, and transmits position packets.
*   [OgnOutboundManager](../../lib/features/telemetry/data/ogn_aprs_service.dart#L224): Controls spawning, message passing across `SendPort`/`ReceivePort` pairs, and teardown.

### 5.2. Outbound APRS Encoding
Every $3\text{ s}$, if `telemetry.isFlying` is `true`, the isolate formats and sends a standard APRS frame:
*   **Callsign Formatting:** Uses `OGN` + 6-hex OGN ID (or existing `ICA`/`FLR` prefix).
*   **Coordinate Encoding:** Converts decimal degrees into Degrees/Minutes/Direction (`DDMM.mmN` / `DDDMM.mmE`).
*   **Unit Conversions:**
    *   Speed: $\text{m/s} \rightarrow \text{knots}$ ($\times 1.94384$).
    *   Altitude: $\text{meters} \rightarrow \text{feet}$ ($\times 3.28084$).
    *   Vario: $\text{m/s} \rightarrow \text{feet per minute}$ ($\times 196.8504$).
*   **Comment String:** `idXXYYYYYY +VSfpm` (encodes aircraft type byte `XX` and 6-hex `YYYYYY` ID).

### 5.3. Activation Requirements
Outbound beaconing starts automatically when:
1.  An active aircraft is selected in settings.
2.  `aircraft.sendLivePosition` is enabled (`true`).
3.  `aircraft.ognDeviceId` is a valid 6-character hexadecimal string (e.g. `012345`).
4.  GPS telemetry reports valid coordinates and `telemetry.isFlying == true`.

---

## 6. Riverpod State Management & Filtering

### 6.1. Providers Overview
1.  `ognAprsServiceProvider`: Provides the singleton `OgnAprsService` instance.
2.  `puretrackAuthServiceProvider`: Provides the `PuretrackAuthService` instance.
3.  `puretrackAuthProvider`: Manages authentication state (credentials, JWT tokens, login status).
4.  `gdl90ServiceProvider`: Keep-alive provider owning the `Gdl90Service` singleton. It wires `appSettingsProvider` through `applyGdl90Settings` (start-once via `ref.listen(..., fireImmediately: true)` + a `started` flag, then `updateConfig()` on every settings change) and disposes the service on teardown.
5.  `gdl90HeartbeatActiveProvider`: Stream provider emitting the live receiver status (`true` while a GDL90 heartbeat arrived within the last $10\text{ s}$) by bridging a periodic poll with the service's heartbeat stream.
6.  `trafficProvider` ([TrafficNotifier](../../lib/features/telemetry/presentation/providers/traffic_provider.dart#L29)): Keeps an active in-memory map (`_aircraftMap`) of all aggregated aircraft across OGN, PureTrack, and GDL90. Manages connections, decay timers, DDB lookups, and outbound beaconing state. Subscribes to the GDL90 target stream, mirrors the service's per-target expiry via `purgeSourceFromIcao`, and maintains `_ownshipTrackHistory` for ownship turn rate calculation.
7.  `filteredTrafficProvider` ([filteredTraffic](../../lib/features/telemetry/presentation/providers/traffic_provider.dart#L348)): Applies spatial distance filters and runs 3D collision threat evaluations via `CasEvaluator.evaluateThreat` for all targets.
8.  `activeCollisionAlertProvider` ([activeCollisionAlert](../../lib/features/telemetry/presentation/providers/traffic_provider.dart#L461)): Filters all active traffic threats, sorts targets by shortest $t_{\text{CPA}}$ and closest minimum separation distance, returning the highest-priority collision threat.

### 6.2. Spatial Filtering & CAS Threat Evaluation Logic
`filteredTraffic` filters and evaluates the raw list using preferences defined in `AppSettings`:
*   **Horizontal Distance Filter:** Rejects targets exceeding `trafficMaxHorizontalDistance` (default $50000\text{ m} / 50\text{ km}$).
*   **Vertical Distance Filter:** Rejects targets exceeding `trafficMaxVerticalDistance` (default $1500\text{ m}$).
*   **3D Threat Evaluation:** Calculates turn rates ($\omega$), detects sustained thermal circling, predicts 3D kinematic trajectories, and evaluates closest point of approach ($t_{\text{CPA}}$ and $d_{\text{CPA}}$). For comprehensive mathematical details, see [Collision Avoidance System Documentation](collision-avoidance-system.md).

---

## 7. Map Rendering & Trajectory Projection

The MapLibre integration handles traffic visualization in [map_camera_style.dart](../../lib/features/map/presentation/providers/map_camera_style.dart#L183) and [map_camera_provider.dart](../../lib/features/map/presentation/providers/map_camera_provider.dart#L528).

### 7.1. Layer Architecture
*   **`traffic-source`:** GeoJSON source holding target points with feature properties (`id`, `heading`, `icon-image`, `altitudeTag`, `isThreat`, `isFlying`, `possiblePositionRatio`). The `icon-image` is always the single SDF frame `traffic-icon-<type>`; `isThreat`/`isFlying` drive the `icon-color` paint expression (see § 7.2).
*   **`traffic-layer`:** Symbol layer rendering the SDF aircraft silhouettes from the app sprite (rotated according to target track `heading`) and displaying dynamic relative altitude tags (`altitudeTag`) for active threats.
*   **`traffic-possible-layer`:** Symbol layer rendering position uncertainty rings when lookahead projection is active.

### 7.2. Icon Registration, Category Styling & Threat Highlighting
Traffic icons come from the app sprite ([`assets/map_sprites/`](../../assets/map_sprites/), sprite id `"default"`) as SDF silhouettes (`traffic-icon-<type>`). Colour state is applied per layer via the `icon-color` expression on `traffic-layer` (no runtime tinting):
*   **Active Traffic (Flying, $GS > 1.0\text{ m/s}$):** Blue icon (`#2196F3`) — `isFlying == true`.
*   **Inactive / Stationary Traffic ($GS \le 1.0\text{ m/s}$):** Grey icon (`#9E9E9E`).
*   **Collision Threat Targets (`isCollisionThreat == true`):** Red icon (`#FF3333`) and bold red altitude tag text (`#FF3333` with black halo outline).

### 7.3. Trajectory Lookahead Vector
To compensate for network latency and depict true relative movement, Stork projects each aircraft's estimated future position:
*   **Lookahead Constant:** `kTrafficLookaheadPeriodSeconds = 10.0` seconds.
*   **Distance Projection:** $\text{distance} = \text{groundSpeed} \times (\text{elapsedSeconds} + 10.0)$.
*   **Position Ratio:** Calculated relative to icon size (`kTrafficBaseIconSizePx = 64.0`) to scale the `traffic-possible-layer` circle radius appropriately.

---

## 8. Interactive User Interface

### 8.1. Details Dialog (`TrafficDetailsDialog`)
Tapping an aircraft icon on the map queries features from `traffic-layer` and opens [TrafficDetailsDialog](../../lib/features/map/presentation/components/dialogs/traffic_details_dialog.dart#L15).

```text
+---------------------------------------------------+
| ✈ Traffic Details                             [X] |
+---------------------------------------------------+
| [Icon]  OM-1234 [77]                  2.4 km      |
|         Discus 2c • Glider                        |
|         [ OGN ] [ GDL90 ]                          |
+---------------------------------------------------+
| ABSOLUTE ALTITUDE             LAST SEEN           |
| 1,450 m                       4s ago              |
|                                                   |
| GROUND SPEED                  VERTICAL SPEED      |
| 120 km/h                      +2.4 m/s            |
|                                                   |
| AIRCRAFT TYPE                                     |
| Glider                                            |
+---------------------------------------------------+
```

The dialog's aircraft icon is rendered from the app sprite via `SpriteIcon` (`frameId: acType.trafficMapIconId`), tinted blue (`#2196F3`) for flying targets (`groundSpeed > 1.0 m/s`) and grey for stationary targets. Unlike the map layer, `TrafficDetailsDialog` does **not** pass `isCollisionThreat` to `SpriteIcon`, so it never uses the map's red `#FF3333` threat colour — collision threats are not tinted red in the dialog. See the [Map Sprite & Icon System](../architecture/map-sprite.md).

The dialog displays localized source chips (`[ OGN ]`, `[ PureTrack ]`, `[ GDL90 ]`) using theme-adaptive color tokens (`Theme.of(context)`), highlighting the `activeSource` of the aircraft. Fields whose GDL90 validity flag is `false` (e.g. unavailable altitude) render as `-`.

### 8.2. Collision Warning Banner (`CollisionWarningBanner`)
When an active threat is detected, an alert banner is dynamically rendered over the map UI:
*   Displays target callsign, separation at CPA ($d_{\text{CPA}}$), time to closest approach ($t_{\text{CPA}}$), and relative altitude ($\pm\text{m}$ or $\pm\text{ft}$).
*   Tapping the banner opens the `TrafficDetailsDialog` for the threat target.

### 8.3. PureTrack Authentication Banner (`PureTrackAuthBanner`)
Displays an inline banner when PureTrack streaming requires user authentication or token renewal, allowing immediate navigation to settings or quick login.

---

## 9. Settings & Configuration

The traffic monitoring, PureTrack credentials, GDL90 receiver, and collision avoidance systems are configured via [AppSettings](../../lib/features/settings/domain/models/app_settings.dart), [Aircraft](../../lib/features/settings/domain/models/aircraft.dart), [PureTrackSettingsCard](../../lib/features/settings/presentation/widgets/puretrack_settings_card.dart), and [Gdl90SettingsCard](../../lib/features/settings/presentation/widgets/gdl90_settings_card.dart):

```dart
// AppSettings traffic filtering fields
bool trafficFilterMaxHorizontalDistanceEnabled; // Default: true
double trafficMaxHorizontalDistance;             // Default: 50000.0 (meters)
bool trafficFilterMaxVerticalDistanceEnabled;   // Default: true
double trafficMaxVerticalDistance;               // Default: 1500.0 (meters)

// PureTrack Configuration fields
bool puretrackEnabled;                           // Toggle PureTrack telemetry integration
String puretrackUsername;                        // PureTrack user account email
String puretrackPassword;                        // PureTrack user password

// GDL90 Receiver Configuration fields
bool gdl90Enabled;                               // Toggle local GDL90 UDP receiver (default: true)
String gdl90BindIp;                              // UDP bind address (default: '0.0.0.0')
int gdl90UdpPort;                                // UDP port (default: 4000, clamped 1..65535)
int gdl90TargetExpirySeconds;                    // Target expiry timeout (default: 60, clamped 10..300)

// AppSettings Collision Avoidance System (CAS) fields
bool casEnabled;                                 // Default: true
double casLookaheadTime;                         // Default: 12.0 (seconds)
double casHorizontalThreshold;                   // Default: 1000.0 (meters)
double casVerticalThreshold;                     // Default: 300.0 (meters)

// Aircraft profile live tracking fields
bool sendLivePosition;                           // Toggle live outbound position broadcast
String ognDeviceId;                              // 6-character Hex OGN device ID
```

### 9.1. GDL90 / SafeSky Receiver Card ([Gdl90SettingsCard](../../lib/features/settings/presentation/widgets/gdl90_settings_card.dart))
The GDL90 receiver is configured from the traffic settings page:
*   **Enable Toggle:** Master switch for the local GDL90 UDP receiver (`gdl90Enabled`).
*   **Receiver Status Indicator:** Live dot + label driven by `gdl90HeartbeatActiveProvider` — green **Active** while a heartbeat was received within the last $10\text{ s}$, grey **Inactive (No signal)** otherwise.
*   **Bind IP Address & UDP Port:** Text fields (locale-aware, with dedicated `FocusNode`s so a rebuild never clobbers in-progress user input) for `gdl90BindIp` and `gdl90UdpPort`. Updates are clamped via the settings notifier (`port` to $1\text{–}65535$).
*   **Target Expiry Timeout:** Slider from $10\text{ s}$ to $300\text{ s}$ in $10\text{ s}$ steps controlling how long a GDL90 target survives without a new report before the service drops it (`gdl90TargetExpirySeconds`).
