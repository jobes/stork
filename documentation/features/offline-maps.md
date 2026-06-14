# Offline Maps Technical Documentation

This document outlines the technical implementation of the offline map system in the Stork application.

## Overview

The Stork application implements an **Offline-First** architecture for map data. The system is designed to prioritize locally stored tiles to ensure high performance and availability without an internet connection, while seamlessly falling back to remote sources when online. This allows users to view both pre-downloaded regions and live-streamed data within the same interface. 

The system is built on top of MapLibre and uses a custom tile management engine backed by a local SQLite database and a local assets server.


## Key Components

### 1. Map Layers
The system downloads and manages three distinct layers to provide a comprehensive mapping experience:
- **Protomaps**: Vector tiles providing the base map (roads, buildings, natural features). Max zoom: 14.
- **OpenAIP**: Vector tiles containing aviation-specific data such as airspaces, airports, and navigational aids. Max zoom: 14.
- **Terrain**: Raster tiles providing elevation and topographic data. Max zoom: 12.

### 2. State Management
The offline map system is managed by the [OfflineMapsNotifier](../../lib/features/offline_maps/presentation/providers/offline_maps_provider.dart) (using Riverpod). It tracks:
- Defined geographic regions (bounding boxes).
- Download progress (tiles, bytes, and metadata).
- Active download states and error handling.

### 3. Data Storage
All offline data is persisted in a local SQLite database managed by [DatabaseService](../../lib/core/services/database/database_service_io.dart).
- **Regions**: Stores the ID and coordinates (NW/SE) of user-defined areas.
- **Tiles**: Stores raw tile data (PBF for vector, PNG for terrain) indexed by Z/X/Y coordinates and layer kind.
- **Metadata**: Stores supplementary GeoJSON features (airspaces, airports) extracted or downloaded separately.

## Implementation Details

### Region and Tile Calculation
Regions are defined by two geographic points: Northwest and Southeast. The system calculates the required tile set for each region using the standard Web Mercator projection.
- **Zoom Levels**: Tiles are fetched from zoom level 0 up to the layer's maximum zoom.
- **Deduplication**: Since regions may overlap, the system generates a unified set of unique tile coordinates across all active regions before starting a download.

### Download Engine ([TileDownloadService](../../lib/core/services/tile_download_service_io.dart))
The download process is optimized for efficiency and reliability:
- **Batch Processing**: Tiles are processed in large batches (up to 5000 tiles) to reduce database overhead.
- **PMTiles Archives**: The system fetches data from PMTiles archives. By ordering tiles by their internal PMTiles ID, the engine can utilize HTTP Range Requests to fetch multiple sequential tiles in a single network request.
- **Concurrent Archive Access**: Downloads for different layers (e.g., Protomaps and Terrain) run concurrently to maximize bandwidth utilization.
- **Fallback Mechanism**: If a batch download fails (e.g., due to missing tiles in the source archive), the system recursively splits the batch to identify and skip problematic tiles while successfully downloading the rest.

### Airspace & Airport Metadata
A unique feature of the Stork offline system is the two-stage metadata acquisition:
1. **Extraction**: After downloading OpenAIP tiles, the system scans a subset of these tiles (typically at zoom level 10) to identify which countries are covered by the region.
2. **Supplemental Fetching**: Based on the identified countries, the system fetches high-detail GeoJSON metadata (airspaces and airports) from Google Cloud Storage.
3. **Local Storage**: These features are parsed and stored in the local database, allowing the map to display interactive aeronautical details even when offline. For more information on how this data is modeled, parsed, and accessed, see the [Aeronautical Metadata and Map Interaction](aeronautical-metadata.md) documentation.

## Performance Optimizations
- **Sequential Writes**: Database updates are batched (50 tiles per transaction) to ensure high write performance.
- **Memory Management**: The system uses streams to process tile data, preventing large chunks of raw data from bloating the application's memory footprint during intensive downloads.
- **UI Responsiveness**: Progress is polled at 1-second intervals from the database, ensuring the UI stays updated without blocking the main thread with frequent state changes.

## Transparent Tile Serving ([MapAssetsServer](../../lib/core/services/map_assets_server_io.dart))
The application runs a local `HttpServer` that acts as a proxy for all map requests. This enables a transparent **Offline-First** loading strategy:

1.  **Local Look-up**: For every tile request, the server first queries the local SQLite database. If a matching tile is found (i.e., it was part of a previous download), it is served immediately from disk.
2.  **Remote Fallback**: If the tile is not found locally, the server automatically attempts to fetch it from the corresponding remote **PMTiles** archive. 
3.  **Unified Experience**: From the perspective of the MapLibre renderer, there is no distinction between "offline" and "online" modes. The renderer simply requests tiles from the local server, which handles the resolution logic internally.

This hybrid approach ensures that users always have access to the best available data: low-latency, offline-capable maps for downloaded regions, and full global coverage when connected to the internet.

### Dynamic Style Rewriting ([StyleService](../../lib/core/services/style_service_io.dart))

For the transparent tile serving proxy to work, the map style definitions must be dynamically rewired before they are loaded by the MapLibre engine. This is handled by [StyleService](../../lib/core/services/style_service_io.dart):
- **Asset Domain Mapping**: It loads the style definition (`assets/openaip/styles.json`) at runtime and swaps all `asset://` prefixes with the local server's URL (`MapAssetsServer.baseUrl`).
- **Vector & Raster Source Interception**: It modifies the JSON structure to strip standard remote API endpoints from vector sources (`protomaps`, `openaip-data`) and raster terrain sources (`terrain`), replacing them with tile template arrays pointing to the local proxy server (e.g., `http://localhost:<port>/pmtiles/protomaps/{z}/{x}/{y}.pbf`).
- **Offline Consistency**: This ensures that all map layers are requested solely through the local caching proxy, enabling transparent offline fallback for all vector data, aircraft layers, and hillshade terrain.


