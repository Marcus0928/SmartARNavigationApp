# API & Function Documentation

## Smart AR Navigation App for Enhanced Driving Assistance

---

| Field | Details |
|---|---|
| **Project Title** | Smart AR Navigation App for Enhanced Driving Assistance |
| **Author** | Liew Sau Yang (22062475) |
| **Supervisor** | Dr Javid Iqbal Thirupattur |
| **Institution** | Sunway University — School of Computing and Artificial Intelligence |
| **Programme** | Bachelor of Software Engineering (Hons) |
| **Version** | 1.7 |
| **Last Updated** | July 2026 |

---

## Table of Contents

1. [Overview](#1-overview)
2. [LocationService](#2-locationservice)
3. [RouteRepository](#3-routerepository)
4. [PlacesRepository](#4-placesrepository)
5. [ARService](#5-arservice)
6. [NavigationViewModel](#6-navigationviewmodel)
7. [ARViewModel](#7-arviewmodel)
8. [MapViewModel](#8-mapviewmodel)
9. [RecentPlacesRepository](#9-recentplacesrepository)
10. [RecentPlacesViewModel](#10-recentplacesviewmodel)
11. [SettingsViewModel](#11-settingsviewmodel)
12. [Utility Functions](#12-utility-functions)
13. [Enums & Constants](#13-enums--constants)
14. [DynamicArrowWidget](#14-dynamicarrowwidget)
15. [AmbientLightService](#15-ambientlightservice)
16. [VoiceService](#16-voiceservice)
17. [TrafficDelayBadge](#17-trafficdelaybadge)

---

## 1. Overview

This document describes the core functions of the Smart AR Navigation App. Each section covers one file/class, listing its key functions with:
- **Purpose** — what it does
- **Parameters** — what it takes in
- **Returns** — what it gives back
- **Notes** — anything important to know

All code is written in **Dart** using the **Flutter** framework.

### Naming Conventions

| Convention | Example |
|---|---|
| Classes | `PascalCase` → `RouteRepository` |
| Functions / Variables | `camelCase` → `startNavigation()` |
| Constants | `camelCase` → `apiBaseUrl` |
| Files | `snake_case` → `route_repository.dart` |
| Private members | Prefix with `_` → `_locationStream` |

---

## 2. LocationService

**File:** `lib/services/location_service.dart`  
**Purpose:** Wraps the `geolocator` package to provide GPS location to the rest of the app.

---

### `checkPermission()`

```dart
Future<bool> checkPermission()
```

**Purpose:** Checks if the app has location permission. Requests it if not yet granted.

**Parameters:** None

**Returns:** `bool` — `true` if permission granted, `false` if denied

**Notes:**
- Call this on app startup in `SplashScreen`
- If permanently denied, redirect user to app settings

---

### `getCurrentLocation()`

```dart
Future<LatLng> getCurrentLocation()
```

**Purpose:** Gets the user's current GPS position as a one-time read.

**Parameters:** None

**Returns:** `LatLng` — latitude and longitude of the current position

**Notes:**
- Used when navigation first starts to set the origin point
- Throws an exception if location permission is not granted

---

### `getLocationStream()`

```dart
Stream<LatLng> getLocationStream()
```

**Purpose:** Returns a continuous stream of GPS position updates.

**Parameters:** None

**Returns:** `Stream<LatLng>` — emits a new `LatLng` every ~1 second

**Notes:**
- Used during active navigation to update AR overlays in real time
- Remember to cancel the stream subscription when navigation stops to save battery
- Cancels any previous internal `Geolocator` subscription before creating the new one — a defensive guard so that if this is ever called twice without an intervening `stopLocationStream()` (not currently possible via `MapViewModel`'s `_trackingStarted` guard, but not defended against at this layer either), GPS fixes aren't delivered twice per real position update

---

### `stopLocationStream()`

```dart
void stopLocationStream()
```

**Purpose:** Cancels the active GPS stream subscription.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Always call this when the user stops navigation or leaves the AR screen

---

## 3. RouteRepository

**File:** `lib/repositories/route_repository.dart`  
**Purpose:** Communicates with the Google Maps Directions API to fetch route data.

---

### `getRoute()`

```dart
Future<List<RouteModel>> getRoute({
  required LatLng origin,
  required LatLng destination,
  bool avoidTolls = false,
  bool avoidHighways = false,
  double? heading,
})
```

**Purpose:** Fetches up to three alternative driving routes from the Google Maps Directions API.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `origin` | `LatLng` | The user's current GPS location |
| `destination` | `LatLng` | The user's chosen destination |
| `avoidTolls` | `bool` | If `true`, adds `avoid=tolls` to the request (default `false`) |
| `avoidHighways` | `bool` | If `true`, adds `avoid=highways` to the request (default `false`) |
| `heading` | `double?` | The device's compass heading in degrees (0–360, 0 = North). When non-null, appended as `&heading=N` so the Directions API biases the route to match the driver's current direction of travel. Suppresses phantom U-turns at route start. |

**Returns:** `List<RouteModel>` — up to 3 alternative routes ordered fastest-first; each entry includes `label`, `waypoints`, `polylinePoints`, `turns`, `totalDistance`, `estimatedDuration`, and `hasTolls`

**Notes:**
- Makes an HTTP GET request to `maps.googleapis.com/maps/api/directions/json` with `alternatives=true` and `departure_time=now`
- `mode=driving`
- Duration uses `duration_in_traffic` when available (requires `departure_time=now`)
- Throws a `RouteNotFoundException` if no route is found
- Throws a `NetworkException` if the device has no internet

---

### `parseRouteResponse()`

```dart
List<RouteModel> parseRouteResponse(Map<String, dynamic> json)
```

**File:** `lib/core/utils/route_parser.dart`

**Purpose:** Parses the raw JSON response from the Google Maps Directions API into a list of `RouteModel` objects; also detects toll roads.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `json` | `Map<String, dynamic>` | Raw JSON response from the Directions API |

**Returns:** `List<RouteModel>` — one entry per alternative route

**Notes:**
- Sets `hasTolls = true` when the route-level `warnings` array contains the word "toll", **or** when any step's `html_instructions` contains the word "toll" (covers Malaysian routes where warnings may be absent)
- Extracts the road name from the first non-compass, non-ordinal `<b>` tag in `html_instructions`
- Extracts roundabout exit numbers via `_parseRoundaboutExit()`: tries the structured `step['exit']` integer field first; falls back to parsing the ordinal in `html_instructions` (e.g. "take the **3rd** exit") when the field is absent — common in Malaysian API responses
- Drops any step shorter than 15 m from the `turns` list (filters GPS/API noise steps that would otherwise be popped almost instantly by `ARViewModel`'s turn-pruning), **except** the last step in a leg, which is always kept regardless of length — Google often emits a short final "turn onto X; destination is on the Y" step when the destination sits close to the last turn, and dropping it would leave the final turn without an arrow or voice announcement

---

### `getTrafficSeverityAhead()`

```dart
Future<TrafficSegmentInfo?> getTrafficSeverityAhead({
  required LatLng currentLocation,
  required List<LatLng> remainingPolyline,
})
```

**Purpose:** Checks live traffic conditions over the next ~2 km of the active route and classifies the delay.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `currentLocation` | `LatLng` | The user's current GPS position |
| `remainingPolyline` | `List<LatLng>` | The not-yet-driven portion of the route polyline |

**Returns:** `TrafficSegmentInfo?` — `null` when there's no significant delay (or on any network/parsing failure); otherwise a segment with `delayMinutes`, `segmentStartPosition`, `segmentEndPosition`, and `severity`

**Notes:**
- Walks `remainingPolyline` forward from `currentLocation` to find the point ~2 000 m ahead (`_pointAhead()`), then requests a Directions API route for just that short segment
- Compares that segment's traffic-aware `duration_in_traffic` against its free-flow `duration`; `delayRatio = (durationInTraffic - duration) / duration`
- Returns `null` if `delayRatio < 0.2` (not worth surfacing) — this is a normal "no traffic" outcome, not an error
- Classifies `TrafficSeverity.heavy` when `delayRatio > 0.5`, otherwise `TrafficSeverity.moderate`
- `delayMinutes` is `(durationInTraffic - duration) / 60`, rounded
- Best-effort like `_checkForFasterRoute()` — any network or parsing exception is swallowed and returns `null` rather than throwing
- Called by `NavigationViewModel._checkTrafficSegment()` on a 3-minute timer during active navigation

---

## 4. PlacesRepository

**File:** `lib/repositories/places_repository.dart`  
**Purpose:** Communicates with Google Maps Places API for destination search autocomplete.

---

### `searchPlaces()`

```dart
Future<List<PlaceModel>> searchPlaces(String query)
```

**Purpose:** Returns a list of place suggestions based on the user's search input.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `query` | `String` | The text the user has typed in the search bar |

**Returns:** `List<PlaceModel>` — list of matching place suggestions (max 5)

**Notes:**
- Makes an HTTP GET request to the Google Places Autocomplete API
- Returns an empty list if query is less than 3 characters
- Results are biased toward the user's current location

---

### `getPlaceDetails()`

```dart
Future<PlaceModel> getPlaceDetails(String placeId)
```

**Purpose:** Gets the full details (including GPS coordinates) of a selected place.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `placeId` | `String` | The Google Place ID from a `searchPlaces()` result |

**Returns:** `PlaceModel` — includes name, address, and `LatLng` coordinates

**Notes:**
- Called after the user taps on a suggestion from the search dropdown
- The `LatLng` from this response is passed to `RouteRepository.getRoute()` as the destination

---

## 5. ARService

**File:** `lib/services/ar_service.dart`  
**Purpose:** Wraps `ar_flutter_plugin` to manage the ARCore session and render overlays.

---

### `initializeAR()`

```dart
Future<bool> initializeAR(
  ARSessionManager sessionManager,
  ARObjectManager objectManager,
)
```

**Purpose:** Initializes the ARCore session on the device.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `sessionManager` | `ARSessionManager` | Provided by the `ARView` widget's `onARViewCreated` callback |
| `objectManager` | `ARObjectManager` | Provided by the same callback |

**Returns:** `bool` — `true` once `onInitialize()` completes for both managers

**Notes:**
- Call this when the AR Navigation Screen loads (from `ARNavigationScreenState._onARViewCreated`)
- If a previous session is still active (`_isInitialized == true`), calls `disposeAR()` first to release it before initializing the new one — without this, re-entering the AR screen repeatedly (e.g. via the Routes button round-trip) would leak native ARCore sessions and eventually crash

---

### `placeArrow()`

```dart
void placeArrow(TurnDirection direction, double distance)
```

**Purpose:** Notifies the widget layer that arrow state has changed (intentional no-op in the current implementation).

**Notes:**
- Arrow overlays are rendered as Flutter widget overlays driven by `ARViewModel` state, not as 3D ARCore anchor nodes. `ARNavigationScreen` rebuilds `DynamicArrowWidget` whenever `ARViewModel` notifies listeners. This method exists to maintain the service interface; no ARCore calls are made inside it.

---

### `updateArrow()`

```dart
void updateArrow(TurnDirection direction, double distance)
```

**Purpose:** Same as `placeArrow()` — no-op; the ViewModel drives the widget rebuild.

---

### `clearOverlays()`

```dart
void clearOverlays()
```

**Purpose:** Resets arrow state on navigation end (intentional no-op in the current implementation).

**Notes:**
- Overlay clearing is handled by `ARViewModel.resetOverlay()` which sets all state to null and notifies listeners, causing `ARNavigationScreen` to hide the arrow widget.

---

### `disposeAR()`

```dart
void disposeAR()
```

**Purpose:** Properly closes and disposes the ARCore session.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Called unconditionally from `ARNavigationScreenState.dispose()`, so the session is always released on screen teardown — not just when a new session happens to be created afterward
- Also called internally by `initializeAR()` before it reinitializes, if a session is already active
- Failing to dispose will cause memory leaks and, with repeated re-initialization, native ARCore crashes

---

## 6. NavigationViewModel

**File:** `lib/viewmodels/navigation_viewmodel.dart`  
**Purpose:** Manages the overall navigation session state. Extends `ChangeNotifier`.

---

### `startNavigation()`

```dart
Future<void> startNavigation(
  PlaceModel destination, {
  RouteModel? route,
  int? routeIndex,
})
```

**Purpose:** Starts a navigation session to the selected destination.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `destination` | `PlaceModel` | The place the user wants to navigate to |
| `route` | `RouteModel?` | Pre-fetched route to use directly (skips the API call) |
| `routeIndex` | `int?` | Index of the selected route in the preview list; stored as `activeRouteIndex` |

**Returns:** Nothing

**Notes:**
- If `route` is provided, uses it directly and skips `RouteRepository.getRoute()`
- Passes `heading: _locationService.currentHeading` to both `getRoute()` and `initializeOverlay()` so route direction matches the driver's travel direction
- Sets `navigationStatus` to `NavigationStatus.navigating`
- Records `activeRouteIndex` so the route selection UI can show Resume vs Go labels
- Starts the background faster-route check timer (`Timer.periodic` every 5 min) and the traffic segment check timer (`Timer.periodic` every 3 min) after a successful route fetch
- Notifies listeners so the UI navigates to the AR screen
- **Not** for resuming an already-active session on the same route: calling this while `navigationStatus == navigating` fully stops and restarts the session (fresh route fetch, `ARViewModel.initializeOverlay()` reseeded). The Home Screen's "Resume" button (shown when the selected route already matches `activeRouteIndex`) skips calling this entirely and just re-pushes the AR screen, to avoid an unnecessary restart

---

### `stopNavigation()`

```dart
void stopNavigation()
```

**Purpose:** Ends the active navigation session and resets all state.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Sets `navigationStatus` to `NavigationStatus.idle`
- Cancels the faster-route check timer and the traffic segment check timer
- Clears `_suggestedFasterRoute` and `_trafficSegmentInfo`
- Calls `LocationService.stopLocationStream()`
- Calls `ARService.clearOverlays()`
- Notifies listeners so the UI returns to the Home Screen

---

### `recalculateRoute()`

```dart
Future<void> recalculateRoute()
```

**Purpose:** Fetches a new route when the user has gone off the original path.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Triggered automatically by `MapViewModel` when GPS position deviates more than **50 metres** from the nearest route segment (perpendicular distance, not vertex distance)
- A 30-second cooldown prevents repeated reroutes caused by GPS drift
- Sets `navigationStatus` to `NavigationStatus.rerouting` before the API call (triggers the `_ReroutingBanner` on the AR screen), then back to `navigating` on success
- Passes `heading: _locationService.currentHeading` to `getRoute()` and `initializeOverlay()`
- Updates `currentRoute` and notifies listeners

---

### `checkIfArrived()`

```dart
void checkIfArrived(LatLng currentLocation)
```

**Purpose:** Checks if the user has reached the destination.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `currentLocation` | `LatLng` | The user's current GPS position |

**Returns:** Nothing

**Notes:**
- Called on every GPS update during navigation
- If distance to destination is less than 20 metres, sets status to `NavigationStatus.arrived`
- Triggers the arrival UI state

---

### `suggestedFasterRoute`

```dart
RouteModel? get suggestedFasterRoute
```

**Purpose:** Exposes the most recently found faster route candidate for the AR screen to show the full-screen `_FasterRouteMapWidget` preview.

**Notes:**
- Set by `_checkForFasterRoute()` (`Timer.periodic`, every 5 min) when a candidate saves at least 300 seconds (5 min) **and** that saving is at least 10% of the remaining duration — both conditions must hold
- Skipped entirely if a turn is imminent (`distanceToNextTurn < 500`), so the suggestion never interrupts a turn
- A previously dismissed duration is remembered (`_dismissedRouteDuration`) so the same route isn't re-suggested immediately after the user dismisses it
- Cleared when the user taps **Switch** (`acceptFasterRoute()`) or **Dismiss** (`dismissFasterRoute()`), or when navigation stops — there is no auto-dismiss timer; the preview stays up until the user acts

---

### `acceptFasterRoute()`

```dart
Future<void> acceptFasterRoute()
```

**Purpose:** Switches the active navigation route to the suggested faster route.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Calls `initializeOverlay()` with the faster route and heading
- Clears `_suggestedFasterRoute`
- Notifies listeners so the AR screen rebuilds with the new route

---

### `dismissFasterRoute()`

```dart
void dismissFasterRoute()
```

**Purpose:** Dismisses the faster-route preview without switching routes.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Clears `_suggestedFasterRoute` and records its duration as `_dismissedRouteDuration`
- The next `_checkForFasterRoute()` tick may surface another suggestion if a candidate saves more time than the dismissed one

---

### `trafficSegmentInfo` / `hasEnteredTrafficSegment`

```dart
TrafficSegmentInfo? get trafficSegmentInfo
bool get hasEnteredTrafficSegment
```

**Purpose:** Exposes the current traffic-delay segment (if any) and whether the driver's GPS position currently sits inside it, so the AR screen can render `TrafficDelayBadge`.

**Notes:**
- `trafficSegmentInfo` is set by `_checkTrafficSegment()` and cleared by `_clearTrafficSegment()`, `stopNavigation()`, or a fresh `_checkTrafficSegment()` result
- `hasEnteredTrafficSegment` is recomputed on every GPS tick by `updateTrafficSegmentProgress()`

---

### `_checkTrafficSegment()`

```dart
Future<void> _checkTrafficSegment()
```

**Purpose:** Polls `RouteRepository.getTrafficSeverityAhead()` for the current position and stores the result.

**Notes:**
- Called by a `Timer.periodic` (every 3 min) started in `startNavigation()` and cancelled in `stopNavigation()`
- No-ops if there's no active destination/route, or if `navigationStatus != navigating`
- On a fresh result, resets `hasEnteredTrafficSegment` to `false` — the newly (re)fetched segment hasn't been entered yet even if the previous one had been
- Best-effort — network/parsing errors are silently ignored, leaving the previous segment (if any) in place

---

### `updateTrafficSegmentProgress()`

```dart
void updateTrafficSegmentProgress(LatLng location)
```

**Purpose:** Classifies the driver's current GPS position against the active traffic segment on every GPS tick — entered, not yet reached, or passed.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `location` | `LatLng` | The user's current GPS position |

**Returns:** Nothing

**Notes:**
- Called on every GPS update alongside `checkIfArrived()` and `ARViewModel.updateAROverlay()`
- Uses the triangle-inequality relationship between `start→location`, `location→end`, and `start→end` distances to classify the position without a full vector projection — appropriate for the short (~2 km) lookahead segment
- If `location` is farther from the segment start than the segment's own length, the segment has been passed and is cleared via `_clearTrafficSegment()`
- No-ops if `trafficSegmentInfo` is `null`

---

## 7. ARViewModel

**File:** `lib/viewmodels/ar_viewmodel.dart`  
**Purpose:** Manages AR overlay state. Extends `ChangeNotifier`.

---

### `updateAROverlay()`

```dart
void updateAROverlay(LatLng currentLocation)
```

**Purpose:** Recalculates what AR overlay to show based on the user's current position.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `currentLocation` | `LatLng` | The user's latest GPS position |

**Returns:** Nothing

**Notes:**
- Called on every GPS stream update
- Drops any turn whose position is within **25 m** of `currentLocation` (threshold raised from 10 m to account for Malaysian urban GPS accuracy of 10–30 m)
- Finds the first **non-forward** turn in `_remainingTurns` (i.e. the next real maneuver — left, right, keepLeft, keepRight, U-turn, or roundabout) and calculates the distance to it; this distance is always assigned to `distanceToNextTurn`
- **Distance gate (all non-forward turns):** A `_lookaheadActive` flag implements hysteresis — engages when `distanceToCurrentStep ≤ 1 000 m`, disengages when `distanceToCurrentStep > 1 100 m`. While the gate is inactive the overlay shows the forward/straight direction; once active it shows the upcoming turn early. This prevents flickering at the 1 km boundary and applies to **all** non-forward turn types (not just roundabouts).
- **If within 1 000 m** of that upcoming non-forward turn (gate active): sets `nextTurnDirection`, `instructionText`, `currentStreetName`, and `roundaboutExit` from that upcoming turn so the driver gets early warning
- **If more than 1 100 m** away (gate inactive): shows the current step direction (forward/straight) while `distanceToNextTurn` still reflects the upcoming non-forward turn
- Notifies listeners so the AR overlay widget rebuilds

---

### `initializeOverlay()`

```dart
Future<void> initializeOverlay(RouteModel route, {double? heading})
```

**Purpose:** Sets up the AR overlay when navigation first starts.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `route` | `RouteModel` | The route fetched from `RouteRepository` |
| `heading` | `double?` | The device's compass heading at navigation start. When non-null and the first step is a U-turn, that step is removed (phantom U-turn guard). |

**Returns:** Nothing

**Notes:**
- Stores the route's `turns` list as `_remainingTurns` and sets the initial overlay state
- Phantom U-turn guard: if `heading != null` and `_remainingTurns.length > 1` and the first turn is a U-turn, the U-turn step is discarded — it was produced by the Directions API because it had no heading context
- Called once when the AR Navigation Screen first loads, and again after each reroute (`recalculateRoute()`) or accepted faster route (`acceptFasterRoute()`)
- Rerouting always hands this a fresh list of `TurnInstruction` objects, even when the upcoming real-world turn hasn't changed. If the new head turn matches the previous `_lastHeadTurn` by direction and position (within 20 m), the old reference is carried forward instead of being treated as a new turn — otherwise the next `updateAROverlay()` tick would reset the voice-announcement dedup state and re-speak the same announcement mid-utterance

---

### Voice mute (`SettingsViewModel.voiceMuted`)

**Purpose:** `ARViewModel` no longer owns its own mute flag — `SettingsViewModel.voiceMuted` (see [§11](#11-settingsviewmodel)) is the single source of truth, so the AR screen's mute button and the Settings screen's "Mute Voice Guidance" toggle always agree and the choice survives an app restart.

**Notes:**
- `ARViewModel`'s constructor now requires a `SettingsViewModel settingsViewModel` argument (in addition to `arService`); it reads `_settingsViewModel.voiceMuted` directly wherever `voiceGuidanceEnabled` used to be checked — inside `_checkVoiceAnnouncement()`, `_checkFinalLegAnnouncement()`, and `announceArrival()` — skipping the `VoiceService.speak()` call entirely when muted
- `ARViewModel` also registers a listener on `SettingsViewModel` (`_onSettingsChanged`) that detects the specific `false → true` mute transition — regardless of which UI triggered it — and calls `VoiceService.stop()` immediately, so muting cuts off an in-progress announcement rather than letting it finish. `dispose()` removes this listener.
- There is no `toggleVoiceGuidance()` method anymore; UI code toggles the setting directly via `settingsVM.setVoiceMuted(!settingsVM.voiceMuted)`

---

### `resetOverlay()`

```dart
void resetOverlay()
```

**Purpose:** Clears all AR overlay state when navigation ends or reroutes.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Resets `nextTurnDirection`, `distanceToNextTurn`, and `currentStreetName` to null
- Calls `ARService.clearOverlays()`

---

## 8. MapViewModel

**File:** `lib/viewmodels/map_viewmodel.dart`  
**Purpose:** Handles GPS tracking and destination search. Extends `ChangeNotifier`.

---

### `startLocationTracking()`

```dart
Future<void> startLocationTracking()
```

**Purpose:** Begins listening to the GPS stream and updates `currentLocation`, `currentHeading`, and `currentAccuracy`.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- First calls `LocationService.getCurrentLocation()` for an immediate one-shot GPS fix so the map centres without waiting for the stream's `distanceFilter` to trigger
- Then subscribes to `LocationService.getLocationStream()` for continuous updates
- Updates `currentHeading` and `currentAccuracy` from `LocationService` on every GPS event
- On each update during active navigation, calls `NavigationViewModel.checkIfArrived()` and `ARViewModel.updateAROverlay()`

---

### `currentHeading`

```dart
double? currentHeading
```

**Purpose:** The user's current direction of travel in degrees (0 = North, clockwise). Null when stationary or unavailable.

**Notes:**
- Sourced from `Position.heading` via `geolocator`; values less than 0 (returned when heading is unavailable) are converted to `null`
- Used by `HomeScreen` to rotate the Waze-style location arrow marker

---

### `currentAccuracy`

```dart
double? currentAccuracy
```

**Purpose:** The GPS accuracy radius in metres for the most recent position fix.

**Notes:**
- Used by `HomeScreen` to draw the semi-transparent accuracy ring around the user's map position

---

### `stopLocationTracking()`

```dart
void stopLocationTracking()
```

**Purpose:** Stops the GPS stream subscription.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Call when navigation ends to stop unnecessary battery drain

---

### `searchDestination()`

```dart
Future<void> searchDestination(String query)
```

**Purpose:** Fetches place suggestions for the search bar autocomplete.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `query` | `String` | Text typed by the user in the search bar |

**Returns:** Nothing

**Notes:**
- Calls `PlacesRepository.searchPlaces(query)`
- Updates `searchResults` list and notifies listeners
- The Home Screen search bar rebuilds its dropdown from `searchResults`

---

### `selectDestination()`

```dart
Future<void> selectDestination(PlaceModel place)
```

**Purpose:** Handles the user tapping on a search result — fetches full place details then loads preview routes.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `place` | `PlaceModel` | The place the user selected from the dropdown |

**Returns:** Nothing

**Notes:**
- Calls `PlacesRepository.getPlaceDetails()` to resolve full coordinates
- Sets `selectedDestination`, clears `searchResults`, sets `isFetchingRoute = true`, then calls the internal `_fetchPreviewRoute()`
- The Home Screen bottom sheet switches to route preview mode once `selectedDestination` is non-null

---

### `setSelectedDestination()`

```dart
void setSelectedDestination(PlaceModel place)
```

**Purpose:** Sets a fully-resolved place (coordinates already present) as the destination and fetches preview routes — used by quick-access buttons (Home/Work/Favourite) and recent history entries.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `place` | `PlaceModel` | A `PlaceModel` that already has valid `coordinates` |

**Returns:** Nothing

**Notes:**
- Skips the `getPlaceDetails()` call since coordinates are already known
- Immediately calls `_fetchPreviewRoute()` after setting the destination

---

### `clearDestination()`

```dart
void clearDestination()
```

**Purpose:** Clears the selected destination, all preview routes, and resets route-selection state.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Called when the user taps **Cancel** on the route preview panel
- Resets `selectedDestination`, `previewRoutes`, `selectedRouteIndex`, `isFetchingRoute`, and `searchResults`

---

### `selectRoute()`

```dart
void selectRoute(int index)
```

**Purpose:** Changes the active route selection in the preview panel.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `index` | `int` | Zero-based index into `previewRoutes` |

**Returns:** Nothing

**Notes:**
- Guards against out-of-range indices
- Notifies listeners so the map and route list rebuild with the newly selected route highlighted

---

### `refreshPreviewRoute()`

```dart
Future<void> refreshPreviewRoute()
```

**Purpose:** Re-fetches preview routes from the user's **current GPS position** as the new origin. Called by the Routes button in `NavigationBottomBar` when returning to route selection during active navigation.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Increments `routeVersion`, which signals `HomeMapController` to reset `_routeFitted = false` and re-fit the camera to the updated route bounds
- Resets `selectedRouteIndex` to `0` and sets `isFetchingRoute = true` while the request is in flight
- Has no effect if `selectedDestination` is null

---

### Key properties

| Property | Type | Description |
|---|---|---|
| `previewRoutes` | `List<RouteModel>` | Up to 3 alternative routes fetched after a destination is set |
| `selectedRouteIndex` | `int` | Index of the currently highlighted route (default `0`) |
| `selectedRoute` | `RouteModel?` | Convenience getter: `previewRoutes[selectedRouteIndex]`, or `null` if empty |
| `isFetchingRoute` | `bool` | `true` while a route request is in flight |
| `routeVersion` | `int` | Incremented by `refreshPreviewRoute()`; read by `HomeMapController` to trigger camera re-fit |

---

## 9. RecentPlacesRepository

**File:** `lib/repositories/recent_places_repository.dart`
**Purpose:** Persists up to 8 recently navigated places in `shared_preferences` as a JSON-encoded string list.

---

### `getAll()`

```dart
Future<List<PlaceModel>> getAll()
```

**Purpose:** Reads and returns all stored recent places, ordered newest-first.

**Parameters:** None

**Returns:** `List<PlaceModel>` — decoded recent places; malformed entries are silently skipped

---

### `add()`

```dart
Future<void> add(PlaceModel place)
```

**Purpose:** Prepends a place to the recent list, removes any existing duplicate, and trims to 8 entries.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `place` | `PlaceModel` | The place to record |

**Returns:** Nothing

**Notes:**
- Deduplication is by `placeId` — same place selected twice moves it to position 0 rather than creating a duplicate

---

### `clear()`

```dart
Future<void> clear()
```

**Purpose:** Removes the entire recent history from `shared_preferences`.

**Parameters:** None

**Returns:** Nothing

---

## 10. RecentPlacesViewModel

**File:** `lib/viewmodels/recent_places_viewmodel.dart`
**Purpose:** Exposes the recent search history list to the Home Screen. Extends `ChangeNotifier`.

---

### `load()`

```dart
Future<void> load()
```

**Purpose:** Reads persisted recent places from `RecentPlacesRepository` and notifies listeners.

**Notes:** Called automatically on app start via `..load()` in `app.dart`'s provider initialiser.

---

### `add()`

```dart
Future<void> add(PlaceModel place)
```

**Purpose:** Records a place as recently used, persists it, reloads the list, and notifies listeners.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `place` | `PlaceModel` | The destination the user just selected |

---

### `clear()`

```dart
Future<void> clear()
```

**Purpose:** Wipes the full recent history and notifies listeners.

---

### Key properties

| Property | Type | Description |
|---|---|---|
| `places` | `List<PlaceModel>` | Ordered recent places list (newest first, max 8) |

---

## 11. SettingsViewModel

**File:** `lib/viewmodels/settings_viewmodel.dart`  
**Purpose:** Manages user preferences, persisted via `shared_preferences`. Extends `ChangeNotifier`.

> **Dependency:** Add `shared_preferences: ^2.2.0` to `pubspec.yaml`.

Every preference follows the same shape: a synchronous getter reads the in-memory field (already loaded at startup by `_loadSettings()`), and an async `setXxx()` method updates the field, calls `notifyListeners()`, then persists the new value to `shared_preferences` — in that order, so the UI updates immediately and doesn't wait on the write. All getters are populated from `shared_preferences` once, in `_loadSettings()`, which runs from the constructor and is awaited nowhere (fire-and-forget); until it completes, getters return the hardcoded defaults listed below.

| Property | Type | Default | Key | Setter |
|---|---|---|---|---|
| `navigationMode` | `String` | `'AR'` | `'navigation_mode'` | `setNavigationMode(String mode)` |
| `distanceUnit` | `String` | `'km'` | `'distance_unit'` | `setDistanceUnit(String unit)` |
| `showSpeed` | `bool` | `true` | `'show_speed'` | `setShowSpeed(bool value)` |
| `showETA` | `bool` | `true` | `'show_eta'` | `setShowETA(bool value)` |
| `arrowSize` | `String` | `'Medium'` | `'arrow_size'` | `setArrowSize(String size)` |
| `overlayOpacity` | `double` | `1.0` | `'overlay_opacity'` | `setOverlayOpacity(double opacity)` |
| `avoidTolls` | `bool` | `false` | `'avoid_tolls'` | `setAvoidTolls(bool value)` |
| `autoBrightness` | `bool` | `true` | `'auto_brightness'` | `setAutoBrightness(bool value)` |
| `voiceMuted` | `bool` | `false` | `'voice_muted'` | `setVoiceMuted(bool value)` |

---

### `navigationMode` / `setNavigationMode()`

**Purpose:** Active navigation mode — locked to AR in the current version; the toggle is visible in Settings but disabled until 2D mode is implemented. Setting `'2D'` has no effect until the 2D screen is built.

---

### `distanceUnit` / `setDistanceUnit()`

**Purpose:** Preferred distance unit — `'km'` or `'miles'`. Read by `ARViewModel`/`DynamicArrowWidget` when formatting distance labels on the AR overlay.

---

### `showSpeed` / `setShowSpeed()`

**Purpose:** Whether the speed display is shown during navigation.

---

### `showETA` / `setShowETA()`

**Purpose:** Whether the ETA display is shown during navigation.

---

### `arrowSize` / `setArrowSize()`

**Purpose:** Preferred AR arrow size — `'Small'`, `'Medium'`, or `'Large'`.

---

### `overlayOpacity` / `setOverlayOpacity()`

**Purpose:** AR overlay opacity, applied to the AR overlay widget's `Opacity` wrapper when `autoBrightness` is `false`.

**Notes:**
- `setOverlayOpacity()` clamps the incoming value to `[0.5, 1.0]` before storing and persisting it

---

### `avoidTolls` / `setAvoidTolls()`

**Purpose:** Whether toll roads should be avoided when routing. Read by `NavigationViewModel`/`MapViewModel` and passed as `avoidTolls` to `RouteRepository.getRoute()`.

---

### `autoBrightness` / `setAutoBrightness()`

**Purpose:** Whether the AR arrow's opacity/colour is driven automatically by the ambient light sensor (default `true`).

**Notes:**
- When `true`, `ARNavigationScreen` starts `AmbientLightService` and ignores `overlayOpacity` for the main AR arrow; when `false`, the sensor is stopped and `overlayOpacity` is used instead
- `ARNavigationScreenState._syncAmbientLight()` starts/stops `AmbientLightService` in response to this value changing, without restarting the sensor on every rebuild

---

### `voiceMuted` / `setVoiceMuted()`

**Purpose:** Single source of truth for whether spoken turn-by-turn voice guidance is muted. Read directly by `ARViewModel` wherever it used to check its own (now-removed) `voiceGuidanceEnabled` flag — see [§7](#7-arviewmodel).

**Notes:**
- Written by both the AR screen's mute button (`onPressed: () => settingsVM.setVoiceMuted(!settingsVM.voiceMuted)`) and the Settings screen's "Mute Voice Guidance" `SwitchListTile` in `NavigationSection` — since both write through the same field and the AR screen reads it via `context.watch<SettingsViewModel>()`, muting from either place is immediately reflected in the other and on next AR screen load
- `ARViewModel` additionally listens for the mute transition specifically (not just any settings change) so it can stop an in-progress announcement the instant the app is muted — see [§7](#7-arviewmodel)

---

## 12. Utility Functions

**File:** `lib/core/utils/location_utils.dart`  
**Purpose:** Helper functions for location calculations.

---

### `calculateDistance()`

```dart
double calculateDistance(LatLng point1, LatLng point2)
```

**Purpose:** Calculates the straight-line distance in metres between two GPS coordinates.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `point1` | `LatLng` | First GPS coordinate |
| `point2` | `LatLng` | Second GPS coordinate |

**Returns:** `double` — distance in metres

**Notes:**
- Uses `Geolocator.distanceBetween()` internally
- Used to check if the user has arrived or gone off-route

---

### `_distanceToSegment()`

```dart
double _distanceToSegment(LatLng p, LatLng a, LatLng b)
```

**File:** `lib/viewmodels/map_viewmodel.dart` (private helper)

**Purpose:** Returns the shortest distance in metres from point `p` to the line segment `a → b` using a flat-earth lat/lng projection.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `p` | `LatLng` | The point to measure from (current GPS position) |
| `a` | `LatLng` | Start of the segment |
| `b` | `LatLng` | End of the segment |

**Returns:** `double` — perpendicular distance in metres (or distance to the nearer endpoint if the perpendicular falls outside the segment)

**Notes:**
- Used by `_isOffRoute()` in `MapViewModel` to check against every consecutive pair of polyline waypoints, taking the minimum — this handles sparse polylines where vertices are 50–100 m apart on highways
- Replaced the previous vertex-only check that was causing false reroutes from GPS drift on dual carriageways

---

### `findNextTurn()`

```dart
TurnInstruction? findNextTurn(LatLng currentLocation, List<TurnInstruction> turns)
```

**Purpose:** Finds the next upcoming turn instruction based on the user's current position.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `currentLocation` | `LatLng` | The user's current GPS position |
| `turns` | `List<TurnInstruction>` | All turn instructions from the `RouteModel` |

**Returns:** `TurnInstruction?` — the next upcoming turn, or `null` if no more turns

**Notes:**
- Iterates through the turns list and returns the first one the user hasn't passed yet
- A turn is considered "passed" when the user is within 10 metres of its position
- **Deprecated usage:** As of v1.3, `ARViewModel.updateAROverlay()` no longer calls `findNextTurn()`. The ViewModel removes passed turns with a 25 m threshold via `removeWhere`, then uses `List.firstWhere` directly on `_remainingTurns`. `findNextTurn` remains in `location_utils.dart` and may be used by other callers.

---

## 13. Enums & Constants

**File:** `lib/core/enums/turn_direction.dart`

```dart
enum TurnDirection {
  forward,     // Go straight
  left,        // Turn left (sharp or normal)
  right,       // Turn right (sharp or normal)
  keepLeft,    // Slight left / keep left / ramp left / fork left
  keepRight,   // Slight right / keep right / ramp right / fork right
  uTurn,       // Make a U-turn (left or right)
  roundabout,  // Enter roundabout — exit number shown in centre of diagram
}
```

---

**File:** `lib/core/enums/navigation_status.dart`

```dart
enum NavigationStatus {
  idle,        // No active navigation session
  loading,     // Fetching route data
  navigating,  // Active navigation in progress
  rerouting,   // Recalculating route
  arrived,     // User has reached the destination
}
```

---

**File:** `lib/core/enums/navigation_approach_stage.dart`

```dart
enum NavigationApproachStage {
  far,         // > 200 m to next turn — arrow is cyan, slow pulse
  approaching, // 50–200 m to next turn — arrow turns amber, medium pulse
  imminent,    // < 50 m to next turn — arrow turns red, fast pulse
}
```

Used by `DynamicArrowWidget` to drive arrow colour and pulse animation speed. `ARViewModel.approachStage` computes the stage from `distanceToNextTurn`:
- `d == null || d > 200` → `far`
- `d > 50` → `approaching`
- otherwise → `imminent`

---

**File:** `lib/core/enums/traffic_severity.dart`

```dart
enum TrafficSeverity {
  moderate, // 20–50% delay vs free-flow duration — amber badge
  heavy,    // > 50% delay vs free-flow duration — red badge
}
```

Set by `RouteRepository.getTrafficSeverityAhead()` and carried on `TrafficSegmentInfo.severity`; consumed by `TrafficDelayBadge` (see [§17](#17-trafficdelaybadge)) to pick the badge's background/foreground colours.

---

**File:** `lib/models/traffic_segment_info.dart`

```dart
class TrafficSegmentInfo {
  final int delayMinutes;             // Estimated delay in minutes vs free-flow
  final LatLng segmentStartPosition;  // Where the checked ~2 km segment begins (current location at check time)
  final LatLng segmentEndPosition;    // Where the checked segment ends
  final TrafficSeverity severity;     // moderate or heavy
}
```

Immutable value object returned by `RouteRepository.getTrafficSeverityAhead()` and stored on `NavigationViewModel.trafficSegmentInfo`.

---

**File:** `lib/core/constants/app_strings.dart`

```dart
// Key UI strings used across the app
const String appName = 'Smart AR Navigate';
const String searchHint = 'Where to?';
const String startNavigation = 'Start AR Navigation';
const String stopNavigation = 'Stop';
const String arrivedMessage = 'You have arrived!';
const String reroutingMessage = 'Recalculating route...';
const String noInternetMessage = 'No internet connection.';
const String locationPermissionMessage = 'Location permission is required for navigation.';
const String cameraPermissionMessage = 'Camera permission is required for AR navigation.';
```

---

**File:** `lib/core/constants/app_colors.dart`

```dart
import 'package:flutter/material.dart';

const Color primaryColor       = Color(0xFF1A73E8);  // Deep Blue
const Color arArrowColor       = Color(0xFF00E676);  // Bright Green
const Color warningColor       = Color(0xFFFFC107);  // Amber
const Color overlayBackground  = Color(0x99000000);  // Semi-transparent Black
const Color textPrimary        = Color(0xFF212121);  // Dark Grey
```

---

## 14. DynamicArrowWidget

**File:** `lib/views/widgets/dynamic_arrow_widget.dart`  
**Purpose:** A `StatefulWidget` that renders all 7 turn-direction AR arrows using `CustomPainter`. Replaces the older `TurnArrowWidget`, `AROverlayWidget`, and `RoundaboutWidget`.

### Constructor

```dart
DynamicArrowWidget({
  required TurnDirection direction,
  required double distance,
  required NavigationApproachStage approachStage,
  double? size,          // canvas side length in logical pixels (default: fills parent)
  bool showLabel = true, // whether to draw the direction label below the arrow
  int? exitNumber,       // roundabout exit number (1–4); only shown when direction == roundabout
  double opacityOverride = 0.85, // overall widget opacity; driven by ambient light level or the manual opacity slider
  Color? colorOverride,  // overrides the 'far' stage colour only; null = default arArrowColor
})
```

### Behaviour

| Parameter | Effect |
|---|---|
| `direction` | Selects which arrow shape is drawn (chevrons, U-arc, or roundabout arc) |
| `distance` | Passed to `approachStage` for colour; also drives pulse speed |
| `approachStage` | `far` → cyan (or `colorOverride`) / slow pulse; `approaching` → amber / medium pulse; `imminent` → red / fast pulse |
| `exitNumber` | When non-null and `direction == roundabout`, the number is rendered in bold white at the arc centre |
| `opacityOverride` | Replaces the widget's outer `Opacity` value (previously hardcoded to `0.85`); set from `AmbientLightService.levelNotifier` or `SettingsViewModel.overlayOpacity` by `ARNavigationScreen` |
| `colorOverride` | When non-null, replaces `arArrowColor` for the `far` approach stage only — `approaching` (amber) and `imminent` (red) are left untouched so the urgency colours are never masked |

### Arrow shapes

| `direction` | Shape |
|---|---|
| `forward` | 3 upward chevrons with 12 px stroke and flow-wave opacity animation |
| `right` | Same chevrons rotated 90° CW |
| `left` | Mirror of right (x-flip + 90° CW) |
| `keepRight` | 2 chevrons at 80 % scale, −15° tilt, 90° CW |
| `keepLeft` | Mirror of keepRight |
| `uTurn` | U-shaped arc (clockwise 180°) with downward arrowhead, 12 px stroke |
| `roundabout` | 270° CCW arc, exit arrowhead at 9-o'clock, entry indicator at 135°, exit number centred |

All shapes use a 24 px glow layer (alpha 0.3) beneath the 12 px main stroke and rounded `StrokeCap`.

---

## 15. AmbientLightService

**File:** `lib/services/ambient_light_service.dart`
**Purpose:** Wraps the `light` package's ambient light sensor stream and exposes a debounced `LightLevel` for driving AR arrow auto-brightness.

```dart
enum LightLevel { bright, normal, dark }
```

---

### `start()`

```dart
void start()
```

**Purpose:** Begins listening to `Light().lightSensorStream`.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Idempotent — calling `start()` while already subscribed is a no-op
- Wraps `.listen()` in a `try/catch` (synchronous setup failures, e.g. platform channel unavailable) **and** passes an `onError` callback to `.listen()` (asynchronous stream errors, e.g. sensor missing or unauthorized) — either failure path logs via `debugPrint` and leaves `levelNotifier` at its default `LightLevel.normal`
- Called by `ARNavigationScreenState` when `SettingsViewModel.autoBrightness` is `true`

---

### `stop()`

```dart
void stop()
```

**Purpose:** Cancels the sensor stream subscription and any pending debounce timer.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Idempotent — safe to call when not started
- Called when the user turns off the "Auto Brightness" setting, or from `dispose()`

---

### `dispose()`

```dart
void dispose()
```

**Purpose:** Stops the sensor and disposes `levelNotifier`.

**Notes:** Always call this in the owning widget's `dispose()` — `ARNavigationScreenState` does so.

---

### `levelNotifier`

```dart
ValueNotifier<LightLevel> levelNotifier
```

**Purpose:** The current debounced ambient light level; consumed via `ValueListenableBuilder<LightLevel>` in `ARNavigationScreen`.

**Notes:**
- Thresholds: lux > 1000 → `bright`; lux < 100 → `dark`; otherwise → `normal`
- A level change is only committed after the new *pending* level has been the latest reading continuously for 2 seconds — the debounce timer restarts only when the pending target level itself changes, not on every sensor reading, so it reliably fires even under a fast sensor sample rate

---

## 16. VoiceService

**File:** `lib/services/voice_service.dart`
**Purpose:** Wraps `flutter_tts` to speak turn-by-turn voice announcements.

---

### `initialize()`

```dart
Future<void> initialize()
```

**Purpose:** Configures the TTS engine — language, speech rate, volume, and navigation-style audio ducking.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Sets language to `'en-US'`, speech rate to `0.5`, volume to `1.0`
- Calls `setAudioAttributesForNavigation()` to request transient "duck" audio focus (lowers other apps' volume instead of pausing them), matching how turn-by-turn navigation apps announce guidance over music/podcasts
- Should be called once during setup, before the first `speak()` call

---

### `speak()`

```dart
Future<void> speak(String text)
```

**Purpose:** Speaks the given announcement text.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `text` | `String` | The announcement to speak, built by `ARViewModel._buildVoiceInstruction()` |

**Returns:** Nothing

**Notes:**
- Always calls `_tts.stop()` before `_tts.speak(text)`, so any still-playing announcement is cut off and immediately replaced rather than queued — this is intentional (a new announcement should always take priority over a stale one) but means two `speak()` calls with the same text in quick succession will audibly sound like the first one was interrupted and restarted

---

### `stop()`

```dart
void stop()
```

**Purpose:** Cancels any in-progress speech immediately.

**Notes:** Called by `ARViewModel.resetOverlay()` on navigation stop/arrival, so speech doesn't continue after navigation ends.

---

### `dispose()`

```dart
void dispose()
```

**Purpose:** Stops any in-progress speech. Owned and disposed by `ARViewModel`.

---

## 17. TrafficDelayBadge

**File:** `lib/views/widgets/traffic_delay_badge.dart`  
**Purpose:** A `StatelessWidget` that renders the traffic-delay pill shown on the AR screen when `NavigationViewModel.trafficSegmentInfo` is non-null and the driver is within range.

### Constructor

```dart
TrafficDelayBadge({
  required TrafficSegmentInfo segmentInfo,
  required bool hasEnteredSegment,
  double? distanceAheadKm, // required when hasEnteredSegment == false
  double? jamLengthKm,     // required when hasEnteredSegment == true
})
```

### Behaviour

| Parameter | Effect |
|---|---|
| `segmentInfo` | Supplies `delayMinutes` (first line, e.g. "6 min jam") and `severity`, which selects the pill's colours |
| `hasEnteredSegment` | Selects which of the two second-line states to render — the pill's shape/colour/icon is identical either way, only the text changes |
| `distanceAheadKm` | Second line reads "X.X km ahead" when `hasEnteredSegment == false` |
| `jamLengthKm` | Second line reads "X.X km jam" when `hasEnteredSegment == true` |

**Colours:** `TrafficSeverity.moderate` → amber background (`0xFFFFA726`) with a near-black amber foreground (`0xFF3D2400`, ~7:1 contrast); `TrafficSeverity.heavy` → red background (`0xFFE53935`) with a near-black red foreground (`0xFF260000`, ~4.6:1 contrast). Foreground shades are drawn from the same hue family as the background rather than a generic dark grey, so the two severities stay visually distinct even to a driver glancing quickly.

### Placement & lifecycle (in `ARNavigationScreen`)

- Not rendered at all when `trafficSegmentInfo == null`
- When `hasEnteredTrafficSegment == true`: always shown, with `hasEnteredSegment: true` and `jamLengthKm` computed as the distance between the segment's start/end positions
- When `hasEnteredTrafficSegment == false`: only shown once `distanceAheadKm` (distance from the current GPS position to the segment start) is `≤ 2.0` — suppressed entirely while farther away, so the badge doesn't appear the moment a distant jam is detected
- Positioned centred, anchored to the same row as `SpeedIndicator` near the bottom of the AR screen

---

*End of API & Function Documentation — Version 1.7*

*Prepared by: Liew Sau Yang | Sunway University | Bachelor of Software Engineering (Hons)*
