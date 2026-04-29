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
| **Version** | 1.0 |
| **Last Updated** | October 2025 |

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
| **Home Screen** | `home_screen.dart` | Full-screen 2D map (Waze-style), floating bottom search bar, top-left settings button |
| **AR Navigation Screen** | `ar_navigation_screen.dart` | Live camera + AR overlays + navigation info |
| **Settings Screen** | `settings_screen.dart` | User preferences: display options, AR settings, and About info |

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
│  [⚙ Settings]                          │  ← top-left floating icon button
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

─ ─ ─ ─ ─ ─ ─ ─ Settings Branch ─ ─ ─ ─ ─ ─ ─ ─
         Home Screen [⚙ Settings] tapped
                 │
                 ▼
┌─────────────────────────────────────────┐
│            Settings Screen              │
│                                         │
│  • Navigation Mode toggle (locked: AR)  │
│  • Distance unit (km / miles)           │
│  • Show / hide speed display            │
│  • Show / hide ETA display              │
│  • AR arrow size (Small/Medium/Large)   │
│  • AR overlay opacity (50%–100%)        │
│  • About (app version + developer info) │
└────────────────┬────────────────────────┘
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
**Responsibility:** Manages the overall navigation session state.

| Property / Method | Type | Description |
|---|---|---|
| `currentDestination` | `String` | The user's entered destination |
| `currentRoute` | `RouteModel` | Active route data from Google Maps API |
| `navigationStatus` | `NavigationStatus` | Enum: idle / navigating / arrived |
| `startNavigation(destination)` | `Future<void>` | Fetches route and starts session |
| `stopNavigation()` | `void` | Ends navigation session, clears state |
| `recalculateRoute()` | `Future<void>` | Called when user goes off-route |

#### `ARViewModel`
**Responsibility:** Manages AR overlay state and rendering instructions.

| Property / Method | Type | Description |
|---|---|---|
| `nextTurnDirection` | `TurnDirection` | Enum: forward / left / right / u-turn |
| `distanceToNextTurn` | `double` | Distance in metres to the next turn |
| `currentStreetName` | `String` | Name of the current street |
| `updateAROverlay(location)` | `void` | Recalculates overlay based on GPS position |
| `isARInitialized` | `bool` | Whether ARCore session is ready |

#### `MapViewModel`
**Responsibility:** Handles GPS location tracking and map data.

| Property / Method | Type | Description |
|---|---|---|
| `currentLocation` | `LatLng` | User's real-time GPS coordinates |
| `startLocationTracking()` | `void` | Begins GPS stream |
| `stopLocationTracking()` | `void` | Ends GPS stream |
| `searchPlaces(query)` | `Future<List<PlaceModel>>` | Returns autocomplete results |

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
| `getNavigationMode()` | `Future<String>` | Reads navigation mode from persistent storage |
| `setNavigationMode(mode)` | `Future<void>` | Saves navigation mode preference |
| `getDistanceUnit()` | `Future<String>` | Reads distance unit preference |
| `setDistanceUnit(unit)` | `Future<void>` | Saves distance unit preference |
| `getShowSpeed()` | `Future<bool>` | Reads show-speed toggle state |
| `setShowSpeed(value)` | `Future<void>` | Saves show-speed toggle state |
| `getShowETA()` | `Future<bool>` | Reads show-ETA toggle state |
| `setShowETA(value)` | `Future<void>` | Saves show-ETA toggle state |
| `getArrowSize()` | `Future<String>` | Reads AR arrow size preference |
| `setArrowSize(size)` | `Future<void>` | Saves AR arrow size preference |
| `getOverlayOpacity()` | `Future<double>` | Reads AR overlay opacity value |
| `setOverlayOpacity(opacity)` | `Future<void>` | Saves AR overlay opacity value |

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

