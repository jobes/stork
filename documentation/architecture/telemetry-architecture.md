# Telemetry and Network Architecture

This document describes the high-performance telemetry, DroneCAN integration, and IP-encapsulated CAN network architecture in the Stork application.

---

## 1. High-Level Architecture

Stork uses an advanced, robust, and real-time telemetry pipeline to ingest flight and hardware data. Since modern avionics systems communicate using **CAN / DroneCAN** buses, but mobile/web devices lack physical CAN ports, the application bridges this gap using **CAN-over-IP** encapsulation.

The telemetry pipeline consists of the following layers:

```mermaid
graph TD
    A[Physical CAN Bus / DroneCAN Nodes]
    A -->|CAN Frames| B[Cannelloni Device / Ethernet Bridge]
    B -->|UDP-Encapsulated CAN Frames| C[Stork App: Cannelloni UDP Socket]
    C -->|Raw CAN Frames| D[Native C libcanard Binding]
    D -->|Parsed Message Payloads| E[Dart FFI Callback]
    E -->|Structured Dart Data| F[TelemetryNotifier / Riverpod]
    F -->|Decayable Fields / Safety| G[App UI & Follow-Mode Map]
```

---

## 2. Cannelloni Service (CAN-over-IP)

To communicate with a remote CAN bus, the application implements the client side of the **Cannelloni** protocol. Cannelloni encapsulates raw CAN frames inside UDP datagrams, allowing low-latency, real-time wireless telemetry over Wi-Fi or Ethernet.

### Socket Management
The system is managed by [CannelloniService](../../lib/core/services/cannelloni_service_io.dart) (a Riverpod provider):
- **Dynamic Connection**: It listens to settings changes ([appSettingsProvider](../../lib/features/settings/presentation/providers/settings_provider.dart)). When a target device is selected, it binds to a local UDP socket on an ephemeral port and connects to the target IP and port.
- **Bi-Directional Sockets**: Using a `RawDatagramSocket`, it listens asynchronously for incoming packets, extracts payload chunks, and immediately forwards them to the native C layer for processing.

### TX Processing Queue (10Hz)
To ensure reliable frame delivery and prevent network congestion, outbound messages are processed in a periodic loop:
- A `Timer` runs at **10Hz** (every 100ms on IO platforms).
- In each tick, the service invokes the native [storkCanardGenerateTxPacket](../../src/native/stork_canard.c) to check if any outbound DroneCAN frames are queued in the native heap.
- If frames are ready, they are packaged into a UDP payload and transmitted to the remote bridge.

---

## 3. Multicast DNS (mDNS) Service Discovery

To avoid forcing users to manually input IP addresses or port numbers, Stork integrates an automated network discovery mechanism using Multicast DNS.

### Scan Procedure
The scan runs via the [discoveredDevices](../../lib/core/services/mdns_service.dart) stream provider:
1. **Service Type**: The service searches for `_cannelloni._udp.local` PTR records on the local subnet.
2. **Filtering**: It filters the results to match instances with the prefix `avionics-dronecan.` to ensure it only registers compatible bridges.
3. **SRV & IP Records**: For each discovered pointer, it retrieves:
   - The SRV record (containing the port and target hostname).
   - The IPAddress record (translating the hostname into a reachable IPv4 address).
4. **Periodic Refresh**: The stream yields results immediately upon initialization and schedules automatic sub-network rescans every **10 seconds** to detect when bridges go offline or new ones join.

---

## 4. Dynamic Node ID Allocation (DNA)

DroneCAN requires each node on the bus to have a unique numeric ID (1 to 127). Newly connected devices initially participate as anonymous nodes (Node ID `0`). Stork includes a full implementation of the **Dynamic Node ID Allocation (DNA)** protocol to claim a valid ID.

### DNA Protocol Workflow
1. **Anonymity**: Upon startup or socket reconnection, the app initializes the native stack with Node ID `0`.
2. **Persistent Unique ID (UUID)**: To identify itself uniquely across sessions, Stork generates a persistent 16-byte random UUID and stores it in `SharedPreferences`.
3. **Request Loop**: [DnaAllocationHandler](../../lib/core/services/dna_allocation_service.dart) begins broadcasting allocation requests containing slices of its UUID.
   - **T_request**: The initial request is sent after a random delay between 600 ms and 1000 ms to prevent network startup collisions.
   - **T_followup**: If a partial matching confirmation is received from the allocation server, a follow-up request is scheduled quickly (between 0 ms and 400 ms) to claim the ID.
4. **Collision Avoidance (Rule C)**: If the app detects DNA activity or allocation messages belonging to *other* nodes on the bus, it backs off and restarts its request timer to avoid colliding with other initializing devices.
5. **Confirmation**: Once the server allocates a Node ID and confirms the full 16-byte UUID, the handler switches `CannelloniService` to the allocated ID via [storkCanardInit(allocatedNodeId)](../../src/native/stork_canard.c) and begins active broadcasting.

---

## 5. Native DroneCAN Integration (FFI & C `libcanard`)

The core decoding and encoding of DroneCAN messages is implemented in C using a custom wrapper around [libcanard](../../src/native/stork_canard.c). This is bound to Dart via `dart:ffi`.

