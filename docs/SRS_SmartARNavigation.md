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
| **Version** | 1.0 |
| **Last Updated** | October 2025 |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Overall Description](#2-overall-description)
3. [System Features & Functional Requirements](#3-system-features--functional-requirements)
   - [3.7 Settings Screen](#37-settings-screen)
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
| FR-10 | The system shall parse route data including waypoints, turn types (left, right, forward), and distances. |
| FR-11 | The system shall recalculate the route automatically if the user deviates from the planned path. |

---

### 3.4 AR Overlay Rendering

**Description:** The app shall render augmented reality navigation cues on top of the live camera feed.

| ID | Requirement |
|---|---|
| FR-12 | The system shall overlay directional arrows (forward, turn left, turn right) on the camera view. |
| FR-13 | The system shall display the distance to the next turn as text on the AR overlay. |
| FR-14 | The system shall update AR overlays in real-time as the user's GPS position changes. |
| FR-15 | The system shall align AR overlays with the real-world environment using ARCore plane detection. |
| FR-16 | The system shall remove or update AR cues after a turn is completed. |

---

### 3.5 User Interface

**Description:** The app shall provide a simple, minimal UI inspired by Waze. The Home Screen displays a full-screen interactive 2D map with a floating search bar at the bottom and a settings button at the top left. The AR screen does not obstruct the camera view.

| ID | Requirement |
|---|---|
| FR-17 | The system shall display a full-screen interactive 2D Google Map as the Home Screen background. |
| FR-17a | The system shall provide a floating search bar anchored to the bottom of the Home Screen for destination entry. |
| FR-17b | The system shall display a Settings button (icon) at the top-left corner of the Home Screen. |
| FR-18 | The system shall display a "Start AR Navigation" button once the user has selected a destination. |
| FR-19 | The system shall display a stop/end navigation button during an active session. |
| FR-20 | The system shall show a status indicator for GPS signal strength. |
| FR-21 | The UI shall follow Material Design guidelines for consistency and accessibility. |

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
| FR-25 | The system shall provide a Settings screen accessible via the settings icon on the Home Screen. |
| FR-26 | The Settings screen shall include a Navigation Mode toggle (AR / 2D Map); the toggle shall be locked to AR mode in the current version. |
| FR-27 | The Settings screen shall allow the user to set a distance unit preference (kilometres or miles). |
| FR-28 | The Settings screen shall include a toggle to show or hide the speed display during navigation. |
| FR-29 | The Settings screen shall include a toggle to show or hide the estimated time of arrival (ETA) display during navigation. |
| FR-30 | The Settings screen shall allow the user to select a preferred AR arrow size (Small / Medium / Large). |
| FR-31 | The Settings screen shall include an AR overlay opacity slider adjustable between 50% and 100%. |
| FR-32 | The Settings screen shall display an About section showing the current app version and developer information. |

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

---

## 5. External Interface Requirements

### 5.1 User Interface

- The **Home Screen** displays a full-screen interactive 2D Google Map (Waze-style), with a floating search bar at the bottom and a settings icon at the top left.
- The **AR Navigation Screen** displays the live camera feed full-screen, with AR overlays rendered transparently on top.
- A floating bottom panel shows destination search and autocomplete results.
- Overlay elements on the AR screen include: directional arrow icons, distance labels, and status text.

### 5.2 Hardware Interfaces

| Hardware | Usage |
|---|---|
| Rear Camera | Live camera feed for AR background |
| GPS/Location Sensor | Real-time location tracking |
| Accelerometer / Gyroscope | Device orientation for AR plane detection |
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
# pubspec.yaml dependencies (planned)
dependencies:
  flutter:
    sdk: flutter
  ar_flutter_plugin: ^0.7.3     # ARCore integration
  google_maps_flutter: ^2.5.0   # Google Maps SDK
  geolocator: ^10.0.0           # GPS location
  http: ^1.1.0                  # API calls to Google Directions API
  flutter_polyline_points: ^2.0.0  # Route polyline rendering
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

*End of SRS Document — Version 1.0*

*Prepared by: Liew Sau Yang | Sunway University | Bachelor of Software Engineering (Hons)*
