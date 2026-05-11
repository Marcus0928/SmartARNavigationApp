# System Design Document (SDD)

## Smart AR Navigation App for Enhanced Driving Assistance

---

| Field | Details |
|---|---|
| **Project Title** | Smart AR Navigation App for Enhanced Driving Assistance |
| **Author** | Liew Sau Yang (22062475) |
| **Supervisor** | Dr Javid Iqbal Thirupattur |
| **Institution** | Sunway University — School of Computing and Artificial Intelligence |
| **Programme** | Bachelor of Software Engineering (Hons) |
| **Version** | 2.0 |
| **Last Updated** | May 2026 |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Architecture Overview](#2-architecture-overview)
3. [MVVM Architecture Design](#3-mvvm-architecture-design)
4. [Screen & Navigation Flow](#4-screen--navigation-flow)
5. [Component Design](#5-component-design)
6. [Data Flow Design](#6-data-flow-design)
7. [Folder Structure](#7-folder-structure)
8. [External Services & Integrations](#8-external-services--integrations)
9. [UI Design Guidelines](#9-ui-design-guidelines)
10. [Future Enhancements](#10-future-enhancements)

---

## 1. Introduction

### 1.1 Purpose

This System Design Document (SDD) describes the architectural and technical design of the **Smart AR Navigation App**. It serves as the blueprint for development, outlining how each component of the system is structured, how data flows through the app, and how the app's screens and features are organized.

This document bridges the gap between the Software Requirements Specification (SRS) and the actual codebase.

### 1.2 Scope

The design covers:
- The overall app architecture (MVVM pattern)
- Screen flow and navigation logic
- Component responsibilities
- Data flow between the app and external services (ARCore, Google Maps API)
- Folder/file structure for the Flutter project

### 1.3 Design Goals

| Goal | Description |
|---|---|
| **Separation of Concerns** | UI logic is kept separate from business logic using MVVM |
| **Scalability** | The design allows new features (e.g. 2D map toggle) to be added without restructuring |
| **Readability** | Clear folder structure and naming conventions for easy maintenance |
| **Testability** | Business logic in ViewModels can be unit tested independently of the UI |

---

## 2. Architecture Overview

The app follows the **MVVM (Model-View-ViewModel)** architectural pattern. This is the recommended architecture for Flutter applications as it cleanly separates the user interface (View) from the business logic (ViewModel) and data (Model).

### 2.1 Why MVVM?

| Reason | Detail |
|---|---|
| **Flutter-friendly** | Works naturally with Flutter's `setState`, `Provider`, or `ChangeNotifier` |
| **Separation of UI & Logic** | AR overlay logic, GPS logic, and API calls live in ViewModels, not in widgets |
| **Easy to extend** | Adding a 2D map toggle screen in the future requires minimal restructuring |
| **Supervisor-friendly** | MVVM is a well-known, widely documented pattern — easy to explain and justify |

### 2.2 High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                        Flutter App                          │
│                                                             │
│  ┌─────────────────────────────────────────────────────┐   │
│  │                    VIEW LAYER                        │   │
│  │   (Flutter Widgets / Screens / UI Components)        │   │
│  │                                                      │   │
│  │   SplashScreen  │  HomeScreen  │  ARNavigationScreen │   │
│  └────────────────────────┬────────────────────────────┘   │
│                           │ observes / triggers             │
│  ┌────────────────────────▼────────────────────────────┐   │
│  │                 VIEWMODEL LAYER                      │   │
│  │         (Business Logic / State Management)          │   │
│  │                                                      │   │
│  │   NavigationViewModel  │  ARViewModel  │ MapViewModel│   │
│  └────────────────────────┬────────────────────────────┘   │
│                           │ reads / writes                  │
│  ┌────────────────────────▼────────────────────────────┐   │
│  │                   MODEL LAYER                        │   │
│  │          (Data / Repositories / Services)            │   │
│  │                                                      │   │
│  │   LocationService  │  RouteRepository  │  ARService  │   │
│  └────────────────────────┬────────────────────────────┘   │
│                           │ API calls                       │
└───────────────────────────┼─────────────────────────────────┘
                            │
          ┌─────────────────┼──────────────────┐
          │                 │                  │
   ┌──────▼──────┐  ┌───────▼──────┐  ┌───────▼──────┐
   │  ARCore     │  │ Google Maps  │  │  GPS/Location │
   │  (ar_flutter│  │  Directions  │  │  (geolocator) │
   │   _plugin)  │  │     API      │  │               │
   └─────────────┘  └──────────────┘  └───────────────┘
```

---

## 3. MVVM Architecture Design

### 3.1 Layer Responsibilities

#### 📱 View Layer
- Contains all Flutter **Widgets and Screens**
- Responsible **only** for displaying UI and capturing user input
- Observes ViewModel state changes and re-renders accordingly
- Has **no direct access** to APIs or services

#### 🧠 ViewModel Layer
- Contains all **business logic and state management**
- Uses `ChangeNotifier` + `Provider` package for state
- Calls Models/Repositories to fetch data
- Exposes data to Views via observable properties
- Examples: calculating next turn direction, managing navigation session state

#### 🗃️ Model Layer
- Contains **data classes, repositories, and services**
- Handles all external communication (Google Maps API, ARCore, GPS)
- Returns clean data objects to the ViewModel
- Has no knowledge of the UI

### 3.2 State Management

The app uses **Provider** (Flutter's recommended state management solution) to connect ViewModels to Views.

```
User taps "Start Navigation"
        ↓
View calls NavigationViewModel.startNavigation(destination)
        ↓
ViewModel calls RouteRepository.getRoute(origin, destination)
        ↓
RouteRepository calls Google Maps Directions API
        ↓
API returns route data (waypoints, turn instructions)
        ↓
ViewModel updates state (currentRoute, nextTurn, distance)
        ↓
View rebuilds AR overlays based on new ViewModel state
```

---

## 4. Screen & Navigation Flow

### 4.1 Screen List

| Screen | File | Description |
|---|---|---|
| **Splash Screen** | `splash_screen.dart` | App logo, initialization, permission checks |
| **Home Screen** | `home_screen.dart` | Full-screen 2D map (Waze-style), floating bottom search bar, top-left hamburger button opening a Waze-style side drawer |
| **AR Navigation Screen** | `ar_navigation_screen.dart` | Live camera + AR overlays + navigation info |
| **Plan Drive Screen** | `plan_drive_screen.dart` | From/To route planner with map preview, route alternatives strip, and avoid-tolls/highways options |
| **Profile Screen** | `profile_screen.dart` | User profile (name, email, avatar), navigation stats, and quick-access saved places management |
| **Settings Screen** | `settings_screen.dart` | User preferences: display options, AR settings, avoid tolls, and About info |

> 🔮 **Future Screen (if time permits):**
> | **2D Map Screen** | `map_screen.dart` | Traditional Google Maps 2D navigation view |

### 4.2 Navigation Flow Diagram

```
┌─────────────────┐
│  Splash Screen  │
│                 │
│ • Show app logo │
│ • Check camera  │
│   & location    │
│   permissions   │
│ • Initialize    │
│   ARCore &      │
│   Google Maps   │
└────────┬────────┘
         │ auto-navigate after init
         ▼
┌─────────────────────────────────────────┐
│              Home Screen                │
│                                         │
│  [≡ Menu]                               │  ← top-left hamburger button
│                                         │
│                                         │
│        [Full-Screen Google Map]         │  ← interactive 2D map (Waze-style)
│          (user's location centred)      │
│                                         │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  🔍 Where to?                     │  │  ← floating bottom search bar
│  └───────────────────────────────────┘  │
│  (autocomplete dropdown expands upward) │
│  [Start AR Nav ▶] (after destination)  │
└────────────────┬────────────────────────┘
                 │ user taps "Start AR Navigation"
                 ▼
┌─────────────────────────────────────────┐
│          AR Navigation Screen           │
│                                         │
│  [Live Camera Feed — Full Screen]       │
│                                         │
│  ┌─────────────────────────────────┐    │
│  │  AR Overlay:                    │    │
│  │  • Directional arrow            │    │
│  │  • Distance to next turn        │    │
│  │  • Street name                  │    │
│  └─────────────────────────────────┘    │
│                                         │
│  [Top Bar: Destination name]            │
│  [Bottom Bar: ETA / Distance left]      │
│  [Stop Button]                          │
│                                         │
│  🔮 Future: [Switch to 2D Map] toggle   │
└────────────────┬────────────────────────┘
                 │ user taps Stop OR arrives
                 ▼
         Back to Home Screen

─ ─ ─ ─ ─ ─ ─ ─ Menu Drawer Branch ─ ─ ─ ─ ─ ─ ─
         Home Screen [≡ Menu] tapped
                 │
                 ▼
┌─────────────────────────────────────────┐
│       Side Drawer (slides from left)    │
│                                         │
│  ┌───────────────────────────────────┐  │
│  │  [M]  Marcus                      │  │  ← avatar + name (tappable → Profile)
│  │       Smart AR Navigator          │  │
│  └───────────────────────────────────┘  │
│  ─────────────────────────────────────  │
│  ↗  Plan a drive ───────────────────────┼──┐
│  ✉  Inbox                              │  │
│  ⚙  Settings ──────────────────────────┼──┼──┐
│  ?  Help & Feedback                     │  │  │
│                                         │  │  │
│  ⏻  Shutdown (confirmation dialog)      │  │  │
└────────────────┬────────────────────────┘  │  │
                 │ user taps Back             │  │
                 ▼                           ▼  ▼
         Back to Home Screen     Plan Drive    Settings Screen
                                  Screen       │
                                  │            • Navigation Mode (locked: AR)
                                  │            • Distance unit (km / miles)
                                  │            • Avoid Tolls toggle
                                  │            • Show / hide speed display
                                  │            • Show / hide ETA display
                                  │            • AR arrow size (S/M/L)
                                  │            • AR overlay opacity (50–100%)
                                  │            • About (version + developer)
                                  │                    │ user taps Back
                                  │                    ▼
                                  │           Back to Home Screen
                                  │
                                  • From field (defaults to GPS location)
                                  • To field (destination search)
                                  • Avoid Tolls / Avoid Highways chips
                                  • Route alternatives horizontal strip
                                  • Map preview with selected route
                                  • [Start AR Navigation] button
                                          │ user taps Start
                                          ▼
                                  AR Navigation Screen

─ ─ ─ ─ ─ ─ ─ Profile Branch ─ ─ ─ ─ ─ ─ ─
         Drawer avatar/name tapped
                 │
                 ▼
┌─────────────────────────────────────────┐
│             Profile Screen              │
│                                         │
│  [Avatar: first letter of name]         │
│  Name field / Email field               │
│  [Save Profile]                         │
│                                         │
│  My Stats:                              │
│  Drives | km driven | Top destination   │
│                                         │
│  Saved Places:                          │
│  Home / Work / Favourite (editable)     │
└─────────────────────────────────────────┘
                 │ user taps Back
                 ▼
         Back to Home Screen
```

### 4.3 Permission Flow (Splash Screen)

```
App Launches
     ↓
Check Camera Permission
     ├── Granted → Check Location Permission
     └── Denied  → Show permission rationale → Request again
                        └── Permanently Denied → Show settings redirect

Check Location Permission
     ├── Granted → Initialize Services → Go to Home Screen
     └── Denied  → Show permission rationale → Request again
                        └── Permanently Denied → Show settings redirect
```

---

## 5. Component Design

### 5.1 ViewModels

#### `NavigationViewModel`
**Responsibility:** Manages the overall navigation session state. Depends on `ARViewModel` and `ProfileViewModel` — the latter is updated automatically on session end.

| Property / Method | Type | Description |
|---|---|---|
| `currentDestination` | `PlaceModel?` | The user's selected destination |
| `currentRoute` | `RouteModel?` | Active route data from Google Maps API |
| `navigationStatus` | `NavigationStatus` | Enum: idle / loading / navigating / rerouting / arrived |
| `errorMessage` | `String?` | Last navigation error, if any |
| `startNavigation(destination, {route})` | `Future<void>` | Fetches route (or uses pre-fetched route) and starts session |
| `stopNavigation()` | `void` | Ends navigation session, clears state |
| `checkIfArrived(location)` | `void` | Detects arrival (< 10 m from destination); on arrival calls `ProfileViewModel.incrementDriveCount()` and `ProfileViewModel.addDistance()` |

#### `ARViewModel`
**Responsibility:** Manages AR overlay state and rendering instructions.

| Property / Method | Type | Description |
|---|---|---|
| `nextTurnDirection` | `TurnDirection?` | Current maneuver: forward, left, right, keepLeft, keepRight, uTurn, or roundabout |
| `distanceToNextTurn` | `double?` | Distance in metres to the next turn |
| `currentStreetName` | `String?` | Name of the upcoming street (extracted from Google Maps step instruction) |
| `exitNumber` | `int?` | Roundabout exit number (1–4); non-null only when `nextTurnDirection == roundabout` |
| `isARInitialized` | `bool` | Whether ARCore session is ready |
| `initializeOverlay(route)` | `Future<void>` | Seeds the turn queue from a `RouteModel` and sets initial overlay state |
| `updateAROverlay(location)` | `void` | Drops passed turns (< 10 m) and recalculates overlay from current GPS position |
| `resetOverlay()` | `void` | Clears all overlay state (called on navigation stop or arrival) |

#### `MapViewModel`
**Responsibility:** Handles GPS location tracking and map data.

| Property / Method | Type | Description |
|---|---|---|
| `currentLocation` | `LatLng?` | User's real-time GPS coordinates |
| `currentHeading` | `double?` | Direction of travel in degrees (0 = North, clockwise); null when stationary |
| `currentAccuracy` | `double?` | GPS accuracy radius in metres |
| `startLocationTracking()` | `Future<void>` | One-shot fix then continuous GPS stream |
| `stopLocationTracking()` | `void` | Ends GPS stream |
| `searchPlaces(query)` | `Future<List<PlaceModel>>` | Returns autocomplete results |

#### `SavedPlacesViewModel`
**Responsibility:** Manages the three fixed saved-place slots (Home, Work, Favourite), persisted via `shared_preferences`.

| Property / Method | Type | Description |
|---|---|---|
| `home` | `PlaceModel?` | Saved Home location |
| `work` | `PlaceModel?` | Saved Work location |
| `favourite` | `PlaceModel?` | Saved Favourite location |
| `searchResults` | `List<PlaceModel>` | Live search results for the place-search sheet |
| `getPlace(type)` | `PlaceModel?` | Returns the saved place for a given `SavedPlaceType` |
| `selectAndSavePlace(type, place)` | `Future<void>` | Fetches full place details then persists to SharedPreferences |
| `clearPlace(type)` | `Future<void>` | Removes the saved place for a given slot |
| `searchPlace(query)` | `Future<void>` | Searches the Places API and updates `searchResults` |

#### `SavedLocationsViewModel`
**Responsibility:** Manages the user's unbounded list of bookmarked places, persisted via SQLite.

| Property / Method | Type | Description |
|---|---|---|
| `locations` | `List<PlaceModel>` | All saved locations, ordered newest-first |
| `count` | `int` | Number of saved locations |
| `isSaved(placeId)` | `bool` | O(1) check via an in-memory `Set<String>` |
| `toggle(place)` | `Future<void>` | Adds the place if not saved; removes it if already saved |
| `remove(placeId)` | `Future<void>` | Removes a specific location by its Google Places ID |

#### `SettingsViewModel`
**Responsibility:** Manages user preferences, persisted via `shared_preferences`.

| Property / Method | Type | Description |
|---|---|---|
| `navigationMode` | `String` | Active navigation mode (`'AR'` — locked in current version) |
| `distanceUnit` | `String` | Preferred unit: `'km'` or `'miles'` |
| `showSpeed` | `bool` | Whether speed display is shown during navigation |
| `showETA` | `bool` | Whether ETA display is shown during navigation |
| `arrowSize` | `String` | AR arrow size: `'Small'`, `'Medium'`, or `'Large'` |
| `overlayOpacity` | `double` | AR overlay opacity between `0.5` and `1.0` |
| `avoidTolls` | `bool` | Whether toll roads should be avoided when routing |
| `setNavigationMode(mode)` | `Future<void>` | Saves navigation mode preference |
| `setDistanceUnit(unit)` | `Future<void>` | Saves distance unit preference |
| `setShowSpeed(value)` | `Future<void>` | Saves show-speed toggle state |
| `setShowETA(value)` | `Future<void>` | Saves show-ETA toggle state |
| `setArrowSize(size)` | `Future<void>` | Saves AR arrow size preference |
| `setOverlayOpacity(opacity)` | `Future<void>` | Saves AR overlay opacity value (clamped to 0.5–1.0) |
| `setAvoidTolls(value)` | `Future<void>` | Saves avoid-tolls toggle state |

#### `ProfileViewModel`
**Responsibility:** Manages the user's profile data (name, email) and driving statistics, persisted via `shared_preferences`.

| Property / Method | Type | Description |
|---|---|---|
| `name` | `String` | User's display name |
| `email` | `String` | User's email address |
| `totalDrives` | `int` | Cumulative count of completed navigation sessions |
| `totalDistanceKm` | `double` | Cumulative distance driven in kilometres |
| `isSaving` | `bool` | True while a save operation is in progress |
| `loadProfile()` | `Future<void>` | Loads all persisted fields from `shared_preferences` |
| `saveProfile(name, email)` | `Future<void>` | Persists name and email; sets `isSaving` during the write |
| `incrementDriveCount()` | `Future<void>` | Increments `totalDrives` and persists (called by `NavigationViewModel` on arrival) |
| `addDistance(km)` | `Future<void>` | Adds to `totalDistanceKm` and persists (called by `NavigationViewModel` on arrival) |

#### `PlanDriveViewModel`
**Responsibility:** Manages the Plan a Drive screen state — origin/destination search, route fetching, route selection, and routing options.

| Property / Method | Type | Description |
|---|---|---|
| `fromLatLng` | `LatLng?` | Origin coordinates (defaults to device GPS on `init()`) |
| `fromLabel` | `String` | Display label for the origin (e.g. `'Your location'` or place name) |
| `fromResults` | `List<PlaceModel>` | Autocomplete results for the From field |
| `destination` | `PlaceModel?` | Selected destination place |
| `toResults` | `List<PlaceModel>` | Autocomplete results for the To field |
| `routes` | `List<RouteModel>` | Fetched alternative routes (up to 3) |
| `selectedRouteIndex` | `int` | Index of the currently highlighted route |
| `selectedRoute` | `RouteModel?` | Convenience getter for the active route |
| `isFetching` | `bool` | True while a route request is in flight |
| `error` | `String?` | Error message if the route fetch failed |
| `avoidTolls` | `bool` | Whether toll roads are excluded from the route |
| `avoidHighways` | `bool` | Whether highways are excluded from the route |
| `init()` | `Future<void>` | Fetches the current GPS location and seeds `fromLatLng` |
| `searchFrom(query)` | `Future<void>` | Searches Places API and updates `fromResults` |
| `selectFrom(place)` | `Future<void>` | Sets origin from a search result and re-fetches routes |
| `useCurrentLocationFrom(loc)` | `void` | Resets origin to the device's GPS coordinates |
| `searchTo(query)` | `Future<void>` | Searches Places API and updates `toResults` |
| `selectTo(place)` | `Future<void>` | Sets destination (fetches full place details) and re-fetches routes |
| `clearTo()` | `void` | Clears destination, routes, and error state |
| `selectRoute(index)` | `void` | Changes the highlighted route in the alternatives strip |
| `toggleAvoidTolls()` | `void` | Flips `avoidTolls` and re-fetches routes |
| `toggleAvoidHighways()` | `void` | Flips `avoidHighways` and re-fetches routes |
| `swapLocations()` | `Future<void>` | Exchanges origin and destination then re-fetches routes |

---

### 5.2 Models (Data Classes)

#### `RouteModel`
```dart
class RouteModel {
  final List<LatLng> waypoints;       // List of GPS coordinates along the route
  final List<TurnInstruction> turns;  // Turn-by-turn instructions
  final double totalDistance;         // Total route distance in metres
  final int estimatedDuration;        // Estimated time in seconds
}
```

#### `TurnDirection` (enum)

| Value | Icon rendered | Google Maps maneuver strings |
|---|---|---|
| `forward` | Arrow up | *(default / straight)* |
| `left` | Turn left | `turn-left`, `turn-sharp-left` |
| `right` | Turn right | `turn-right`, `turn-sharp-right` |
| `keepLeft` | Slight left | `turn-slight-left`, `keep-left`, `ramp-left`, `fork-left` |
| `keepRight` | Slight right | `turn-slight-right`, `keep-right`, `ramp-right`, `fork-right` |
| `uTurn` | U-turn | `uturn-left`, `uturn-right` |
| `roundabout` | Custom diagram | `roundabout-left`, `roundabout-right` |

#### `TurnInstruction`
```dart
class TurnInstruction {
  final TurnDirection direction;  // One of the 7 TurnDirection values
  final double distanceFromPrev;  // Distance from previous waypoint in metres
  final String streetName;        // Road name extracted from bold tag in html_instructions
  final LatLng position;          // GPS position of the end of this step
  final int? exitNumber;          // Roundabout exit number (null for non-roundabout steps)
}
```

#### `PlaceModel`
```dart
class PlaceModel {
  final String placeId;       // Google Places ID
  final String name;          // Display name of the place
  final String address;       // Full address string
  final LatLng coordinates;   // GPS coordinates
}
```

---

### 5.3 Services & Repositories

#### `LocationService`
- Wraps the `geolocator` Flutter package
- Provides a continuous GPS stream to the ViewModel
- Handles permission checks internally

#### `RouteRepository`
- Makes HTTP calls to **Google Maps Directions API**
- Parses JSON response into `RouteModel` objects
- Handles API errors and network failures

#### `PlacesRepository`
- Makes HTTP calls to **Google Maps Places API** (Text Search + Place Details endpoints)
- Returns search results as `List<PlaceModel>` with coordinates already included
- `getPlaceDetails(placeId)` fetches the full address and coordinates for a selected place

#### `SavedLocationsDatabase`
- SQLite database helper using the `sqflite` package
- Creates and manages the `saved_locations` table (columns: `id`, `place_id`, `name`, `address`, `lat`, `lng`, `saved_at`)
- `place_id` has a `UNIQUE` constraint to prevent duplicate bookmarks
- Provides raw CRUD methods: `insert`, `delete`, `getAll` (ordered by `saved_at DESC`), `exists`

#### `SavedLocationsRepository`
- Sits above `SavedLocationsDatabase` and converts raw rows to/from `PlaceModel` objects
- `save(place)` — inserts a `PlaceModel` with the current timestamp
- `remove(placeId)` — deletes by Google Places ID
- `getAll()` — returns all bookmarks as `List<PlaceModel>`
- `isSaved(placeId)` — checks existence without loading all rows

#### `ARService`
- Wraps `ar_flutter_plugin`
- Manages ARCore session lifecycle (initialize, pause, resume, dispose)
- Provides methods to place and update AR anchor objects on the camera feed

---

## 6. Data Flow Design

### 6.1 Navigation Start Flow

```
User enters destination on HomeScreen
            ↓
MapViewModel.searchPlaces(query)
            ↓
PlacesRepository → Google Places API
            ↓
Returns List<PlaceModel> → shown as autocomplete dropdown
            ↓
User selects a place
            ↓
NavigationViewModel.startNavigation(destination)
            ↓
RouteRepository.getRoute(currentLocation, destination)
            ↓
Google Maps Directions API → returns JSON route data
            ↓
Parsed into RouteModel
            ↓
NavigationViewModel updates state → notifies listeners
            ↓
App navigates to ARNavigationScreen
```

### 6.2 Real-Time AR Update Flow

```
GPS stream emits new LatLng every ~1 second
            ↓
MapViewModel.currentLocation updates
            ↓
ARViewModel.updateAROverlay(newLocation) called
            ↓
Calculates: distance to next turn, turn direction, street name
            ↓
ARViewModel notifies listeners
            ↓
ARNavigationScreen rebuilds AR overlay widgets
            ↓
ar_flutter_plugin renders updated arrows/text on camera feed
```

### 6.3 Off-Route Recalculation Flow

```
GPS position deviates from RouteModel waypoints
            ↓
NavigationViewModel detects deviation (> 30 metres threshold)
            ↓
NavigationViewModel.recalculateRoute() called
            ↓
RouteRepository fetches new route from current position
            ↓
RouteModel updated → ARViewModel resets overlay
            ↓
User sees updated AR directions
```

---

## 7. Folder Structure

The Flutter project follows a **feature-first** folder structure, which groups files by feature rather than by type. This is the recommended approach for scalable Flutter apps.

```
smart_ar_navigation/
│
├── lib/
│   ├── main.dart                    # App entry point
│   │
│   ├── core/                        # Shared utilities & constants
│   │   ├── constants/
│   │   │   ├── app_colors.dart      # Color palette
│   │   │   ├── app_strings.dart     # All text strings
│   │   │   └── api_keys.dart        # API key references (loaded from .env)
│   │   ├── enums/
│   │   │   ├── turn_direction.dart  # forward, left, right, keepLeft, keepRight, uTurn, roundabout
│   │   │   └── navigation_status.dart # idle, loading, navigating, rerouting, arrived
│   │   └── utils/
│   │       ├── location_utils.dart  # Distance / findNextTurn helpers
│   │       └── route_parser.dart    # Parses Google Maps JSON; extracts street name & roundabout exit number
│   │
│   ├── models/                      # Data classes (Model layer)
│   │   ├── route_model.dart
│   │   ├── turn_instruction.dart    # Includes exitNumber for roundabout steps
│   │   └── place_model.dart
│   │
│   ├── services/                    # External service wrappers (Model layer)
│   │   ├── location_service.dart        # GPS / geolocator wrapper
│   │   ├── ar_service.dart              # ARCore / ar_flutter_plugin wrapper
│   │   └── saved_locations_database.dart # SQLite database helper (sqflite)
│   │
│   ├── repositories/                # API & DB communication (Model layer)
│   │   ├── route_repository.dart         # Google Maps Directions API (supports avoidTolls / avoidHighways)
│   │   ├── places_repository.dart        # Google Maps Places API
│   │   └── saved_locations_repository.dart # CRUD over SavedLocationsDatabase
│   │
│   ├── viewmodels/                  # Business logic (ViewModel layer)
│   │   ├── navigation_viewmodel.dart     # Session state; updates ProfileViewModel on arrival
│   │   ├── ar_viewmodel.dart             # Tracks nextTurnDirection, exitNumber, streetName
│   │   ├── map_viewmodel.dart            # GPS stream, heading, accuracy, place search
│   │   ├── settings_viewmodel.dart       # Preferences: unit, speed, ETA, arrow size, opacity, avoidTolls
│   │   ├── profile_viewmodel.dart        # Name, email, drive stats (SharedPreferences)
│   │   ├── plan_drive_viewmodel.dart     # Plan Drive screen: search, routes, options
│   │   ├── saved_places_viewmodel.dart   # Home / Work / Favourite slots (SharedPreferences)
│   │   └── saved_locations_viewmodel.dart # Bookmarked places list (SQLite)
│   │
│   ├── views/                       # Screens & Widgets (View layer)
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── ar_navigation_screen.dart
│   │   │   ├── plan_drive_screen.dart
│   │   │   ├── profile_screen.dart
│   │   │   ├── settings_screen.dart
│   │   │   │
│   │   │   ├── home/widgets/              # Extracted widgets for HomeScreen
│   │   │   │   ├── home_map_layer.dart        # FlutterMap tile + polyline + marker stack
│   │   │   │   ├── home_controls.dart         # Menu button (left) + my-location / compass (right)
│   │   │   │   ├── home_bottom_sheet.dart     # DraggableScrollableSheet: search / route preview / idle
│   │   │   │   ├── quick_actions_section.dart # Home/Work/Favourite quick buttons + Saved Places tile
│   │   │   │   ├── search_result_item.dart    # Search result row with bookmark toggle
│   │   │   │   ├── route_preview_card.dart    # Route summary card shown after destination selected
│   │   │   │   ├── compass_button.dart        # Rotating compass FAB
│   │   │   │   ├── floating_icon_button.dart  # Reusable floating circular button
│   │   │   │   ├── location_indicator.dart    # Animated GPS location dot
│   │   │   │   ├── place_options_sheet.dart   # Long-press options: Navigate / Edit / Remove
│   │   │   │   ├── place_search_sheet.dart    # Bottom sheet for searching & assigning a saved place
│   │   │   │   ├── quick_place_button.dart    # Individual Home / Work / Favourite button chip
│   │   │   │   ├── saved_locations_sheet.dart # Full bookmarked-places list bottom sheet
│   │   │   │   ├── speed_indicator.dart       # Live speed display during navigation
│   │   │   │   └── waze_drawer.dart           # Side navigation drawer
│   │   │   │
│   │   │   ├── plan_drive/widgets/        # Extracted widgets for PlanDriveScreen
│   │   │   │   ├── plan_drive_input_card.dart    # From / To text fields with swap button
│   │   │   │   ├── plan_drive_options_row.dart   # Avoid Tolls / Avoid Highways option chips
│   │   │   │   ├── plan_drive_map.dart           # FlutterMap with route polylines + pins
│   │   │   │   ├── search_overlay.dart           # Full-height search results list
│   │   │   │   ├── route_alternatives_strip.dart # Horizontal scrollable route cards strip
│   │   │   │   ├── route_summary_card.dart       # Bottom card: fetching / error / route details + Start button
│   │   │   │   ├── option_chip.dart              # Animated toggle chip (Avoid Tolls / Highways)
│   │   │   │   ├── fetching_indicator.dart       # "Finding routes…" progress row
│   │   │   │   └── stat_chip.dart                # Icon + label mini chip
│   │   │   │
│   │   │   └── profile/widgets/           # Extracted widgets for ProfileScreen
│   │   │       ├── profile_card.dart          # White rounded card container
│   │   │       ├── profile_section_label.dart # Uppercase muted section heading
│   │   │       ├── profile_field.dart         # Labeled text input with styled borders
│   │   │       ├── profile_header_card.dart   # Avatar + Name/Email fields + Save button
│   │   │       ├── stats_section.dart         # 3-column stats: drives / km / top destination
│   │   │       └── saved_places_section.dart  # Home / Work / Favourite place rows
│   │   │
│   │   └── widgets/                 # Reusable UI components (shared across screens)
│   │       ├── ar_overlay_widget.dart      # Turn card HUD (switches between TurnArrowWidget / RoundaboutWidget)
│   │       ├── roundabout_widget.dart      # CustomPainter: ring + entry/exit arrows + exit number
│   │       ├── search_bar_widget.dart      # Destination search input
│   │       ├── navigation_bottom_bar.dart  # ETA / distance bottom panel
│   │       └── turn_arrow_widget.dart      # Material icon arrows for all 7 TurnDirection values
│   │
│   └── app.dart                     # MaterialApp setup, routing & MultiProvider tree
│
├── assets/
│   ├── map_style.json               # Custom Waze-inspired map style
│   ├── images/
│   │   └── logo.png
│   └── icons/
│       └── logo.svg
│
├── test/                            # Unit & widget tests
│   ├── viewmodels/
│   └── repositories/
│
├── pubspec.yaml                     # Dependencies
├── .env                             # API keys (NOT committed to Git)
├── .gitignore
└── README.md
```

---

## 8. External Services & Integrations

### 8.1 Google Maps Directions API

- **Purpose:** Fetches turn-by-turn route from origin to destination
- **Request Type:** HTTP GET
- **Endpoint:** `https://maps.googleapis.com/maps/api/directions/json`
- **Key Parameters:** `origin`, `destination`, `mode=walking`, `key`
- **Response:** JSON with legs, steps, distance, duration

**Sample Request:**
```
GET https://maps.googleapis.com/maps/api/directions/json
  ?origin=-3.1319,101.6841
  &destination=Sunway+University
  &mode=walking
  &key=YOUR_API_KEY
```

### 8.2 Google Maps Places API

- **Purpose:** Autocomplete destination search input
- **Request Type:** HTTP GET
- **Endpoint:** `https://maps.googleapis.com/maps/api/place/autocomplete/json`
- **Key Parameters:** `input`, `key`

### 8.3 flutter_map + CartoDB Positron Tiles

- **Purpose:** Renders the Home Screen map without the Google Maps SDK — no Google branding
- **Tile URL:** `https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png`
- **Style:** CartoDB Voyager — Waze-like coloured rendering: blue water, green parks/forests, amber highways, white local roads
- **Attribution:** © OpenStreetMap contributors, © CARTO
- **Key Packages:** `flutter_map: ^6.1.0`, `latlong2: ^0.9.0`

### 8.4 ARCore (via `ar_flutter_plugin`)

- **Purpose:** Renders 3D AR overlays on the live camera feed
- **Key Functions Used:**
  - Initialize AR session
  - Detect ground plane (for anchor placement)
  - Place and update AR anchor nodes (arrows, text)
  - Handle AR session lifecycle (pause on app background)

### 8.5 Geolocator Package

- **Purpose:** Continuous real-time GPS location stream
- **Key Functions Used:**
  - `Geolocator.getPositionStream()` — returns live GPS updates
  - `Geolocator.checkPermission()` — verifies location access
  - `Geolocator.distanceBetween()` — calculates distance between two coordinates

### 8.6 SQLite (via `sqflite`)

- **Purpose:** Persistent local storage for the user's unbounded list of bookmarked places
- **Database file:** `saved_locations.db` (stored in the app's default databases path)
- **Table:** `saved_locations` — columns: `id` (PK), `place_id` (UNIQUE), `name`, `address`, `lat`, `lng`, `saved_at`
- **Key Design Decisions:**
  - `place_id` is unique to prevent duplicate bookmarks
  - Rows are ordered by `saved_at DESC` so newest saves appear first
  - `ConflictAlgorithm.ignore` on insert prevents crashes on accidental re-saves
  - The `SavedLocationsViewModel` maintains an in-memory `Set<String>` of saved IDs for O(1) `isSaved()` checks without hitting the database on every search result render

---

## 9. UI Design Guidelines

### 9.1 Design Principles

- **Waze-style Home** — The Home Screen uses a full-screen interactive 2D map as its base. All controls float on top without a traditional app bar.
- **Custom Map Style** — The Home Screen map uses CartoDB Voyager tiles via `flutter_map`, delivering a Waze-like aesthetic (blue water, green parks, amber highways, white local roads) without any Google Maps SDK or branding. Route data is still fetched from the Google Maps Directions API.
- **Animated Map Transitions** — All programmatic map movements (initial GPS centre, "my location" button) use `AnimatedMapController` with a 650 ms `easeInOut` curve, avoiding jarring instant jumps.
- **Minimal UI** — The AR camera view is the hero on the navigation screen. UI elements should not obstruct it.
- **High Contrast** — All text and overlays must be readable in bright sunlight.
- **Material Design 3** — Follow Flutter's Material Design guidelines.

### 9.2 Screen Layouts

#### Splash Screen
```
┌─────────────────────┐
│                     │
│                     │
│      [App Logo]     │
│                     │
│  Smart AR Navigate  │
│                     │
│   [Loading bar...]  │
│                     │
└─────────────────────┘
```

#### Home Screen
```
┌─────────────────────┐
│ ≡              📍 ↑ │  ← Hamburger (left) + my-location / compass (right)
│                     │
│   [Full-Screen      │
│    CartoDB Map]     │  ← Interactive 2D map, user location centred
│                     │
│  ┌───────────────┐  │
│  │ 🔍 Where to? │  │  ← DraggableScrollableSheet (bottom)
│  │               │  │    idle: quick actions + saved places
│  │ [Home][Work]  │  │    searching: autocomplete results
│  │ [Favourite]   │  │    destination set: route preview card
│  └───────────────┘  │
└─────────────────────┘
```

#### Plan Drive Screen
```
┌─────────────────────┐
│ ← Plan a Drive      │  ← AppBar with back button
│ ┌─────────────────┐ │
│ │ From: Your loc  │ │  ← From text field
│ │ ⇅               │ │  ← Swap button
│ │ To:  search...  │ │  ← To text field
│ └─────────────────┘ │
│ [Avoid Tolls][Avoid Highways] │  ← Toggle option chips
│                     │
│   [Map with route   │  ← FlutterMap: selected route highlighted,
│    preview]         │    alternatives dimmed
│                     │
│ ─────────────────── │
│ [Alt 1][Alt 2][Alt3]│  ← Route alternatives horizontal strip
│ ─────────────────── │
│ 25 min · 18.2 km    │  ← Route summary card
│ [Start AR Navigation]│
└─────────────────────┘
```

#### Profile Screen
```
┌─────────────────────┐
│ ← My Profile        │  ← AppBar
│                     │
│      [  M  ]        │  ← CircleAvatar (first letter of name)
│  NAME               │
│  [________________] │  ← Name text field
│  EMAIL              │
│  [________________] │  ← Email text field
│  [  Save Profile  ] │
│                     │
│  MY STATS           │
│ ┌──────┬────┬─────┐ │
│ │Drives│ km │ Top │ │  ← 3-column stat row
│ └──────┴────┴─────┘ │
│                     │
│  SAVED PLACES       │
│  🏠 Home       edit │
│  💼 Work       edit │
│  ⭐ Favourite  edit │
└─────────────────────┘
```

#### AR Navigation Screen
```
┌─────────────────────┐
│ ← Sunway University │  ← Destination name (top bar, semi-transparent)
├─────────────────────┤
│                     │
│  [LIVE CAMERA FEED] │
│                     │
│      ↑ 50m          │  ← AR overlay: arrow + distance
│   Turn Left         │  ← AR overlay: instruction text
│                     │
│                     │
├─────────────────────┤
│ ETA: 5 min  1.2 km  │  ← Bottom info bar
│         [■ Stop]    │  ← Stop navigation button
└─────────────────────┘
```

### 9.3 Color Palette

| Element | Color | Hex |
|---|---|---|
| Primary | Deep Blue | `#1A73E8` |
| AR Arrow | Bright Green | `#00E676` |
| AR Text Background | Semi-transparent Black | `#99000000` |
| Warning / Rerouting | Amber | `#FFC107` |
| Background | White | `#FFFFFF` |
| Text Primary | Dark Grey | `#212121` |

---

## 10. Future Enhancements

These features are **out of scope for the current FYP phase** but the design has been structured to accommodate them easily.

| Feature | Design Note |
|---|---|
| **Auto Rerouting** | `NavigationViewModel` already holds the `RouteModel`. Add a deviation check in the GPS update loop (> 30 m from polyline) and call `RouteRepository.getRoute()` again. `ARViewModel.resetOverlay()` and `initializeOverlay()` already handle the reset/re-seed cycle. |
| **Voice Instructions** | Add a `VoiceService` in the services layer. `ARViewModel` already exposes `nextTurnDirection`, `distanceToNextTurn`, and `currentStreetName` — pass these to a `flutter_tts` call at appropriate distance thresholds. |
| **2D Map Toggle** | Add `map_screen.dart` as a new View. `NavigationViewModel` already holds the `RouteModel` — pass it to a `GoogleMap` widget. A toggle button on `ARNavigationScreen` can push/pop between screens. |
| **Offline Navigation** | Replace `RouteRepository` with a cached route strategy. No changes needed in ViewModels or Views. |
| **Speed Warning** | Add a `speedLimit` property to `MapViewModel` using location speed data from `geolocator`. |

---

*End of SDD Document — Version 2.0*

*Prepared by: Liew Sau Yang | Sunway University | Bachelor of Software Engineering (Hons)*
