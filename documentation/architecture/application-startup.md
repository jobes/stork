# Application startup

The first Flutter frame is `StartupPage` (the quiet startup design). Startup
has two bounded stages: local preparation, then native map rendering. The router
mounts after `applicationBootstrapProvider` completes, **behind** the opaque
loader. The map stays laid out and rendering; it is not offstage. Pointer input,
focus and semantics are blocked until the initial map is ready.

`main()` mounts a small `FirstFrameStartup` loader without awaiting configuration
or monitoring and without constructing MaterialApp, themes or the router. It
shares `StartupContent` with the application loader and waits for the first frame
to rasterize before building the full shell. Binding creation and `runApp` share
a guarded zone for uncaught errors. After that frame, configuration loads `.env`
before services that capture API keys are created. Monitoring starts after local
preparation, alongside native rendering. It is never awaited by the startup gate.
`SentryWidget` stays mounted throughout startup, so delayed monitoring completion
cannot replace the native map subtree. Monitoring failure does not prevent startup.
Retry preserves pending monitoring initialization rather than starting a second
Sentry initialization. A completed failure may retry. An initialization that
never settles remains outside map readiness and is not restarted concurrently.

The bootstrap loads display preferences, settings, navigation and favourites,
starts the session's telemetry/recording services, prepares the FIR index off
the UI isolate, starts the local asset server, and opens the offline database.
The settings/session group, FIR index, local asset server and offline database
initialize concurrently. A bounded, permission-free last-known GPS
lookup starts alongside them, with a 600 ms budget counted from that early start.
A valid telemetry position skips waiting for that lookup. When a lookup is
needed, telemetry is re-read afterwards so an arriving live fix wins. The initial
camera falls back to the regional default without GeoIP or a fresh-fix request.
Failed or still-pending local resource providers are invalidated on retry;
successful local dependencies are reused and the native map is recreated.
Riverpod can retain the previous bootstrap result while refreshed preparation
is loading. Handoff waits for that refresh to finish before mounting the retry
map or releasing its preparation leases. A failed refresh keeps the retry page
visible.

`MapStartup` tracks an attempt number and preparation/rendering/ready/failed
phases. Preparation has a 15-second deadline; mounting the map starts a separate
15-second rendering deadline. Exceptions and fatal style/render errors show the
existing failure page immediately. A deadline also shows failure with Retry; it
never treats an incomplete map as ready. Late callbacks from a timed-out attempt
cannot dismiss the failure screen or unlock a newer attempt. Timers are cancelled
on success and disposal. Deep links to non-map destinations complete after their
first prepared frame without waiting for a map that is not mounted.

Startup steps have timeline spans. Build release with
`--dart-define=STORK_STARTUP_TIMINGS=true` to log durations and elapsed time from
Dart `main()`. The `Bootstrap` duration ends after local preparation and initial
style construction; it does not measure native map rendering or gesture latency.
Milestones also record `First loader frame`, `Preparation started`, `Map mounted`,
`Map fully rendered`, `Map ready` and `Interactive`. `Interactive` follows the
frame that removes the loader and enables map input. Normal release builds leave
timing logs disabled.

`mapStyleProvider` prepares the final font scale and embeds all overlay sources
and layer definitions into the initial style. `MapOverlayStyle` is shared with
the live style/palette code; initial GeoJSON uses the same generators as live
updates. Sources with no available data are empty feature collections. Airspace
filters are embedded as well. `handleStyleLoaded(overlaysPrepared: true)` attaches
live updates and catches up only when the input snapshot changed, without adding
the embedded layers again. Each native style callback identifies its requested
style JSON and uses that request's immutable overlay snapshot, not the latest
prepared snapshot. There is no snapshot cache or eviction dependency. Effective
brightness is checked independently of provider inputs. NOTAM errors clear initial and catch-up
notices, and failure of an aircraft catch-up write does not prevent
airspace/traffic initialization.

`AircraftMap` awaits controller/overlay initialization and requires a fully
rendered MapLibre frame for the current style. Native readiness uses
`onRenderFrame.fullyRendered`/`onRenderMap.fullyRendered`, not just style-loaded
or map-created. Web uses resource loading completion followed by idle. A Flutter
post-frame callback allows the texture to composite before revealing it.
Partial frames, obsolete style initialization and callbacks after disposal cannot
signal readiness; the initial signal is emitted once. Native idle is not required,
so continuing telemetry/camera updates cannot indefinitely postpone startup.
Unexpected initialization errors propagate to the retry gate; recoverable source
updates keep their existing retry behavior.

