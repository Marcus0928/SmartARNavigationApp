# Software Requirements Specification (SRS)

## Smart AR Navigation App for Enhanced Driving Assistance

---

| Field | Details |
|---|---|
| **Project Title** | Smart AR Navigation App for Enhanced Driving Assistance |
| **Author** | Liew Sau Yang (22062475) |
| **Supervisor** | Dr Javid Iqbal Thirupattur |
| **Institution** | Sunway University — School of Computing and Artificial Intelligence |
| **Programme** | Bachelor of Software Engineering (Hons) |
| **Semester** | September 2025 |
| **Version** | 2.4 |
| **Last Updated** | July 2026 |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [System Features & Functional Requirements](#3-system-features--functional-requirements)
   - [3.7 Settings Screen](#37-settings-screen)
   - [3.8 Quick-Access Saved Places](#38-quick-access-saved-places-home--work--favourite)
   - [3.9 Bookmarked Locations](#39-bookmarked-locations-saved-places-list)
   - [3.10 Profile Screen](#310-profile-screen)
   - [3.11 Plan a Drive Screen](#311-plan-a-drive-screen)
   - [3.12 Home Screen Route Selection](#312-home-screen-route-selection)
   - [3.13 Recent Search History](#313-recent-search-history)
4. [Non-Functional Requirements](#4-non-functional-requirements)
5. [External Interface Requirements](#5-external-interface-requirements)
6. [Technology Stack](#6-technology-stack)
7. [Constraints & Limitations](#7-constraints--limitations)
8. [Assumptions & Dependencies](#8-assumptions--dependencies)

---

## 1. Introduction

### 1.1 Purpose

This Software Requirements Specification (SRS) defines the functional and non-functional requirements for the **Smart AR Navigation App**, a mobile application designed to provide augmented reality (AR) navigation overlays on an Android device's live camera feed. The document serves as the primary reference for design, development, and testing of the system.

### 1.2 Project Overview

Conventional navigation apps like Google Maps and Waze require users to repeatedly glance between the road and a 2D map interface. This creates cognitive load and increases the risk of distraction. This project addresses the problem by overlaying real-time directional cues — arrows, route lines, and distance markers — directly on the live camera view of the user's phone, using Augmented Reality.

### 1.3 Intended Audience

This document is intended for:

- The project developer (Liew Sau Yang)
- Academic supervisor (Dr Javid Iqbal Thirupattur)
- Examiners and evaluators at Sunway University
- Future developers who may extend or maintain this system

### 1.4 Scope

The application is an Android-based mobile app built using **Flutter (Dart)** in **Visual Studio Code**. It integrates:

- **ARCore** (via `ar_flutter_plugin`) — for rendering AR overlays on the live camera feed
- **Google Maps Flutter SDK** — for GPS tracking and route/navigation data

The app targets pedestrian and low-speed navigation use cases, tested in controlled outdoor environments such as a university campus.

### 1.5 Definitions & Acronyms

| Term | Definition |
|---|---|
| AR | Augmented Reality — overlaying digital content onto a real-world camera view |
| ARCore | Google's AR platform for Android devices |
| GPS | Global Positioning System — used for real-time location tracking |
| SDK | Software Development Kit |
| HCI | Human–Computer Interaction |
| SRS | Software Requirements Specification |
| UI | User Interface |
| UX | User Experience |
| Flutter | Google's cross-platform UI framework using the Dart language |
| Dart | Programming language used by Flutter |
| VS Code | Visual Studio Code — the IDE used for development |

---

## 2. Overall Description

### 2.1 Product Perspective

The Smart AR Navigation App is a standalone Android mobile application. It does not require any external hardware beyond an Android smartphone with a rear-facing camera and GPS capability. It communicates with external services (Google Maps API) over the internet to retrieve route and navigation data.

```
┌──────────────────────────────────────┐
│          Android Device              │
│                                      │
│  ┌────────────┐    ┌──────────────┐  │
│  │  Camera    │───▶│  AR Overlay  │  │
│  │  (Live     │    │  (ARCore /   │  │
│  │   Feed)    │    │  ar_flutter) │  │
│  └────────────┘    └──────┬───────┘  │
│                           │          │
│  ┌────────────┐    ┌──────▼───────┐  │
│  │  GPS       │───▶│  Navigation  │  │
│  │  Module    │    │  Logic       │  │
│  └────────────┘    └──────┬───────┘  │
│                           │          │
└───────────────────────────┼──────────┘
                            │ API Call
                ┌───────────▼──────────┐
                │  Google Maps API     │
                │  (Route Data / GPS)  │
                └──────────────────────┘
```

### 2.2 Product Functions (High-Level)

- Display a live camera feed as the main UI background
- Retrieve the user's real-time GPS location
- Fetch route and turn-by-turn navigation data from Google Maps API
- Render AR overlays (directional arrows, route lines, distance text) on the camera feed
- Update overlays dynamically as the user moves

### 2.3 User Classes and Characteristics

| User Type | Description |
|---|---|
| **Primary User** | A pedestrian or low-speed driver using the app for navigation |
| **Developer** | The student developer building and testing the app |
| **Evaluator** | Supervisor or examiners assessing the system during demo |

Primary users are assumed to be comfortable with basic smartphone usage. No technical expertise is required to operate the app.

### 2.4 Operating Environment

| Component | Requirement |
|---|---|
| **Platform** | Android (API Level 26 / Android 8.0 or higher) |
| **ARCore Support** | Device must support Google ARCore |
| **Internet** | Required for Google Maps API calls |
| **GPS** | Required for location tracking |
| **Camera** | Rear-facing camera required |
| **Development OS** | Windows / macOS / Linux (VS Code + Flutter SDK) |

---

## 3. System Features & Functional Requirements

### 3.1 Live Camera View

**Description:** The app shall display the device's live rear camera feed as the full-screen background of the application.

| ID | Requirement |
|---|---|
| FR-01 | The system shall open and display the rear camera feed on app launch. |
| FR-02 | The camera feed shall be rendered in real-time with no significant lag (< 200ms delay). |
| FR-03 | The system shall request camera permission from the user on first launch. |

---

### 3.2 GPS Location Tracking

**Description:** The app shall continuously track the user's real-time location using the device's GPS.

| ID | Requirement |
|---|---|
| FR-04 | The system shall request location permission from the user on first launch. |
| FR-05 | The system shall retrieve the user's GPS coordinates in real-time. |
| FR-06 | The system shall update the user's location at a minimum frequency of once per second. |
| FR-07 | The system shall display a notification or error message if GPS signal is unavailable. |

---

### 3.3 Route & Navigation Data

**Description:** The app shall fetch navigation route data from Google Maps API based on the user's current location and destination.

| ID | Requirement |
|---|---|
| FR-08 | The system shall allow the user to input a destination address or select a point on a map. |
| FR-09 | The system shall call the Google Maps Directions API to retrieve turn-by-turn route data. |
| FR-10 | The system shall parse route data including waypoints, turn types, distances, and — for roundabout steps — the exit number extracted from the step's HTML instruction text. |
| FR-11 | The system shall recalculate the route automatically if the user deviates from the planned path. Off-route is defined as the perpendicular distance from the current GPS position to the nearest route segment exceeding **50 metres**. A 30-second cooldown prevents repeated reroutes from GPS drift. |

---

### 3.4 AR Overlay Rendering

**Description:** The app shall render augmented reality navigation cues on top of the live camera feed.

| ID | Requirement |
|---|---|
| FR-12 | The system shall overlay directional arrows on the camera view using seven distinct maneuver types: straight (forward), turn left, turn right, keep left, keep right, U-turn, and roundabout. |
| FR-12a | For roundabout maneuvers, the system shall display a custom-painted diagram showing the roundabout ring, an entry arrow, an exit arrow at the correct clock position, and the exit number (e.g. "2") in the centre of the ring. The exit number shall be read from the structured route data if available, or extracted via regex from the step's HTML instruction text as a fallback. |
| FR-12b | The system shall display only the name of the upcoming road on the AR overlay (extracted from the bold text in the Google Maps step instruction), not the full instruction sentence. |
| FR-13 | The system shall display the distance to the next turn as text on the AR overlay. The distance displayed shall always reflect the upcoming non-forward turn (left, right, keep, U-turn, or roundabout), not merely the end of the current straight segment. |
| FR-14 | The system shall update AR overlays in real-time as the user's GPS position changes. |
| FR-15 | The system shall align AR overlays with the real-world environment using ARCore plane detection. |
| FR-16 | The system shall remove or update AR cues after a turn is completed (within 25 m of the turn waypoint, to accommodate Malaysian urban GPS accuracy of 10–30 m). |
| FR-16a | When the user is within 1 000 m of the next non-forward turn, the system shall pre-emptively switch the AR arrow and instruction to show that upcoming turn's direction — even if the current step is still straight — so the driver has sufficient warning time to prepare. This gate applies to **all** non-forward turn types (left, right, keepLeft, keepRight, U-turn, and roundabout). A hysteresis mechanism (engage at 1 000 m, disengage at 1 100 m) prevents oscillation at the boundary. |
| FR-16b | When fetching or recalculating a route, the system shall include the device's current compass heading (degrees, 0–360) as a parameter to the Google Maps Directions API request. This biases the returned route to start in the driver's actual direction of travel, reducing phantom U-turn steps at route start. |

---

### 3.5 User Interface

**Description:** The app shall provide a simple, minimal UI inspired by Waze. The Home Screen displays a full-screen interactive 2D map with a floating search bar at the bottom and a settings button at the top left. The AR screen does not obstruct the camera view.

| ID | Requirement |
|---|---|
| FR-17 | The system shall display a full-screen interactive 2D map (OpenStreetMap tiles via CartoDB Positron) as the Home Screen background. |
| FR-17a | The system shall provide a floating search bar anchored to the bottom of the Home Screen for destination entry. |
| FR-17b | The system shall display a hamburger menu icon (≡) at the top-left corner of the Home Screen that opens a side drawer panel when tapped. |
| FR-18 | The system shall display a "Start AR Navigation" button once the user has selected a destination. |
| FR-19 | The system shall display a stop/end navigation button during an active session. |
| FR-20 | The system shall show a status indicator for GPS signal strength. |
| FR-21 | The UI shall follow Material Design guidelines for consistency and accessibility. |
| FR-33 | The Home Screen map shall use CartoDB Voyager tiles to render a Waze-inspired style (blue water, green parks/forests, amber highways, white local roads) without Google Maps branding. |
| FR-34 | The hamburger menu drawer shall contain the following items, in order: a Profile section (avatar + name) separated by a divider, then Plan a drive, Inbox, Settings, Help & Feedback, and Shutdown. |
| FR-35 | The map shall animate to the user's location with a smooth eased transition (approximately 650 ms, ease-in-out curve) when the location button is tapped or on the first GPS fix after app launch. |
| FR-81 | During active navigation, when the system is recalculating the route (i.e. `NavigationStatus.rerouting`), the AR Navigation Screen shall display a prominent "Recalculating route…" banner. The banner shall disappear automatically once the new route is loaded. |
| FR-82 | During active navigation, the system shall check for a faster route in the background every 2 minutes using the Google Maps Directions API. If a new route is found that saves more than 120 seconds compared to the current route's remaining duration, the system shall display a "Faster route available — Save X min" banner on the AR Navigation Screen. The user may tap **Switch** to accept the new route or **Dismiss** to keep the current one. The banner shall auto-dismiss after 15 seconds if the user does not interact. |

---

### 3.6 Session Management

**Description:** The app shall manage the start and end of a navigation session.

| ID | Requirement |
|---|---|
| FR-22 | The system shall begin AR navigation upon user confirmation of destination. |
| FR-23 | The system shall end the navigation session and clear AR overlays when the user arrives at the destination. |
| FR-24 | The system shall allow the user to manually stop navigation at any time. |

---

### 3.7 Settings Screen

**Description:** The app shall provide a Settings screen accessible from the Home Screen, allowing the user to configure display preferences and view app information.

| ID | Requirement |
|---|---|
| FR-25 | The system shall provide a Settings screen accessible via the Settings option in the hamburger menu drawer on the Home Screen. |
| FR-26 | The Settings screen shall include a Navigation Mode toggle (AR / 2D Map); the toggle shall be locked to AR mode in the current version. |
| FR-27 | The Settings screen shall allow the user to set a distance unit preference (kilometres or miles). |
| FR-28 | The Settings screen shall include a toggle to show or hide the speed display during navigation. |
| FR-29 | The Settings screen shall include a toggle to show or hide the estimated time of arrival (ETA) display during navigation. |
| FR-30 | The Settings screen shall allow the user to select a preferred AR arrow size (Small / Medium / Large). |
| FR-31 | The Settings screen shall include an AR overlay opacity slider adjustable between 50% and 100%. |
| FR-32 | The Settings screen shall display an About section showing the current app version and developer information. |
| FR-49 | The Settings screen shall include a toggle to avoid toll roads when routing; the preference shall be persisted via `shared_preferences`. |
| FR-83 | The Settings screen shall include an "Auto Brightness" toggle. When enabled (default), the system shall read the device's ambient light sensor and automatically adjust the AR arrow's opacity and colour to one of three levels — bright, normal, or dark — based on the measured lux value, applying a 2-second debounce before switching levels to prevent flicker. When disabled, the AR arrow shall use the manual "AR Overlay Opacity" slider value (FR-31) instead. |
| FR-83a | If the device has no ambient light sensor or the sensor stream is unavailable, the system shall fail gracefully and continue to display the AR arrow at its default appearance, without crashing or blocking navigation. |

---

### 3.8 Quick-Access Saved Places (Home / Work / Favourite)

**Description:** The app shall provide three fixed quick-access buttons on the Home Screen bottom sheet for storing a single destination per slot (Home, Work, Favourite), persisted via `shared_preferences`.

| ID | Requirement |
|---|---|
| FR-36 | The Home Screen bottom sheet shall display three quick-access buttons labelled **Home**, **Work**, and **Favourite**. |
| FR-37 | Tapping a quick-access button that has no saved place shall open a place-search sheet, allowing the user to search for and assign a location to that slot. |
| FR-38 | Tapping a quick-access button that has a saved place shall immediately set that place as the selected navigation destination on the map. |
| FR-39 | Long-pressing a populated quick-access button shall open an options sheet with the choices: Navigate, Edit location, and Remove. |
| FR-40 | All three saved places shall be persisted across app restarts using `shared_preferences`. |

---

### 3.9 Bookmarked Locations (Saved Places List)

**Description:** The app shall allow the user to bookmark an unlimited number of places from search results, stored in a local SQLite database.

| ID | Requirement |
|---|---|
| FR-41 | Each search result displayed in the Home Screen bottom sheet shall include a bookmark icon toggle. |
| FR-42 | Tapping the bookmark icon on a search result shall save that place to the local SQLite database; tapping it again shall remove it. |
| FR-43 | The bookmark icon shall visually indicate the saved state (filled icon = saved, outlined icon = not saved). |
| FR-44 | The Home Screen bottom sheet shall display a full-width **Saved Places** button below the quick-access buttons, showing the number of bookmarked places. |
| FR-45 | Tapping the **Saved Places** button shall open a bottom sheet listing all bookmarked places, ordered newest-first. |
| FR-46 | Each entry in the saved places list shall provide a **Navigate** action (sets the place as the map destination) and a **Remove** action (deletes from the database). |
| FR-47 | Saved places shall be stored in a local SQLite database using the `sqflite` package and shall persist across app restarts. |
| FR-48 | The system shall prevent duplicate entries: bookmarking a place that is already saved shall have no effect. |

---

### 3.10 Profile Screen

**Description:** The app shall provide a Profile screen accessible from the hamburger menu drawer, allowing the user to view and edit their name and email, view navigation statistics, and manage their three quick-access saved places (Home, Work, Favourite).

| ID | Requirement |
|---|---|
| FR-50 | The system shall provide a Profile screen accessible via the hamburger menu drawer. |
| FR-51 | The Profile screen shall display an avatar showing the first letter of the user's name. |
| FR-52 | The Profile screen shall allow the user to edit their display name and email address, and save the changes. |
| FR-53 | Profile name and email shall be persisted via `shared_preferences` and restored on next launch. |
| FR-54 | The Profile screen shall display a **My Stats** section showing: total number of completed drives, and total distance driven in kilometres. |
| FR-55 | Drive count and total distance shall be updated automatically when a navigation session ends by arrival, and persisted via `shared_preferences`. |
| FR-56 | The Profile screen shall display a **Saved Places** section showing the Home, Work, and Favourite quick-access slots. |
| FR-57 | Tapping a slot in the Saved Places section shall open the same place-search sheet used on the Home Screen, allowing the user to assign or change the saved location. |

---

### 3.11 Plan a Drive Screen

**Description:** The app shall provide a Plan a Drive screen accessible from the hamburger menu drawer. It allows the user to plan a route between a custom origin and destination, preview alternative routes on a map, and start AR navigation from the selected route.

| ID | Requirement |
|---|---|
| FR-58 | The system shall provide a Plan a Drive screen accessible via the hamburger menu drawer. |
| FR-59 | The Plan a Drive screen shall provide a **From** text field, defaulting to the user's current GPS location. |
| FR-60 | The Plan a Drive screen shall provide a **To** text field for the destination. |
| FR-61 | Both the From and To fields shall show autocomplete search results using the Google Maps Places API as the user types. |
| FR-62 | The Plan a Drive screen shall provide a **Swap** button to interchange the origin and destination. |
| FR-63 | The Plan a Drive screen shall provide toggleable **Avoid Tolls** and **Avoid Highways** option chips; selecting either shall trigger a route re-fetch with the corresponding constraint. |
| FR-64 | When a valid origin and destination are set, the system shall fetch up to three alternative routes from the Google Maps Directions API and display them in a horizontal scrollable strip; the fastest route shall be marked with a "Fastest" badge. |
| FR-65 | The selected route shall be highlighted on the embedded map; alternative routes shall be shown in a dimmed style. |
| FR-66 | The map view shall automatically fit to the bounding box of the selected route when routes are loaded. |
| FR-67 | Tapping **Start AR Navigation** shall hand the selected route to `NavigationViewModel` and launch the AR Navigation Screen. |
| FR-68 | Each route card in the Plan a Drive alternatives strip shall display an orange toll indicator (toll icon + "Toll" label) when the Google Directions API response indicates the route includes toll roads — detected via the route-level `warnings` array or step-level HTML instruction text containing the word "toll". |

---

### 3.12 Home Screen Route Selection

**Description:** After the user selects a destination from the Home Screen search bar or quick-access buttons, the bottom sheet shall transition from search/idle mode to a route selection panel showing alternative routes and action buttons.

| ID | Requirement |
|---|---|
| FR-69 | When a destination is selected on the Home Screen, the search bar shall be hidden and replaced by the route preview panel. |
| FR-70 | The route preview panel shall display the destination name at the top and list all available alternative routes as a vertical list; each row shall show the route label, estimated duration, distance, and an orange toll indicator when `hasTolls` is true. |
| FR-71 | The selected route row shall be indicated with a blue left accent bar; tapping any other row shall change the active selection. |
| FR-72 | The route preview panel shall display a **Cancel** button (outlined) and a **Start** button (filled blue) side-by-side at the bottom of the panel. |
| FR-73 | Tapping **Cancel** shall clear the selected destination, remove route polylines from the map, animate the map back to the user's current GPS location at the default zoom, and reset the bottom sheet to its default collapsed state. |
| FR-74 | Tapping **Start** shall start AR navigation using the currently selected route, equivalent to tapping "Start AR Navigation" on the Plan a Drive screen. |

---

### 3.13 Recent Search History

**Description:** The app shall record places the user has navigated to or searched for and display them in the Home Screen bottom sheet for quick re-selection.

| ID | Requirement |
|---|---|
| FR-75 | The Home Screen bottom sheet shall display a **Recent** section below the quick-access buttons when at least one place has previously been searched or navigated to. |
| FR-76 | The Recent section shall display up to **8** most recently used places, ordered newest-first, each showing a history icon, place name, and address. |
| FR-77 | Tapping a recent entry shall immediately set that place as the selected destination on the map, identical to selecting it from search results. |
| FR-78 | A place shall be added to the recent history whenever the user selects a destination from: the autocomplete search results, a quick-access button (Home / Work / Favourite), or a recent history entry itself. |
| FR-79 | If the same place is selected again it shall move to the top of the list rather than creating a duplicate entry. |
| FR-80 | Recent search history shall be persisted via `shared_preferences` and restored after app restart. |

---

## 4. Non-Functional Requirements

### 4.1 Performance

| ID | Requirement |
|---|---|
| NFR-01 | The AR overlay frame rate shall be maintained at a minimum of 30 frames per second (FPS). |
| NFR-02 | GPS location updates shall have a latency of no more than 1 second. |
| NFR-03 | The app shall launch and be ready for use within 5 seconds on a supported device. |

### 4.2 Usability

| ID | Requirement |
|---|---|
| NFR-04 | A first-time user shall be able to begin navigation within 3 steps (enter destination → confirm → navigate). |
| NFR-05 | All on-screen text and AR cues shall be legible in both bright sunlight and low-light conditions. |
| NFR-06 | The app shall follow Flutter's accessibility guidelines for font sizing and contrast. |

### 4.3 Reliability

| ID | Requirement |
|---|---|
| NFR-07 | The app shall handle GPS signal loss gracefully without crashing. |
| NFR-08 | The app shall handle failed API calls with appropriate error messages. |
| NFR-09 | The app shall not crash during normal navigation usage. |

### 4.4 Maintainability

| ID | Requirement |
|---|---|
| NFR-10 | The codebase shall follow Flutter/Dart best practices and be structured using a clear folder hierarchy. |
| NFR-11 | All functions and classes shall include Dart documentation comments (`///`). |
| NFR-12 | The project shall include a `README.md` with setup and run instructions. |

### 4.5 Security

| ID | Requirement |
|---|---|
| NFR-13 | The Google Maps API key shall be stored securely and not hardcoded in the public source code. |
| NFR-14 | Location data shall not be stored or transmitted beyond what is required for navigation. |

### 4.6 Data Persistence

| ID | Requirement |
|---|---|
| NFR-15 | Recent search history shall be loaded and displayed within 500 ms of the Home Screen becoming visible. |
| NFR-16 | Toll detection shall cover both the Google Directions API route-level `warnings` array and individual step-level HTML instructions to ensure reliable detection on Malaysian highway routes where warnings may not always be populated. |

---

## 5. External Interface Requirements

### 5.1 User Interface

- The **Home Screen** displays a full-screen interactive 2D map (CartoDB Voyager, Waze-style), with a floating search bar at the bottom, a "my location" button at the top right, and a hamburger menu icon (≡) at the top left that opens a side drawer with navigation options.
- The **AR Navigation Screen** displays the live camera feed full-screen, with AR overlays rendered transparently on top.
- A floating bottom panel shows destination search and autocomplete results.
- Overlay elements on the AR screen include: directional arrow icons, distance labels, and status text.

### 5.2 Hardware Interfaces

| Hardware | Usage |
|---|---|
| Rear Camera | Live camera feed for AR background |
| GPS/Location Sensor | Real-time location tracking |
| Accelerometer / Gyroscope | Device orientation for AR plane detection |
| Ambient Light Sensor | Measures lux to drive AR arrow auto-brightness (via the `light` package); feature degrades gracefully if absent |
| Internet (Wi-Fi / Mobile Data) | Google Maps API calls |

### 5.3 Software Interfaces

| Interface | Purpose |
|---|---|
| `ar_flutter_plugin` | ARCore integration for Flutter — renders AR content on camera |
| `google_maps_flutter` | Official Google Maps SDK for Flutter — map and navigation data |
| Google Maps Directions API | REST API for fetching route and turn-by-turn data |
| Google Maps Geocoding API | Converts text address input to GPS coordinates |
| Flutter Location / Geolocator Package | Retrieves real-time device GPS coordinates |

### 5.4 Communication Interfaces

- All external API calls are made over HTTPS.
- The app requires an active internet connection for route fetching.
- GPS uses the device's built-in location hardware (no additional communication protocol).

---

## 6. Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| **Language** | Dart | Primary programming language |
| **Framework** | Flutter | Cross-platform mobile UI framework |
| **IDE** | Visual Studio Code | Development environment |
| **AR Engine** | ARCore (via `ar_flutter_plugin`) | AR rendering on Android camera feed |
| **Maps & Navigation** | Google Maps Flutter SDK | Route data, GPS, map rendering |
| **Location** | `geolocator` Flutter package | Real-time device location |
| **Version Control** | Git + GitHub | Source code management |
| **Target Platform** | Android (API 26+) | Deployment platform |

### 6.1 Key Flutter Packages

```yaml
# pubspec.yaml dependencies (actual)
dependencies:
  flutter:
    sdk: flutter
  ar_flutter_plugin_2: ^0.0.3      # ARCore integration
  google_maps_flutter: ^2.5.0      # LatLng type + platform channel for route API
  flutter_map: ^6.1.0              # Tile-based map display (CartoDB Voyager, no Google SDK)
  latlong2: ^0.9.0                 # LatLng coordinate type for flutter_map
  geolocator: ^12.0.0              # GPS location stream
  http: ^1.1.0                     # HTTP requests to Google APIs
  flutter_polyline_points: ^2.0.0  # Route polyline decoding
  provider: ^6.1.0                 # State management (MVVM / ChangeNotifier)
  flutter_dotenv: ^5.1.0           # Load API keys from .env
  shared_preferences: ^2.2.0       # Persistent key-value storage (settings, Home/Work/Favourite)
  sqflite: ^2.3.3                  # SQLite database for bookmarked saved locations
  path: ^1.9.0                     # File path utilities (required by sqflite)
  light: ^5.0.0                    # Ambient light sensor for AR arrow auto-brightness
```

---

## 7. Constraints & Limitations

| Constraint | Detail |
|---|---|
| **Platform** | Android only — no iOS support in this phase |
| **AR Hardware** | Device must support ARCore (not all Android devices do) |
| **Internet Dependency** | Offline navigation is not supported |
| **HUD Integration** | The app will not integrate with any vehicle head-up display |
| **Voice Commands** | Voice-guided navigation is not included in this phase |
| **Speed** | Intended for pedestrian or very low-speed use — not validated for highway speeds |
| **Lighting** | AR performance may degrade in very low-light or high-glare environments |
| **GPS Accuracy** | Navigation accuracy is subject to device GPS hardware quality |

---

## 8. Assumptions & Dependencies

### 8.1 Assumptions

- The user's Android device supports ARCore.
- The user has granted camera and location permissions.
- The device has a stable internet connection during navigation.
- Testing will be conducted in outdoor open environments with clear GPS signal.

### 8.2 Dependencies

| Dependency | Reason |
|---|---|
| Google Maps API Key | Required for Maps SDK and Directions API calls |
| ARCore-compatible Android device | Required for AR overlay rendering |
| Flutter SDK (stable channel) | Development and build environment |
| `ar_flutter_plugin` (community package) | Core AR functionality |
| Active Google Cloud Project | For API key and Maps API billing setup |

---

*End of SRS Document — Version 2.4*

*Prepared by: Liew Sau Yang | Sunway University | Bachelor of Software Engineering (Hons)*
