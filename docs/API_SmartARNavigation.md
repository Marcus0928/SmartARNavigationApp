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
| **Version** | 1.1 |
| **Last Updated** | May 2026 |

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
- Extracts roundabout exit numbers (e.g. "2nd exit") via regex from `html_instructions`

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
Future<bool> initializeAR()
```

**Purpose:** Initializes the ARCore session on the device.

**Parameters:** None

**Returns:** `bool` — `true` if ARCore initialized successfully, `false` otherwise

**Notes:**
- Call this when the AR Navigation Screen loads
- Will return `false` on devices that don't support ARCore

---

### `placeArrow()`

```dart
void placeArrow(TurnDirection direction, double distance)
```

**Purpose:** Places a directional arrow AR overlay on the camera feed.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `direction` | `TurnDirection` | The direction of the next turn (forward, left, right, uTurn) |
| `distance` | `double` | Distance in metres to the next turn |

**Returns:** Nothing

**Notes:**
- Uses ARCore anchor nodes to attach the arrow to the real-world environment
- Call this every time `ARViewModel.nextTurnDirection` changes

---

### `updateArrow()`

```dart
void updateArrow(TurnDirection direction, double distance)
```

**Purpose:** Updates the existing AR arrow overlay with new direction and distance values.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `direction` | `TurnDirection` | Updated turn direction |
| `distance` | `double` | Updated distance in metres |

**Returns:** Nothing

**Notes:**
- More efficient than removing and re-placing the arrow each GPS update
- Called on every GPS stream update during active navigation

---

### `clearOverlays()`

```dart
void clearOverlays()
```

**Purpose:** Removes all AR overlays from the camera feed.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Call this when navigation ends or is stopped by the user
- Also call this before placing a new set of overlays after rerouting

---

### `disposeAR()`

```dart
void disposeAR()
```

**Purpose:** Properly closes and disposes the ARCore session.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Always call this in the `dispose()` method of the AR Navigation Screen
- Failing to dispose will cause memory leaks

---

## 6. NavigationViewModel

**File:** `lib/viewmodels/navigation_viewmodel.dart`  
**Purpose:** Manages the overall navigation session state. Extends `ChangeNotifier`.

---

### `startNavigation()`

```dart
Future<void> startNavigation(PlaceModel destination)
```

**Purpose:** Starts a navigation session to the selected destination.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `destination` | `PlaceModel` | The place the user wants to navigate to |

**Returns:** Nothing

**Notes:**
- Fetches the current location, then calls `RouteRepository.getRoute()`
- Sets `navigationStatus` to `NavigationStatus.navigating`
- Notifies listeners so the UI navigates to the AR screen

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
- Triggered automatically when GPS position deviates more than 30 metres from the route
- Uses the current GPS location as the new origin
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
- Finds the next upcoming `TurnInstruction` from the current `RouteModel`
- Updates `nextTurnDirection`, `distanceToNextTurn`, and `currentStreetName`
- Notifies listeners so the AR overlay widget rebuilds

---

### `initializeOverlay()`

```dart
Future<void> initializeOverlay(RouteModel route)
```

**Purpose:** Sets up the AR overlay when navigation first starts.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `route` | `RouteModel` | The route fetched from `RouteRepository` |

**Returns:** Nothing

**Notes:**
- Stores the route and places the first AR arrow for the first turn
- Called once when the AR Navigation Screen first loads

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

### Key properties

| Property | Type | Description |
|---|---|---|
| `previewRoutes` | `List<RouteModel>` | Up to 3 alternative routes fetched after a destination is set |
| `selectedRouteIndex` | `int` | Index of the currently highlighted route (default `0`) |
| `selectedRoute` | `RouteModel?` | Convenience getter: `previewRoutes[selectedRouteIndex]`, or `null` if empty |
| `isFetchingRoute` | `bool` | `true` while a route request is in flight |

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

---

### `getNavigationMode()`

```dart
Future<String> getNavigationMode()
```

**Purpose:** Reads the saved navigation mode preference from persistent storage.

**Parameters:** None

**Returns:** `String` — `'AR'` (default; locked to AR in the current version)

**Notes:**
- Key: `'navigation_mode'`
- Always returns `'AR'` for now; the toggle is visible but disabled until 2D mode is implemented

---

### `setNavigationMode()`

```dart
Future<void> setNavigationMode(String mode)
```

**Purpose:** Saves the navigation mode preference.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `mode` | `String` | Navigation mode — `'AR'` or `'2D'` |

**Returns:** Nothing

**Notes:**
- Key: `'navigation_mode'`
- Currently only `'AR'` is accepted; setting `'2D'` has no effect until the 2D screen is built

---

### `getDistanceUnit()`

```dart
Future<String> getDistanceUnit()
```

**Purpose:** Reads the saved distance unit preference.

**Parameters:** None

**Returns:** `String` — `'km'` (default) or `'miles'`

**Notes:**
- Key: `'distance_unit'`
- Used by `ARViewModel` when formatting distance labels on the AR overlay

---

### `setDistanceUnit()`

```dart
Future<void> setDistanceUnit(String unit)
```

**Purpose:** Saves the distance unit preference.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `unit` | `String` | `'km'` or `'miles'` |

**Returns:** Nothing

**Notes:**
- Key: `'distance_unit'`
- Notifies listeners so the AR overlay updates immediately

---

### `getShowSpeed()`

```dart
Future<bool> getShowSpeed()
```

**Purpose:** Reads whether the speed display should be visible during navigation.

**Parameters:** None

**Returns:** `bool` — `true` (default, speed shown) or `false`

**Notes:**
- Key: `'show_speed'`

---

### `setShowSpeed()`

```dart
Future<void> setShowSpeed(bool value)
```

**Purpose:** Saves the show-speed toggle state.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `value` | `bool` | `true` to show speed, `false` to hide it |

**Returns:** Nothing

**Notes:**
- Key: `'show_speed'`

---

### `getShowETA()`

```dart
Future<bool> getShowETA()
```

**Purpose:** Reads whether the ETA display should be visible during navigation.

**Parameters:** None

**Returns:** `bool` — `true` (default, ETA shown) or `false`

**Notes:**
- Key: `'show_eta'`

---

### `setShowETA()`

```dart
Future<void> setShowETA(bool value)
```

**Purpose:** Saves the show-ETA toggle state.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `value` | `bool` | `true` to show ETA, `false` to hide it |

**Returns:** Nothing

**Notes:**
- Key: `'show_eta'`

---

### `getArrowSize()`

```dart
Future<String> getArrowSize()
```

**Purpose:** Reads the preferred AR arrow size.

**Parameters:** None

**Returns:** `String` — `'Medium'` (default), `'Small'`, or `'Large'`

**Notes:**
- Key: `'arrow_size'`
- Used by `ARService` when placing or updating AR arrow anchors

---

### `setArrowSize()`

```dart
Future<void> setArrowSize(String size)
```

**Purpose:** Saves the AR arrow size preference.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `size` | `String` | `'Small'`, `'Medium'`, or `'Large'` |

**Returns:** Nothing

**Notes:**
- Key: `'arrow_size'`

---

### `getOverlayOpacity()`

```dart
Future<double> getOverlayOpacity()
```

**Purpose:** Reads the preferred AR overlay opacity.

**Parameters:** None

**Returns:** `double` — value between `0.5` and `1.0`; default is `1.0`

**Notes:**
- Key: `'overlay_opacity'`
- Applied to the AR overlay widget's `Opacity` wrapper

---

### `setOverlayOpacity()`

```dart
Future<void> setOverlayOpacity(double opacity)
```

**Purpose:** Saves the AR overlay opacity preference.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `opacity` | `double` | Opacity value clamped to `0.5`–`1.0` |

**Returns:** Nothing

**Notes:**
- Key: `'overlay_opacity'`
- Values outside `[0.5, 1.0]` are clamped before saving

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

---

*End of API & Function Documentation — Version 1.1*

*Prepared by: Liew Sau Yang | Sunway University | Bachelor of Software Engineering (Hons)*