#### `TurnInstruction`
```dart
class TurnInstruction {
  final TurnDirection direction;  // forward, left, right, u_turn
  final double distanceFromPrev;  // Distance from previous waypoint in metres
  final String streetName;        // Name of the street for this instruction
  final LatLng position;          // GPS position of this turn
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
- Makes HTTP calls to **Google Maps Places API**
- Returns autocomplete suggestions as `List<PlaceModel>`

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
│   │   │   ├── turn_direction.dart  # forward, left, right, u_turn
│   │   │   └── navigation_status.dart # idle, navigating, arrived
│   │   └── utils/
│   │       ├── location_utils.dart  # Distance calculation helpers
│   │       └── route_parser.dart    # Parses Google Maps API JSON
│   │
│   ├── models/                      # Data classes (Model layer)
│   │   ├── route_model.dart
│   │   ├── turn_instruction.dart
│   │   └── place_model.dart
│   │
│   ├── services/                    # External service wrappers (Model layer)
│   │   ├── location_service.dart    # GPS / geolocator wrapper
│   │   └── ar_service.dart          # ARCore / ar_flutter_plugin wrapper
│   │
│   ├── repositories/                # API communication (Model layer)
│   │   ├── route_repository.dart    # Google Maps Directions API
│   │   └── places_repository.dart   # Google Maps Places API
│   │
│   ├── viewmodels/                  # Business logic (ViewModel layer)
│   │   ├── navigation_viewmodel.dart
│   │   ├── ar_viewmodel.dart
│   │   ├── map_viewmodel.dart
│   │   └── settings_viewmodel.dart
│   │
│   ├── views/                       # Screens & Widgets (View layer)
│   │   ├── screens/
│   │   │   ├── splash_screen.dart
│   │   │   ├── home_screen.dart
│   │   │   ├── ar_navigation_screen.dart
│   │   │   └── settings_screen.dart
│   │   └── widgets/                 # Reusable UI components
│   │       ├── ar_overlay_widget.dart     # AR arrows and distance text
│   │       ├── search_bar_widget.dart     # Destination search input
│   │       ├── navigation_bottom_bar.dart # ETA / distance bottom panel
│   │       └── turn_arrow_widget.dart     # Directional arrow display
│   │
│   └── app.dart                     # MaterialApp setup & routing
│
├── assets/
│   ├── images/
│   │   └── app_logo.png
│   └── icons/
│       ├── arrow_forward.png
│       ├── arrow_left.png
│       ├── arrow_right.png
│       └── arrow_uturn.png
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

### 8.3 ARCore (via `ar_flutter_plugin`)

- **Purpose:** Renders 3D AR overlays on the live camera feed
- **Key Functions Used:**
  - Initialize AR session
  - Detect ground plane (for anchor placement)
  - Place and update AR anchor nodes (arrows, text)
  - Handle AR session lifecycle (pause on app background)

### 8.4 Geolocator Package

- **Purpose:** Continuous real-time GPS location stream
- **Key Functions Used:**
  - `Geolocator.getPositionStream()` — returns live GPS updates
  - `Geolocator.checkPermission()` — verifies location access
  - `Geolocator.distanceBetween()` — calculates distance between two coordinates

---

## 9. UI Design Guidelines

### 9.1 Design Principles

- **Waze-style Home** — The Home Screen uses a full-screen interactive 2D map as its base. All controls float on top without a traditional app bar.
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
│ ⚙                   │  ← Settings icon (top-left, floating)
│                     │
│                     │
│   [Full-Screen      │
│    Google Map]      │  ← Interactive 2D map, user location centred
│                     │
│                     │
│  ┌───────────────┐  │
│  │ 🔍 Where to? │  │  ← Floating search bar (bottom)
│  └───────────────┘  │
│  [Start AR Nav ▶]   │  ← Appears after destination selected
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
| **2D Map Toggle** | Add `map_screen.dart` as a new View. `NavigationViewModel` already holds the `RouteModel` — just pass it to a `GoogleMap` widget. A toggle button on `ARNavigationScreen` can push/pop between screens. |
| **Voice Instructions** | Add a `VoiceService` in the services layer. `ARViewModel` already has `nextTurnDirection` and `distanceToNextTurn` — just pass these to a text-to-speech call. |
| **Offline Navigation** | Replace `RouteRepository` with a cached route strategy. No changes needed in ViewModels or Views. |
| **Speed Warning** | Add a `speedLimit` property to `MapViewModel` using location speed data from `geolocator`. |

---

*End of SDD Document — Version 1.0*

*Prepared by: Liew Sau Yang | Sunway University | Bachelor of Software Engineering (Hons)*
