# Flight forecast

**Flight forecast** is enabled by default and can be switched in **Settings → Map**. The switch shows weather on the map, enables wind-adjusted ETA and weather alerts. The map shows the wind at the aircraft both with and without a route: a large arrow points where the wind is blowing, the wind speed is written below it and the surface gust follows as a short localized **gusts** value. The marker scales with the **Map font size** setting. On a route, the map shows small markers for waypoints without existing icons and dots for weather samples. Each waypoint and sample also carries a small wind arrow with the forecast speed and surface gusts at its estimated arrival time. An airport or saved favourite keeps its own icon. Tap a point to open the map menu and select **Route point details** or **Forecast at this point**. The route list also opens waypoint details.

Set cruising speed and default forecast altitude in the aircraft editor. A fresh aircraft starts at **100 km/h** and the pilot enters its default altitude in **ft AMSL**. The shared cruising speed setting was removed. Its previous value is ignored. A waypoint may override the selected aircraft's altitude or use its default. The altitude between two waypoints changes linearly with progress through the leg.

## Positions and times

The forecast includes the route origin, waypoints and destination. Additional points are placed at **10-minute** intervals using the selected aircraft's cruising speed and skipped within **2 minutes** of a waypoint. During flight the samples stay in place as ETAs change. Passed samples are dropped and editing the route can regenerate the sample positions. On the ground, choosing **Planned departure** in the route page opens one dialog with quick presets (Now, +30 min, +1 h), a day strip limited to the four-day horizon and an inline time field. It previews the destination ETA, clamps past times to now and rejects times outside the horizon. The departure picker uses local time and stores the selected instant in **UTC**; all forecast times (ETA, hourly intervals, download time and weather-warning passage times) are shown in **UTC** and marked with `UTC`. Clearing the route, or removing its last waypoint, clears the planned departure so a new route starts from the current time; undoing the removal restores it.

## Model data and offline use

