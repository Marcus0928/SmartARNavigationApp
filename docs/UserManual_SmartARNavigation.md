# User Manual

## Smart AR Navigation App for Enhanced Driving Assistance

---

| Field | Details |
|---|---|
| **Project Title** | Smart AR Navigation App for Enhanced Driving Assistance |
| **Author** | Liew Sau Yang (22062475) |
| **Supervisor** | Dr Javid Iqbal Thirupattur |
| **Institution** | Sunway University — School of Computing and Artificial Intelligence |
| **Programme** | Bachelor of Software Engineering (Hons) |
| **App Version** | 1.0 |
| **Last Updated** | October 2025 |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Device Requirements](#2-device-requirements)
3. [Installation Guide](#3-installation-guide)
4. [Getting Started](#4-getting-started)
5. [Using the App](#5-using-the-app)
6. [Understanding the AR Overlays](#6-understanding-the-ar-overlays)
7. [Tips for Best Results](#7-tips-for-best-results)
8. [Troubleshooting](#8-troubleshooting)
9. [Known Limitations](#9-known-limitations)
10. [Developer Setup Guide](#10-developer-setup-guide)

---

## 1. Introduction

### 1.1 What is Smart AR Navigate?

**Smart AR Navigate** is a mobile navigation app that overlays real-time directional cues directly onto your phone's live camera view using Augmented Reality (AR). Instead of looking down at a 2D map, you hold up your phone and see arrows and distance information appear on top of the real world in front of you.

Think of it like Google Maps or Waze — but the directions are shown on your camera view rather than a flat map.

### 1.2 Who is this app for?

This app is designed for:
- Drivers looking for a more intuitive, heads-up navigation experience
- Anyone who wants AR directional cues overlaid on the real world instead of looking down at a 2D map
- Students and commuters navigating by car in outdoor environments

> ⚠️ **Safety Notice:** Always mount your phone securely on a dashboard or windscreen holder while driving. Never hold your phone while the vehicle is in motion. Always prioritise road safety over the app display.

---

## 2. Device Requirements

Before installing, make sure your device meets the following requirements:

| Requirement | Minimum |
|---|---|
| **Operating System** | Android 8.0 (Oreo) or higher |
| **ARCore Support** | Required — device must support Google Play Services for AR |
| **RAM** | 3GB or more |
| **Storage** | At least 100MB free space |
| **Camera** | Rear-facing camera required |
| **GPS** | Built-in GPS required |
| **Internet** | Mobile data or Wi-Fi required for navigation |

### 2.1 Check if Your Device Supports ARCore

1. Open the **Google Play Store**
2. Search for **"Google Play Services for AR"**
3. If it shows **"Installed"** or allows you to install → ✅ Your device is supported
4. If it shows **"Not compatible"** → ❌ This app will not work on your device

> ✅ **Confirmed compatible device:** OPPO Reno 7 5G (CPH2371)

---

## 3. Installation Guide

### 3.1 Installing the App (APK — Direct Install)

Since this is a prototype app, it is distributed as an APK file rather than through the Google Play Store.

**Step 1 — Enable Unknown Sources**
1. Go to your phone's **Settings**
2. Tap **Security** or **Privacy**
3. Enable **"Install unknown apps"** or **"Unknown sources"**
4. If prompted, allow your file manager or browser to install unknown apps

**Step 2 — Download the APK**
1. Receive the APK file from the developer
2. Open your phone's **File Manager**
3. Navigate to the folder where the APK was saved (usually **Downloads**)
4. Tap the APK file

**Step 3 — Install**
1. Tap **"Install"** when prompted
2. Wait for the installation to complete
3. Tap **"Open"** to launch the app, or find it in your app drawer

---

## 4. Getting Started

### 4.1 First Launch — Granting Permissions

The app requires two permissions to work. On first launch, you will be asked to grant both.

**Permission 1 — Camera**
```
"Smart AR Navigate would like to access your camera"
```
→ Tap **"Allow"**

This is needed to show the live camera feed for AR navigation.

**Permission 2 — Location**
```
"Smart AR Navigate would like to access your location"
```
→ Tap **"Allow only while using the app"**

This is needed for GPS tracking and route calculation.

> ⚠️ If you accidentally tap "Deny", you can grant permissions manually:
> 1. Go to **Settings → Apps → Smart AR Navigate → Permissions**
> 2. Enable **Camera** and **Location**

### 4.2 Home Screen Overview

After permissions are granted, you will see the **Home Screen**:

```
┌─────────────────────────┐
│   Smart AR Navigate     │  ← App name
├─────────────────────────┤
│  🔍  Where to?          │  ← Search bar — tap here to start
├─────────────────────────┤
│                         │
│    [ Map Preview ]      │  ← Shows your current location
│                         │
└─────────────────────────┘
```

---

## 5. Using the App

### 5.1 Setting a Destination

**Step 1** — Tap the **"Where to?"** search bar at the top of the Home Screen

**Step 2** — Type your destination
- Example: `"Sunway Pyramid"`, `"Sunway University Library"`, `"Petaling Jaya City Council"`
- A list of suggestions will appear as you type

**Step 3** — Tap on your destination from the suggestions list

**Step 4** — A **"Start AR Navigation"** button will appear at the bottom of the screen

```
┌─────────────────────────┐
│  Sunway University  ×   │  ← Selected destination
├─────────────────────────┤
│                         │
│    [ Map Preview ]      │  ← Route preview shown
│                         │
├─────────────────────────┤
│   [ Start AR Nav ▶ ]    │  ← Tap this to begin!
└─────────────────────────┘
```

---

### 5.2 Starting AR Navigation

**Step 1** — Tap **"Start AR Navigation"**

**Step 2** — The AR Navigation Screen will open, showing your live camera feed

**Step 3** — Mount your phone on a dashboard or windscreen holder, pointing the camera at the road ahead

**Step 4** — AR arrows and distance information will appear on the camera view

**Step 5** — Follow the arrows to reach your destination!

> 💡 **Tip:** Mount your phone on a windscreen holder at eye level for the best AR overlay alignment. Make sure the camera has a clear view of the road ahead.

---

### 5.3 During Navigation

While navigating, you will see the following on screen:

```
┌─────────────────────────┐
│ ←  Sunway University    │  ← Your destination (top bar)
├─────────────────────────┤
│                         │
│   [ LIVE CAMERA FEED ]  │
│                         │
│        ↑  50m           │  ← AR arrow + distance to next turn
│     Go Straight         │  ← Instruction text
│                         │
├─────────────────────────┤
│  ETA: 5 min   1.2 km    │  ← Estimated time and distance left
│           [ ■ Stop ]    │  ← Tap to stop navigation
└─────────────────────────┘
```

| Element | What it means |
|---|---|
| **Arrow** | The direction you need to go |
| **Distance (e.g. 50m)** | How far until the next turn |
| **Instruction text** | What action to take (Go Straight, Turn Left, Turn Right) |
| **ETA** | Estimated time remaining to destination |
| **Distance remaining** | Total distance left to destination |

---

### 5.4 Stopping Navigation

To stop navigation at any time:
1. Tap the **"Stop"** button at the bottom right of the AR Navigation Screen
2. The app will return to the Home Screen

Navigation also stops automatically when you **arrive at your destination**, and the app will show:
```
✅ You have arrived!
```

---

### 5.5 If the Route Changes (Rerouting)

If you drive off the planned route, the app will automatically recalculate:

1. You will see the message: **"Recalculating route..."**
2. Wait a few seconds for the new route to load
3. New AR arrows will appear for the updated route

> 💡 **Tip:** If rerouting takes too long, stop navigation and start again with the same destination.

---

## 6. Understanding the AR Overlays

### 6.1 Arrow Types

| Arrow | Meaning |
|---|---|
| ↑ | Go straight ahead |
| ← | Turn left |
| → | Turn right |
| ↓ | Make a U-turn |

### 6.2 Distance Display

The distance shown next to the arrow is the distance to your **next turn**, not your final destination.

| Display | Meaning |
|---|---|
| `500m` | Your next turn is 500 metres ahead |
| `50m` | Your next turn is coming up soon — get ready |
| `10m` | Turn now! |

### 6.3 Arrow Colour Meaning

| Colour | Meaning |
|---|---|
| 🟢 Green | Normal navigation — follow the arrow |
| 🟡 Amber | Rerouting in progress |

---

## 7. Tips for Best Results

### 7.1 GPS Accuracy
- Use the app **outdoors** in open areas for the best GPS signal
- Avoid using near tall buildings, tunnels, or dense tree cover — these block GPS signals
- Give the app **10–15 seconds** after launching to get a strong GPS lock before starting navigation

### 7.2 AR Overlay Quality
- Use the app in **daytime** with good lighting for the best AR performance
- **Avoid very bright sunlight** pointing directly at the camera — it can wash out the overlays
- Hold your phone **steady** — excessive shaking reduces AR tracking quality

### 7.3 Battery & Performance
- AR and GPS both use significant battery — ensure your phone is **sufficiently charged** before a long navigation session
- Close other background apps before using the app for smoother performance
- The app works best on **4G/LTE** — weak mobile data may cause slower route loading

### 7.4 Navigation Accuracy
- For best results, start navigation **while stationary** so the app can get your precise starting position
- The GPS and AR overlays update approximately every second — suitable for normal driving speeds
- If arrows seem misaligned, try stopping the car safely and slowly rotating your phone — ARCore will recalibrate

---

## 8. Troubleshooting

### ❌ "The app won't open / crashes on launch"
- Ensure your device runs **Android 8.0 or higher**
- Ensure **Google Play Services for AR** is installed on your device
- Try restarting your phone and opening the app again
- Reinstall the APK if the issue persists

### ❌ "No AR arrows are showing on the camera"
- Make sure you granted **Camera permission** to the app
- Go outdoors — ARCore works best in well-lit outdoor environments
- Try moving your phone slowly around in different directions to help ARCore initialize
- Check that ARCore (Google Play Services for AR) is up to date in the Play Store

### ❌ "My location is wrong on the map"
- Go outside to an open area for a better GPS signal
- Wait 15–20 seconds for the GPS to lock on to your position
- Make sure **Location permission** is granted and location services are turned ON in your phone settings

### ❌ "Search bar shows no results"
- Check your internet connection (mobile data or Wi-Fi)
- Try typing more characters — results appear after 3+ characters
- Try a more specific search term (e.g. "Sunway University, Subang Jaya" instead of just "Sunway")

### ❌ "Rerouting takes very long or doesn't work"
- Check your internet connection — rerouting requires an active connection to Google Maps API
- Stop navigation and restart with the same destination
- Move to an area with better mobile data coverage

### ❌ "The distance shown seems wrong"
- GPS accuracy can vary by ±10 metres depending on your device and environment
- This is a known limitation of GPS technology and is within the acceptable tolerance of the app
- For best distance accuracy, use the app in open outdoor areas

---

## 9. Known Limitations

These are known limitations of the current Version 1.0 of the app. They are documented for transparency and may be addressed in future versions.

| Limitation | Detail |
|---|---|
| **Android only** | The app does not support iOS devices |
| **Driving speeds** | Optimised for normal urban driving speeds — performance at highway speeds may vary |
| **No offline navigation** | An internet connection is required at all times |
| **No voice guidance** | The app is visual only — no spoken turn instructions in this version |
| **No 2D map view** | Only AR camera view is available in this version |
| **GPS accuracy** | Distance accuracy is ± 10 metres — dependent on device GPS quality |
| **Tunnel / underpass** | AR and GPS performance degrades in tunnels or underpasses |
| **Lighting sensitivity** | AR overlays may be harder to see in very bright sunlight or at night |
| **No traffic data** | The app does not account for real-time traffic conditions |

---

## 10. Developer Setup Guide

This section is for developers who want to run the app from source code.

### 10.1 Prerequisites

Make sure the following are installed on your development machine:

| Tool | Version | Download |
|---|---|---|
| Flutter SDK | Stable channel (3.x+) | flutter.dev |
| Dart | Included with Flutter | — |
| VS Code | Latest | code.visualstudio.com |
| Flutter VS Code Extension | Latest | VS Code Marketplace |
| Android SDK | API 26+ | Via Android Studio SDK Manager |
| Git | Latest | git-scm.com |

### 10.2 Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/smart_ar_navigation.git
cd smart_ar_navigation
```

### 10.3 Install Dependencies

```bash
flutter pub get
```

### 10.4 Configure API Keys

1. Create a file called `.env` in the project root
2. Add your Google Maps API key:

```
GOOGLE_MAPS_API_KEY=your_api_key_here
```

3. Make sure `.env` is listed in your `.gitignore` file — **never commit your API key to Git**

### 10.5 Enable Google Maps on Android

Open `android/app/src/main/AndroidManifest.xml` and add your API key:

```xml
<meta-data
    android:name="com.google.android.geo.API_KEY"
    android:value="${GOOGLE_MAPS_API_KEY}"/>
```

### 10.6 Run the App

Connect your Android device via USB with **USB Debugging** enabled, then run:

```bash
flutter run
```

Or press **F5** in VS Code with your device connected.

### 10.7 Build APK for Distribution

```bash
flutter build apk --release
```

The APK will be located at:
```
build/app/outputs/flutter-apk/app-release.apk
```

---

> 📝 **For questions or issues, contact the developer:**
> Liew Sau Yang — Sunway University, Bachelor of Software Engineering (Hons)

---

*End of User Manual — Version 1.0*

*Prepared by: Liew Sau Yang | Sunway University | Bachelor of Software Engineering (Hons)*
