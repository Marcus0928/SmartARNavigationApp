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

- 📷 **Live Camera AR View** — Real-time camera feed with AR overlays
- 🗺️ **Google Maps Integration** — Accurate route and navigation data
- 🧭 **Turn-by-Turn AR Directions** — Arrows and distance shown on camera
- 📍 **Real-Time GPS Tracking** — Continuous location updates
- 🔄 **Auto Rerouting** — Recalculates route when you go off path
- ✅ **Arrival Detection** — Notifies when you reach your destination

---

## 🛠️ Built With

| Technology | Purpose |
|---|---|
| [Flutter](https://flutter.dev) | Cross-platform mobile UI framework |
| [Dart](https://dart.dev) | Programming language |
| [ARCore](https://developers.google.com/ar) | AR rendering via `ar_flutter_plugin` |
| [Google Maps Flutter SDK](https://pub.dev/packages/google_maps_flutter) | Maps and navigation data |
| [Geolocator](https://pub.dev/packages/geolocator) | Real-time GPS location |
| [Google Maps Directions API](https://developers.google.com/maps/documentation/directions) | Turn-by-turn route data |
| [Google Maps Places API](https://developers.google.com/maps/documentation/places) | Destination search autocomplete |

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
│   ├── app.dart                 # MaterialApp setup & routing
│   ├── core/                    # Shared constants, enums, utilities
│   ├── models/                  # Data classes
│   ├── services/                # ARCore & GPS service wrappers
│   ├── repositories/            # Google Maps API communication
│   ├── viewmodels/              # Business logic (MVVM)
│   └── views/                   # Screens & widgets (UI)
│
├── assets/
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

Then add it to `android/app/src/main/AndroidManifest.xml`:
```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY}"/>
```

> ⚠️ Never commit your `.env` file or API key to Git. It is already listed in `.gitignore`.

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
  ar_flutter_plugin: ^0.7.3        # ARCore integration
  google_maps_flutter: ^2.5.0      # Google Maps SDK
  geolocator: ^10.0.0              # GPS location
  http: ^1.1.0                     # HTTP requests to Google APIs
  flutter_polyline_points: ^2.0.0  # Route polyline rendering
  provider: ^6.1.0                 # State management (MVVM)
  flutter_dotenv: ^5.1.0           # Load API keys from .env
```

---

## 📱 Tested Device

| Device | Model | ARCore | Android | Status |
|---|---|---|---|---|
| OPPO Reno 7 5G | CPH2371 | ✅ Pre-installed | Android 11/12 | ✅ Confirmed |

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
- [ ] Project setup & folder structure
- [ ] Permissions & splash screen
- [ ] Home screen with destination search
- [ ] Google Maps route fetching
- [ ] AR Navigation screen with live camera
- [ ] AR overlay rendering (arrows + distance)
- [ ] Real-time GPS tracking & AR updates
- [ ] Auto rerouting
- [ ] Arrival detection
- [ ] Manual testing & bug fixes
- [ ] Final APK build & submission

---

## ⚠️ Known Limitations

- Android only — no iOS support
- Requires active internet connection
- No voice guidance in this version
- No 2D map toggle in this version
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
