# 🚗 Smart AR Navigation App for Enhanced Driving Assistance

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white)
![Android](https://img.shields.io/badge/Android-API_26+-3DDC84?style=for-the-badge&logo=android&logoColor=white)
![ARCore](https://img.shields.io/badge/ARCore-Supported-FF6F00?style=for-the-badge&logo=google&logoColor=white)

> A Final Year Project (FYP) for Bachelor of Software Engineering (Hons)
> Sunway University — School of Computing and Artificial Intelligence

---

## 📖 About The Project

**Smart AR Navigate** is an Android mobile application that overlays real-time AR navigation cues — directional arrows, turn instructions, and distance markers — directly onto the device's live camera feed. Instead of glancing down at a 2D map, drivers can see navigation directions superimposed on the real world in front of them.

Think of it as **Google Maps or Waze, but with AR directions on your camera view.**

### 🎯 Key Features

- 📷 **Live Camera AR View** — Real-time camera feed with AR overlays powered by ARCore
- 🗺️ **Google Maps Integration** — Accurate route and navigation data via Directions & Places API
- 🎨 **Waze-Inspired Map Style** — CartoDB Voyager tiles: blue water, green parks, amber highways, no Google branding
- 🧭 **Turn-by-Turn AR Directions** — Seven distinct arrow types: straight, turn left/right, keep left/right, U-turn, and roundabout with exit number
- 🎨 **Approach-Stage Arrow Colours** — Arrow colour changes automatically as you near a turn: cyan (> 200 m), amber (50–200 m), red (< 50 m)
- 🔄 **Roundabout Guidance** — Custom-painted 3/4-circle arc (CCW) with a glow trail, exit arrowhead at the left, entry indicator line at 135°, and the exit number centred inside the arc; exit number is parsed from the structured `exit` field or falls back to the ordinal in `html_instructions` (e.g. "take the 3rd exit")
- ⚡ **Early Turn Warning** — Arrow switches to the upcoming non-forward turn direction up to 1 km ahead (instead of at the last moment), giving drivers ample time to prepare; distance displayed always reflects that upcoming turn
- 🏷️ **Road Name Display** — AR overlay shows only the upcoming street name, extracted from the bold text in Google Maps step instructions
- 📍 **Real-Time GPS Tracking** — Continuous location with Waze-style directional arrow and accuracy ring
- 🔄 **Auto Rerouting** — Detects off-route deviation using perpendicular distance to the nearest route segment (50 m threshold, 30 s cooldown); displays a "Recalculating route…" banner on the AR screen during recalculation
- 🚀 **Faster Route Suggestion** — Checks for a faster route every 2 minutes in the background; offers a "Faster route available — Save X min" banner with one-tap switch, auto-dismissed after 15 s
- 🧭 **Heading-Biased Route Fetch** — Passes the device's compass heading to the Directions API so routes start in the correct direction, eliminating phantom U-turns at navigation start
- ✅ **Arrival Detection** — Notifies when you reach your destination (within 20 m)
- 📱 **Screen Wake Lock** — Display stays on automatically throughout the AR navigation session
- 📋 **Waze-Style Side Menu** — Hamburger (≡) button opens a drawer with Profile, Plan a drive, Inbox, Settings, Help & Feedback, and Shutdown
- 🎬 **Animated Map Transitions** — Smooth eased fly-to animation (650 ms, `easeInOut`) when centering on location
- 🏠 **Quick-Access Saved Places** — Home, Work, and Favourite one-tap buttons persist destinations via `shared_preferences`
- 🔖 **Bookmarked Locations** — Bookmark any search result; a SQLite-backed list of saved places is accessible via the "Saved Places" button in the bottom sheet

---

## 🛠️ Built With

| Technology | Purpose |
|---|---|
| [Flutter](https://flutter.dev) | Cross-platform mobile UI framework |
| [Dart](https://dart.dev) | Programming language |
| [ARCore](https://developers.google.com/ar) | AR rendering via `ar_flutter_plugin_2` |
| [flutter_map](https://pub.dev/packages/flutter_map) | Tile-based map display (no Google Maps SDK) |
| [CartoDB Voyager](https://carto.com/basemaps/) | OpenStreetMap-based tile style — Waze-like colours (blue water, green parks, amber highways) |
| [Google Maps Directions API](https://developers.google.com/maps/documentation/directions) | Route and turn-by-turn data |
| [Google Maps Places API](https://developers.google.com/maps/documentation/places) | Destination search autocomplete |
| [Geolocator](https://pub.dev/packages/geolocator) | Real-time GPS location |
| [sqflite](https://pub.dev/packages/sqflite) | SQLite database for saved locations list |
| [shared_preferences](https://pub.dev/packages/shared_preferences) | Persistent key-value storage for Home / Work / Favourite places and settings |
| [wakelock_plus](https://pub.dev/packages/wakelock_plus) | Keeps the screen on during AR navigation |

---

## 📁 Project Structure

```
smart_ar_navigation/
│
├── docs/                        # Project documentation
│   ├── SRS_SmartARNavigation.md
│   ├── SDD_SmartARNavigation.md
│   ├── API_SmartARNavigation.md
│   ├── TestPlan_SmartARNavigation.md
│   └── UserManual_SmartARNavigation.md
│
├── lib/
│   ├── main.dart                # App entry point
│   ├── app.dart                 # MaterialApp setup, routing & Provider tree
│   ├── core/                    # Shared constants, enums, utilities
│   │   ├── enums/
│   │   │   ├── turn_direction.dart              # forward, left, right, keepLeft, keepRight, uTurn, roundabout
│   │   │   ├── navigation_status.dart           # idle, loading, navigating, rerouting, arrived
│   │   │   └── navigation_approach_stage.dart   # far (>200m), approaching (50-200m), imminent (<50m)
│   │   └── utils/
│   │       ├── route_parser.dart        # Parses Google Maps steps; extracts street name & exit number
│   │       ├── instruction_builder.dart # Builds human-readable instruction text from maneuver string
│   │       └── location_utils.dart      # calculateDistance / findNextTurn helpers
│   ├── models/                  # Data classes
│   ├── services/                # ARCore, GPS, and SQLite service wrappers
│   ├── repositories/            # Google Maps API and SQLite communication
│   ├── viewmodels/              # Business logic (MVVM)
│   └── views/                   # Screens & widgets (UI)
│
├── assets/
│   ├── map_style.json           # Waze-inspired Google Maps custom style
│   ├── images/                  # App logo
│   └── icons/                   # AR arrow icons
│
├── test/                        # Unit tests
├── pubspec.yaml                 # Flutter dependencies
├── .env                         # API keys (not committed to Git)
└── README.md
```

---

## 🏗️ Architecture

This project follows the **MVVM (Model-View-ViewModel)** architecture pattern.

```
View  ──────▶  ViewModel  ──────▶  Model
(UI)          (Business Logic)    (Data / Services / APIs)
```

- **View** — Flutter widgets and screens
- **ViewModel** — Business logic using `ChangeNotifier` + `Provider`
- **Model** — Data classes, repositories, and service wrappers

---

## 🚀 Getting Started

### Prerequisites

Make sure the following are installed:

- [Flutter SDK](https://flutter.dev/docs/get-started/install) (stable channel)
- [VS Code](https://code.visualstudio.com/) with Flutter & Dart extensions
- [Git](https://git-scm.com/)
- Android device with ARCore support (API 26+)
- A Google Cloud project with the following APIs enabled:
  - Maps SDK for Android
  - Directions API
  - Places API

### Installation

**1. Clone the repository**
```bash
git clone https://github.com/YOUR_USERNAME/SmartARNavigationApp.git
cd SmartARNavigationApp
```

**2. Install Flutter dependencies**
```bash
flutter pub get
```

**3. Configure your API key**

Create a `.env` file in the project root:
```
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
```

The key is loaded at runtime by `flutter_dotenv` and is **not** stored in `AndroidManifest.xml` or any tracked file.

> ⚠️ Never commit your `.env` file or API key to Git. `.env` is already listed in `.gitignore`.

**4. Connect your Android device**

Enable **USB Debugging** on your Android device:
1. Go to **Settings → About Phone**
2. Tap **Build Number** 7 times to enable Developer Options
3. Go to **Settings → Developer Options**
4. Enable **USB Debugging**
5. Connect your phone via USB

**5. Run the app**
```bash
flutter run
```

Or press **F5** in VS Code with your device connected.

---

## 📦 Building the APK

To build a release APK for distribution:

```bash
flutter build apk --release
```

The APK will be at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

## 📋 Flutter Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  ar_flutter_plugin_2: ^0.0.3      # ARCore integration
  flutter_map: ^6.1.0              # Tile-based map display (no Google Maps SDK)
  latlong2: ^0.9.0                 # LatLng coordinate type for flutter_map
  google_maps_flutter: ^2.5.0      # LatLng type + platform channel for route API
  geolocator: ^12.0.0              # GPS location
  http: ^1.1.0                     # HTTP requests to Google APIs
  flutter_polyline_points: ^2.0.0  # Route polyline rendering
  provider: ^6.1.0                 # State management (MVVM)
  flutter_dotenv: ^5.1.0           # Load API keys from .env
  shared_preferences: ^2.2.0       # Persistent key-value storage (settings, Home/Work/Favourite)
  sqflite: ^2.3.3                  # SQLite database for bookmarked saved locations list
  path: ^1.9.0                     # File path utilities (required by sqflite)
  wakelock_plus: ^1.2.8            # Keeps screen on during AR navigation
```

---

## 📱 Tested Device

| Device | Model | ARCore | Android | Status |
|---|---|---|---|---|
| OPPO Reno 7 5G | CPH2371 | ✅ Pre-installed | Android 11/12 | ✅ Confirmed |
| OPPO Reno 15 5G | CPH2825 | ✅ Pre-installed | Android 16 | ✅ Confirmed |

---

## 📄 Documentation

All project documentation is located in the `/docs` folder:

| Document | Description |
|---|---|
| [SRS](docs/SRS_SmartARNavigation.md) | Software Requirements Specification |
| [SDD](docs/SDD_SmartARNavigation.md) | System Design Document |
| [API Docs](docs/API_SmartARNavigation.md) | API & Function Documentation |
| [Test Plan](docs/TestPlan_SmartARNavigation.md) | Manual Test Cases & Results |
| [User Manual](docs/UserManual_SmartARNavigation.md) | End User & Developer Guide |

---

## 🗺️ Roadmap

- [x] Project documentation
- [x] Project setup & folder structure
- [x] Permissions & splash screen
- [x] Home screen with Waze-style map (CartoDB Voyager tiles)
- [x] Waze-style location indicator (directional arrow + accuracy ring)
- [x] Animated map fly-to transitions (easeInOut, 650 ms)
- [x] Destination search with autocomplete (Places API)
- [x] Waze-style hamburger side menu (Profile, Plan a drive, Inbox, Settings, Help, Shutdown)
- [x] Settings screen (display prefs, AR options, persisted via shared_preferences)
- [x] Quick-access saved places (Home, Work, Favourite — SharedPreferences)
- [x] Bookmarked locations list (SQLite — unlimited saved places)
- [x] Google Maps route fetching (Directions API) with multi-route preview
- [x] AR Navigation screen with live camera feed (ARCore)
- [x] AR overlay rendering — 7 arrow types: straight, left, right, keep left/right, U-turn, roundabout
- [x] Roundabout overlay with custom-painted exit number diagram
- [x] Street name extraction from Google Maps step instructions
- [x] Real-time GPS tracking & AR overlay updates
- [x] Arrival detection (20 m proximity threshold)
- [x] Auto rerouting — segment-based perpendicular off-route detection (50 m threshold, 30 s cooldown); rerouting banner on AR screen
- [x] Faster route suggestion — background check every 2 min; banner with Switch/Dismiss; auto-dismiss after 15 s
- [x] Heading-biased route fetch — compass heading passed to Directions API; phantom U-turn guard in `initializeOverlay()`
- [x] Screen wake lock — display stays on throughout AR navigation
- [x] Transparent edge-to-edge status bar — no overlap with system UI
- [x] AR camera feed restart on app resume — fixes black screen after backgrounding
- [x] Route refresh from current location — Routes button re-fetches from GPS position
- [x] Resume / Go / Start button labels — reflects in-progress navigation state
- [x] Early turn warning — arrow preemptively shows upcoming non-forward turn (all 6 types) within 1 km; 1000/1100 m hysteresis gate prevents oscillation
- [x] GPS accuracy improvement — passed-turn threshold raised from 10 m to 25 m for Malaysian urban GPS conditions
- [x] Roundabout exit number fallback — parses ordinal from `html_instructions` when structured `exit` field is absent
- [ ] Voice guidance
- [ ] Manual testing & bug fixes
- [ ] Final APK build & submission

---

## ⚠️ Known Limitations

- Android only — no iOS support
- Requires active internet connection
- No voice guidance in this version
- AR performance may vary in tunnels or low-light conditions

---

## 👨‍💻 Author

**Liew Sau Yang**
Student ID: 22062475
Bachelor of Software Engineering (Hons)
Sunway University — School of Computing and Artificial Intelligence

**Supervisor:** Dr Javid Iqbal Thirupattur

---

## 📜 License

This project is developed as an academic Final Year Project for Sunway University.
Not licensed for commercial use.

---

*Smart AR Navigation App — FYP 2025 | Sunway University*