### Initialization & Callbacks
During startup, `CannelloniService` loads the native library and performs three main registrations:
1. **Log Callback**: Routes nitty-gritty native C logs into the Dart console with a `[stork_canard]` prefix.
2. **Transfer Callback**: Executed whenever the native C layer successfully reassembles a multi-frame DroneCAN message.
3. **Accept Callback**: Validates incoming message signatures and filters messages the app is interested in, preventing CPU overhead from irrelevant frames.

### Handled Messages

| Message Name | Message ID | Signature | Purpose in Stork |
| :--- | :--- | :--- | :--- |
| **`DynamicNodeIdAllocation`** | `1` | `0x1E1E6F37F15D7C81` | Manages node address resolution. |
| **`GetNodeInfo` (Request/Response)** | `430` | `0xEE468A80E6174A7C` | Allows other nodes to query the app's software version/UID. |
| **`NodeStatus`** | `341` | `0x0F0877D1C67EAE9B` | Broadcasts the app's health and uptime (1Hz). |
| **`StaticPressure`** | `1030` | `0x3E10E45E8D2E12F5` | Feeds barometric altitude data to the telemetry notifier. |
| **`Fix2`** | `1063` | `0xCA41E7000F37435F` | Decodes high-accuracy GPS/GNSS telemetry data (latitude, longitude, heading, ground speed, altitude, satellite count, accuracy). |
| **`IceStatus`** | `1120` | `0xD38AA3EE75537EC6` | Decodes engine status, including oil temp/pressure, coolant temp, fuel rates, CHTs, and EGTs. |
| **`FuelTankStatus`** | `1129` | `0x286B4A387BA84BC4` | Decodes fuel tank levels, volumes, consumption rates, and temperatures. |
| **`StorkEngineRpm`** | `20120` | `0xD8CD8D1076CA4884` | Decodes custom engine speed (RPM), load, throttle position, and ECU index. |

---

## 6. Telemetry State & Decay Safety

Avionics applications must never show stale telemetry data if a connection drops. If a sensor or network bridge fails, displaying outdated values could mislead the pilot or ground crew.

To prevent this, Stork introduces a safety mechanism called **Decay Safety** implemented via a custom wrapper: [DecayableField<T>](../../lib/features/telemetry/presentation/providers/decayable_field.dart).

### `DecayableField<T>` Mechanics
Each telemetric parameter inside [TelemetryNotifier](../../lib/features/telemetry/presentation/providers/telemetry_provider.dart) is wrapped in a [DecayableField](../../lib/features/telemetry/presentation/providers/decayable_field.dart) with a custom timeout threshold:

```dart
// Example: Heading and Speed have a 2-second timeout
late final DecayableField<double> _heading = DecayableField<double>(
  timeout: const Duration(seconds: 2),
  onChanged: (val) {
    state = val == null
        ? state.resetField(TelemetryField.heading)
        : state.copyWith(heading: val);
  },
);
```

### Expiration Logic
- **Frequent Updates**: Every time a telemetry message is parsed (e.g., a `StaticPressure` message from FFI or a GPS update from location services), `update(newValue)` is called. This cancels any active decay timer and schedules a new one.
- **Automatic Cleardown**: If no update is received within the `timeout` window:
  1. The internal timer fires.
  2. The field resets to `null`.
  3. The Riverpod `TelemetryState` is updated to clear the field.
  4. The UI immediately reflects the missing data (e.g. showing offline indicators or warning states).
- **Persistent Support State**: Flags indicating sensor presence (e.g., `isEngineRpmSupported`, `isFuelSupported`) **persist as `true`** even after data decays. This ensures widgets stay visible and show error/timeout states rather than vanishing completely.

### Timeout Thresholds

| Telemetry Parameter | Timeout | Safety Rationale |
| :--- | :--- | :--- |
| **`latitude` / `longitude`** | `Duration.zero` (No decay) | Managed by higher-level GPS providers. |
| **`heading`** | `2 seconds` | Safe rotation updates; prevents heading drift displays. |
| **`groundSpeed`** | `2 seconds` | Ensures sudden deceleration or dropouts are shown instantly. |
| **`indicatedAirSpeed`** | `1 second` | Critical flight dynamic data; must expire immediately if lost. |
| **`gpsAltitude`** | `2 seconds` | Avoids presenting outdated altitude during rapid descents. |
| **`heightAboveGround`** | `2 seconds` | Critical terrain clearance parameter. |
| **`gpsSatelliteCount`** | `1 second` | Standard GPS quality check parameter. |
| **`gpsHorizontalAccuracy`**| `2 seconds` | Used to evaluate position precision. |
| **`gpsVerticalAccuracy`**  | `2 seconds` | Used to evaluate altitude precision. |
| **`engineRPM`** | `1.5 seconds` | Immediate notification if motor/engine RPM telemetry is interrupted. |
| **`coolantTemperature`** | `1.5 seconds` | Coolant system thermal health decay. |
| **`oilPressure`** | `1.5 seconds` | Critical lubrication health decay. |
| **`oilTemperature`** | `1.5 seconds` | Critical engine thermal state decay. |
| **`cylinderHeadTemperatures`** | `1.5 seconds` | Individual cylinder head temperatures decay. |
| **`exhaustGasTemperatures`** | `1.5 seconds` | Individual exhaust gas temperatures decay. |
| **`fuelLevelPercent`** | `1.5 seconds` | Fuel level status decay. |
| **`fuelVolumeLiters`** | `1.5 seconds` | Fuel volume status decay. |
| **`airPressure`** | `1 second` | Essential sensor input. |