Saved navigation legs are embedded even before GPS is available. A valid live
position or the prepared last-known position adds the connector to the first
waypoint; the regional camera fallback is never used as an aircraft position.
The first valid GPS update and route edits bypass position throttling. Subsequent
position updates coalesce over two seconds with a trailing update, so the final
sample is delivered even when GPS stops sending. Native route writes are
serialized and identical source data is skipped. Failed writes retry at most
three times with 250/500/750 ms delays; each retry reads current state, and new
inputs cancel an obsolete retry. Style replacement and disposal cancel pending
retries. Native last-known coordinates are validated before conversion, and
prepared route origins use the same validation. A camera attach catches up a
new telemetry position while preserving an exact prepared camera or an explicit
user focus.

Temporary settings and style subscriptions keep asynchronous settings loading
and the prepared map providers alive through the handoff. Reading a future alone
does not keep an auto-disposed settings provider mounted. The subscriptions close
after the first destination paints; normal page subscriptions then own these
providers. Leaving the map can dispose its controller subscriptions and tickers
as before.

`DeferredStartupTasks` holds optional refreshes until the map is interactive
(or a non-map deep link has completed its handoff). Independent groups are
released at 1-second intervals: NOTAM, airspace activity, weather (including remote elevation/reference lookups), radar, and
Protomaps catalog. A failed or slow group does not block the next. Telemetry
reception and recording are not gated. Local terrain and airport reference
lookups bypass the weather gate; only their network fallbacks wait for it. Outside
the application startup shell, these services behave normally without a gate.

The asset server binds locally without contacting the Protomaps catalog. Both
native and web styles use a URL selected once from preferences or the fallback.
The delayed catalog request has a 3-second timeout and stores its result for the
next session; it never switches an active archive. Existing data availability
alerts remain responsible for freshness and errors. Base map/terrain tiles can
still require network access if they are not stored offline.

Verification includes startup/retry widget tests, layout checks for light/dark,
portrait/landscape and larger text, deferred task ordering, archive stability,
inline overlay style validity, and existing map/weather/server regressions.
`map_startup_provider_test.dart` covers both deadlines, disposal and stale attempts.
`aircraft_map_test.dart` covers partial/full render events, asynchronous style
initialization and its failures, one-shot readiness, fatal map errors and style
coalescing.
`startup_handoff_test.dart` exercises real bootstrap/style/page code with a
substitute native renderer: it checks the visible loader and blocked input,
render timeout/retry, stale callbacks, delayed monitoring completion without map
recreation, local failure retry and disposal when navigating away. A slow
monitoring future does not block `application_bootstrap_test.dart`. Offline
reference tests resolve local terrain/airport data with the online gate closed.

## Samsung release measurements (2026-11-20)

Measured on Samsung SM-X510 using the installed Flutter 3.50.0 SDK and release
APKs with `STORK_STARTUP_TIMINGS=true`. Each sample force-stops and launches the
process with ADB; the screen is awake/unlocked, existing offline data and caches
are retained, and the same saved settings are used. These are process-cold,
cache-retaining starts, not fresh installations. Timings start at Dart `main()`
and exclude Android process and Flutter engine initialization. Android's reported
`am start` wait time is not used as a map-rendering measurement.

| Metric | Baseline runs (ms) | Updated runs (ms) | Baseline median | Updated median |
| --- | --- | --- | ---: | ---: |
| Bootstrap duration | 155 / 189 / 157 | 256 / 125 / 127 | 157 ms | 127 ms |
| Main to prepared style | 268 / 302 / 243 | 407 / 228 / 214 | 268 ms | 228 ms |
| Main to first loader frame | Not instrumented | 107 / 66 / 64 | — | 66 ms |
| Main to fully rendered map | Not instrumented | 1433 / 1747 / 831 | — | 1433 ms |
| Main to interactive map | Not instrumented | 1451 / 1764 / 853 | — | 1451 ms |

Median bootstrap duration decreased by 30 ms (19%); median main-to-prepared-style
elapsed time decreased by 40 ms (15%). The updated first sample after installation
was slower than the following samples. Native rendering varies with available
resources; the complete interaction measurement ranges from 853 to 1764 ms.

The measured release was installed and launched successfully on the tablet.
Visual checks confirmed the base map, airspaces, airports, saved route, favourites
and telemetry widgets. Opening the drawer and panning the native map verified
input after the loader cleared. The full suite passed 1338 tests. Analyzer
reported no errors or warnings; the existing 151 Material import deprecation
information messages remain.

A final reinstall after formatting/lint cleanup also passed a cold-launch smoke
check: fully rendered at 2250 ms and interactive at 2273 ms from Dart `main()`,
with no fatal or startup initialization errors. This separate post-install check
is not included in the three-sample comparison above.

Three samples are a device observation, not a guaranteed saving. The earlier
build did not expose native readiness timing, so only preparation timing has a
comparable baseline. The new render and interaction milestones verify the
loading-screen contract; they must not be compared with the old loader's earlier
removal after preparation alone.
