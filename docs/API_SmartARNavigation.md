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
| **Version** | 1.0 (Basic — Core Functions) |
| **Last Updated** | October 2025 |

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
9. [SettingsViewModel](#9-settingsviewmodel)
10. [Utility Functions](#10-utility-functions)
11. [Enums & Constants](#11-enums--constants)

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
Future<RouteModel> getRoute({
  required LatLng origin,
  required LatLng destination,
})
```

**Purpose:** Fetches a walking route from origin to destination using Google Maps Directions API.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `origin` | `LatLng` | The user's current GPS location |
| `destination` | `LatLng` | The user's chosen destination |

**Returns:** `RouteModel` — contains waypoints, turn instructions, distance, and duration

**Notes:**
- Makes an HTTP GET request to `maps.googleapis.com/maps/api/directions/json`
- Uses `mode=walking` by default (suitable for FYP demo)
- Throws a `RouteNotFoundException` if no route is found
- Throws a `NetworkException` if the device has no internet

---

### `parseRouteResponse()`

```dart
RouteModel parseRouteResponse(Map<String, dynamic> json)
```

**Purpose:** Parses the raw JSON response from Google Maps Directions API into a `RouteModel` object.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `json` | `Map<String, dynamic>` | Raw JSON response from the Directions API |

**Returns:** `RouteModel` — clean data object ready for use in the app

**Notes:**
- This is a private helper function called internally by `getRoute()`
- Extracts steps, distance, duration, and waypoint coordinates from the JSON

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
void startLocationTracking()
```

**Purpose:** Begins listening to the GPS stream and updates `currentLocation`.

**Parameters:** None

**Returns:** Nothing

**Notes:**
- Subscribes to `LocationService.getLocationStream()`
- On each GPS update, calls `NavigationViewModel.checkIfArrived()` and `ARViewModel.updateAROverlay()`

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

**Purpose:** Handles the user tapping on a search result.

**Parameters:**
| Parameter | Type | Description |
|---|---|---|
| `place` | `PlaceModel` | The place the user selected from the dropdown |

**Returns:** Nothing

**Notes:**
- Calls `PlacesRepository.getPlaceDetails()` to get the full coordinates
- Sets `selectedDestination` and notifies listeners
- The Home Screen will show the "Start AR Navigation" button once this is set

---

## 9. SettingsViewModel

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

## 10. Utility Functions

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

## 11. Enums & Constants

**File:** `lib/core/enums/turn_direction.dart`

```dart
enum TurnDirection {
  forward,   // Go straight
  left,      // Turn left
  right,     // Turn right
  uTurn,     // Make a U-turn
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

> 📝 **Note:** This is Version 1.0 — Basic Core Functions.
> A more detailed version with full code examples, error handling patterns,
> and edge case documentation will be added in a future revision.

---

*End of API & Function Documentation — Version 1.0*

*Prepared by: Liew Sau Yang | Sunway University | Bachelor of Software Engineering (Hons)*