Stork requests [DWD ICON EU Native through Open-Meteo](https://open-meteo.com/en/docs/dwd-api) directly from the device when the layer is enabled. Requests contain forecast coordinates and the requested UTC hours. The repository batches up to **20 locations** per request and stores up to **160 recent profiles** locally. It requests hourly data with a **one-hour** buffer on either side of the plan and checks for updates every **30 minutes**. For the live aircraft location a new nearby forecast is requested after approximately **3 km** of displacement. The app interpolates locally when an ETA or altitude changes within a saved profile. If the network request fails, saved data can still be used for a covered ETA and the detail shows the download time and that refresh is unavailable. Outside the saved time range, the point shows that the forecast is unavailable.

The weather feature lives in `lib/features/weather/`. The repository and its data models handle network responses, JSON parsing and local profiles, domain models do the route and weather calculations, and Riverpod provides the plan and forecasts to the existing map style and details UI. To keep the map clear, the Open-Meteo attribution link is shown in the forecast point details, the route weather warnings, the navigation details and the map settings instead of on the map. The displayed values are derived from the model.

## Wind, temperature and pressure

- **Wind and temperature at the planned altitude.** For each hour, the app builds a profile from the model's geopotential heights on **1000, 975, 950, 925, 900, 850, 800, 700, 600 and 500 hPa**. Levels below the model surface or known map terrain are excluded. The low layers add wind at **10, 80, 120 and 180 m** and temperature at **2, 80, 120 and 180 m** above the model surface. These are converted into AMSL heights using the model's grid elevation. The app interpolates between bracketing heights, then between hourly profiles. Wind is interpolated as east and north components and displayed as the direction it comes from. An altitude outside the usable profile has no wind estimate.
- **Surface gusts and precipitation.** The hourly gust value is the maximum **10 m above ground** in the hour containing ETA. Precipitation is the sum for that hour. The detail shows the interval used for both. Low cloud cover is the model's fraction of low cloud.
- **Estimated QNH and QFE.** QNH comes from model surface pressure reduced with the standard-atmosphere relationship. If a reference elevation is available, surface pressure is first adjusted to it using model temperature. The adjusted pressure is shown as QFE and used to estimate QNH. The reference is the published airport elevation when available, otherwise the loaded Stork terrain under the point. QFE is hidden when neither elevation is available. These values are model estimates for planning. The aircraft's altimeter settings are controlled through the existing altitude settings.
- **Point detail emphasis.** Each reading has its own icon colour. Values that exceed the selected aircraft's dangerous wind or gust limit, or that indicate precipitation or fog, are shown in the error colour with a warning symbol.

The model can miss local effects in valleys and along ridges. Coverage was checked with live model responses for Bratislava, Ružomberok and Donovaly. The test confirmed availability for selected heights and hours.

## Wind-adjusted arrival estimates

The navigation widget, route list, navigation dialog and forecast point details use the same timing calculation. The map wind arrows at route points use the estimated arrival time from that calculation. The map markers resolve the same airport or terrain reference as the point details, so the wind and gust values agree with the dialog. The route page shows the ETA, planned altitude and wind at each waypoint together with a route weather strip containing either warnings or the destination wind. The times on the map widget remain elapsed flight times to the next waypoint and the destination. The dialog shows ETA, the timing sources, wind at the waypoint, surface gusts at the destination and the time change attributable to wind on sections with a usable forecast.

The cruising speed in the selected aircraft profile is the planned true airspeed (TAS). Each leg is divided at forecast sample locations. The solver uses the forecast at the two ends of each section and the provisional midpoint time. It accounts for the wind component along the route and the airspeed needed to hold track in a crosswind. A second evaluation accounts for the change in midpoint time. Surface gusts are displayed as weather information.

In flight, Stork estimates the GPS ground vector from recent fixes and reported groundspeed. It subtracts the model wind at the aircraft's current height and position to estimate TAS internally. Sections of the current leg within 30° of the measured GPS track can use that estimate. A constant forecast wind on the same track yields the measured groundspeed. Later legs use the aircraft profile TAS for planning. The ground vector is smoothed during steady flight and reset on a turn. Sections without usable weather data use the GPS groundspeed in flight or the aircraft speed on the ground. If the provided wind prevents forward progress at the estimated TAS, ETA is unavailable from that point on. Automatic waypoint advancement uses the existing GPS-based timing.

## Background processing

On native targets, Flutter `compute` runs each wind-adjusted ETA calculation, weather response decode, offline-cache decode or encode, and forecast GeoJSON build in a short-lived Dart isolate. The UI isolate collects the route and settings, handles asynchronous HTTP and storage, and applies the completed GeoJSON to MapLibre. The route and map layers keep at most one computation in flight each. Pending updates use the newest inputs and results for superseded routes or map styles are discarded. The navigation UI can use its baseline estimate while the first result for a changed route is pending.

Flutter Web executes these same `compute` callbacks on the browser's main event loop.

## Aircraft weather limits and warnings

Each aircraft has optional **Dangerous wind** and **Dangerous surface gusts**
limits, entered in the selected speed unit and stored in m/s. Both start blank.
The wind threshold applies at the planned flight altitude. The gust threshold
applies to the forecast maximum at 10 m above ground. A warning is triggered
when the value strictly exceeds its threshold.

With Flight forecast enabled, Stork checks the aircraft location or the active
route's remaining forecast points at their estimated passage times. Precipitation,
fog (WMO 45/48), freezing drizzle/rain, snow and thunderstorms also generate
warnings, independently of the aircraft's wind limits. The check runs in a
short-lived isolate on native targets. Weather alerts use the existing orange
warning severity in the navigation card and top-right map status indicator.
The indicator's dialog lists active weather conditions alongside other alerts,
with critical system and collision alerts retaining priority.

A missing forecast cannot establish good weather. The model supplies weather
codes and precipitation, but this integration has no complete visibility and
cloud-ceiling assessment. These are adverse-weather warnings for planning.

The navigation detail opens with a weather-warning section when a forecast
hazard is active. It lists each affected waypoint or route sample, coordinates,
expected passage date/time and planned altitude. Wind and gust warnings include
the forecast value and the selected aircraft limit. Precipitation and gusts
show the hourly interval. Each entry opens the corresponding point detail.
The summary and orange status use the same background evaluation.

## Wind speed units

**Units and measurements** includes an independent **Wind speed unit** setting.
It supports m/s, km/h, mph and knots, with km/h as the initial value. The map
wind marker, gust labels, weather details, wind components, navigation weather
summary and warnings use it. The aircraft editor uses this unit for dangerous
wind/gust limits and the aircraft speed unit for cruising TAS. Stored weather
limits stay in m/s when either display unit changes.
