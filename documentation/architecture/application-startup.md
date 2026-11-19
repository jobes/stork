# Application startup

The first Flutter frame is `StartupPage` (the quiet startup design). The router
is mounted only after `applicationBootstrapProvider` completes. This preserves
deep links while preventing `MapPage` and its native MapLibre view from being
created during local preparation. Startup failure stays on this page with retry.

`main()` mounts a small `FirstFrameStartup` loader without awaiting configuration
or the monitoring SDK and without constructing MaterialApp, themes or the router.
It shares `StartupContent` with the later application loader and waits for the
first frame to rasterize before building the full shell. Binding creation and `runApp` share a guarded zone for uncaught
errors. After the first loader frame, `applicationRuntimeProvider` loads `.env`
and initializes Sentry without a second `runApp`. Services that capture API keys
are only created after configuration is available. Sentry's UI wrapper mounts
with the router after initialization; monitoring failure does not prevent startup.

The bootstrap loads display preferences, settings, navigation and favourites,
starts the session's telemetry/recording services, prepares the FIR index off
the UI isolate, starts the local asset server, and opens the offline database.
The initial camera uses valid telemetry or a bounded, permission-free last-known
GPS lookup, with a regional fallback. It does not wait for GeoIP or a fresh fix.

`mapStyleProvider` prepares the final font scale and embeds all overlay sources
and layer definitions into the initial style. `MapOverlayStyle` is shared with
the live style/palette code; initial GeoJSON uses the same generators as live
updates. Sources with no available data are empty feature collections. Airspace
filters are embedded as well. `handleStyleLoaded(overlaysPrepared: true)` attaches
live updates and catches up only when the input snapshot changed, without adding
the embedded layers again. No new native readiness event or fixed map-loading
delay is used.

Saved navigation legs are embedded even before GPS is available. A valid live
position or the prepared last-known position adds the connector to the first
waypoint; the regional camera fallback is never used as an aircraft position.
The first valid GPS update and route edits bypass position throttling. Subsequent
position updates coalesce over two seconds with a trailing update, so the final
sample is delivered even when GPS stops sending. Native route writes are
serialized and identical source data is skipped.

Temporary settings and style subscriptions keep asynchronous settings loading
and the prepared map providers alive through the handoff. Reading a future alone
does not keep an auto-disposed settings provider mounted. The subscriptions close
after the first destination paints; normal page subscriptions then own these providers. Leaving the map can dispose
its controller subscriptions and tickers as before.

`DeferredStartupTasks` holds optional refreshes until that first destination
frame. Independent groups are released at 1-second intervals: NOTAM, airspace
activity, weather (including remote elevation/reference lookups), radar, and
Protomaps catalog. A failed or slow group does not block the next. Telemetry
reception and recording are not gated. Outside the application startup shell,
these services behave normally without a gate.

The asset server binds locally without contacting the Protomaps catalog. Both
native and web styles use a URL selected once from preferences or the fallback.
The delayed catalog request has a 3-second timeout and stores its result for the
next session; it never switches an active archive. Existing data availability
alerts remain responsible for freshness and errors. Base map/terrain tiles can
still require network access if they are not stored offline.

Verification includes startup/retry widget tests, layout checks for light/dark,
portrait/landscape and larger text, deferred task ordering, archive stability,
inline overlay style validity, and the existing map/weather/server regressions.
Native startup speed and first-gesture latency still require profile/release
measurements on a device.
