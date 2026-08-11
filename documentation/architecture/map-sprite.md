# Map Sprite & Icon System

This document describes the **app sprite** — a single MapLibre sprite sheet that
provides every map and UI icon, shared between the native map renderer and the
Flutter widget tree.

## Overview

All map and UI icons come from a single app sprite sheet under
[`assets/map_sprites/`](../../assets/map_sprites/):

| File | Role |
| :--- | :--- |
| `sprite.json` / `sprite.png` | 1× index and sheet |
| `sprite@2x.json` / `sprite@2x.png` | 2× high-DPI index and sheet |

The sprite id is **`"default"`** — no `id:` prefixing anywhere (critical for
cross-platform loading on both native and web). The sprite sheet is the single
source of truth for icon art.

## Registration & Serving

The sprite is wired in three places:

1.  **Style definition** — [`assets/openaip/styles.json`](../../assets/openaip/styles.json)
    declares it in the `sprite` array:
    ```json
    { "id": "default", "url": "asset://map_sprites/sprite" }
    ```
2.  **Asset bundling** — [`pubspec.yaml`](../../pubspec.yaml) declares
    `assets/map_sprites/` under `flutter.assets`.
3.  **Local asset server** — [`MapAssetsServer`](../../lib/core/services/map_assets_server_io.dart)
    serves the `map_sprites` segment (alongside `openaip` and `fonts`), so
    `asset://map_sprites/sprite` resolves through the same transparent local
    proxy used for offline tiles. See
    [Offline Maps](../features/offline-maps.md).

## Sprite Contents

The sheet is compact (one row for the small icons, a shared row for the two
large ones) and contains:

| Frame prefix | Icons | Format | Used by |
| :--- | :--- | :--- | :--- |
| `traffic-icon-<name>` | 13 `AircraftType` silhouettes | **SDF** (`"sdf": true`) white silhouettes | `traffic-layer` (map) + traffic details dialog (UI) |
| `poi-icon-<name>` | 10 `PoiType` map-pin badges | Full colour | `favorites-layer` (map) + favourites list/dialogs (UI) |
| `possibleLoc` | Traffic possible-position ring | Full colour | `traffic-possible-layer` |
| `aircraft-icon` | Pilot's own-aircraft marker | Full colour | `aircraft-layer` |

### SDF traffic silhouettes

The traffic icons are stored as **SDF (signed distance field) white
silhouettes**. This allows MapLibre to tint them via the `icon-color` expression
instead of bundling three tinted variants per aircraft type:

*   **Active / flying** (`isFlying == true`): blue `#2196F3`
*   **Inactive / stationary**: grey `#9E9E9E`
*   **Collision threat** (`isCollisionThreat == true`): red `#FF3333`

The `traffic-layer` paint rule in
[`map_camera_style.dart`](../../lib/features/map/presentation/providers/map_camera_style.dart)
implements this with a `case` expression on the feature properties `isThreat`
and `isFlying` — there is no runtime image tinting.

## Map Usage

On style load, `MapCameraStyle.handleStyleLoaded` does not register any icons
programmatically. Layers reference sprite frames directly by `icon-image`:

*   `aircraft-layer` → `aircraft-icon` (`icon-size` `0.88`, keeping the marker
    at its intended on-screen size)
*   `traffic-layer` → `traffic-icon-<type>` (SDF, tinted via `icon-color`)
*   `traffic-possible-layer` → `possibleLoc`
*   `favorites-layer` → `poi-icon-<name>` (`icon-size` `0.64`)

The traffic feature builder
([`map_camera_provider.dart`](../../lib/features/map/presentation/providers/map_camera_provider.dart))
writes a single `icon-image: traffic-icon-<name>` plus the `isThreat` /
`isFlying` flags used by the paint expression.

## Flutter UI Usage ([`SpriteIcon`](../../lib/core/widgets/sprite_icon.dart))

Because the map already renders every icon from the app sprite, the Flutter UI
renders the exact same art instead of bundling duplicate PNGs:

*   **`SpriteIcon`** ([`lib/core/widgets/sprite_icon.dart`](../../lib/core/widgets/sprite_icon.dart)) — a `StatelessWidget` taking a `frameId` (e.g.
    `poi-icon-home` or `traffic-icon-glider`), optional `width`/`height`, and an
    optional `color` tint. It picks the sprite density from
    `SpriteCache.scaleForDevicePixelRatio` (≥ 1.5 → `@2x`). While loading it
    reserves the requested size so lists do not jump.
*   **`SpriteCache`** ([`lib/core/services/sprite_cache.dart`](../../lib/core/services/sprite_cache.dart)) — a singleton that loads `sprite.json`/`sprite.png`
    (choosing 1× or 2×), crops the requested frame with
    `Canvas.drawImageRect`, and caches decoded frames for the app lifetime.
    Failed loads are not cached so they can be retried after a regeneration.

Usage sites: the favourites page, `AddFavoriteDialog` and
`FavoriteDetailsDialog` (POI icons), and the traffic details dialog (tinted
`traffic-icon-*` silhouettes — flying uses the same blue `#2196F3` as the map).

## Tests

*   `test/core/widgets/sprite_icon_test.dart` — `SpriteIcon` renders a frame
    (deterministic: the `SpriteCache` is faked, no real asset decode/polling).
*   `test/features/map/domain/models/poi_type_sprite_test.dart` — every
    `PoiType` has a sprite frame.
*   `test/features/settings/presentation/assets/aircraft_type_assets_test.dart`
    — every `AircraftType` has a sprite frame.
*   `test/features/map/presentation/providers/traffic_possible_location_test.dart`
    — the `possibleLoc` frame exists.
*   All three frame tests also assert (via
    `test/helpers/sprite_test_utils.dart`) that every frame's bounding box fits
    inside the sheet, so a broken sprite layout fails CI.
*   `test/core/services/map_assets_server_test.dart` — the local server serves
    `map_sprites` assets with `application/json` content type.
