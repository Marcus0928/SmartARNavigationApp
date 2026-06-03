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
| **App Version** | 1.1 |
| **Last Updated** | May 2026 |

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
┌──────────────────────────────┐
│ ≡                     📍  ↑  │  ← Menu (left) + My Location / Compass (right)
│                              │
│   [Full-Screen Map]          │  ← Interactive map centred on your location
│                              │
├──────────────────────────────┤  ← Drag handle — pull up to expand sheet
│  🔍  Where to?               │  ← Search bar (tap to search)
│  [🏠 Home][💼 Work][⭐ Fav][🔖]│  ← Quick-access buttons
│                              │
│  RECENT                      │  ← Recent search history (appears after first use)
│  🕐 Sunway Pyramid        ↗  │
│  🕐 KLCC Twin Towers      ↗  │
└──────────────────────────────┘
```

| Element | What it does |
|---|---|
| **≡ Menu** | Opens the side drawer (Plan a Drive, Settings, Profile…) |
| **📍 My Location** | Animates the map back to your current position |
| **↑ Compass** | Resets map rotation to north |
| **Search bar** | Type any destination to search |
| **Quick buttons** | Tap Home/Work/Favourite to navigate there instantly; tap to set if empty |
| **Recent** | Your last 8 destinations — tap any to navigate again |

---

## 5. Using the App

### 5.1 Setting a Destination

**Step 1** — Tap the **"Where to?"** search bar

**Step 2** — Type your destination
- Example: `"Sunway Pyramid"`, `"Sunway University Library"`, `"Petaling Jaya City Council"`
- A list of suggestions will appear as you type

**Step 3** — Tap on your destination from the suggestions list

**Step 4** — The search bar disappears and a **route selection panel** appears showing up to three route options

```
┌──────────────────────────────┐
│  📍  Sunway Pyramid          │  ← Destination name
│  ─────────────────────────── │
│ ▌Fastest    24 min  18.2 km  │  ← Selected route (blue left bar)
│  Alt 1      31 min  22.4 km 🏧│  ← 🏧 = route includes toll roads
│  Alt 2      35 min  25.1 km  │
│  ─────────────────────────── │
│  [  Cancel  ] [ ▶  Start  ] │  ← Cancel to go back, Start to navigate
└──────────────────────────────┘
```

**Step 5** — Tap a route row to select it; the map updates to show the highlighted route

**Step 6** — Tap **Start** to begin AR navigation, or **Cancel** to go back to the search bar

> 💡 **Tip:** Look for the 🏧 **Toll** label on any route row — it means that route passes through a toll road. Choose a toll-free route if you want to avoid paying tolls.

---

### 5.2 Using Quick-Access Buttons

The four quick-access buttons below the search bar let you navigate to saved locations instantly.

| Button | What it does |
|---|---|
| **🏠 Home** | Navigate to your saved Home address |
| **💼 Work** | Navigate to your saved Work address |
| **⭐ Favourite** | Navigate to your saved Favourite location |
| **🔖 Saved** | Browse your saved places |

**If a button is empty (not yet set):**
1. Tap the button to open the **Save Place** screen
2. Search for a location and tap **Save**
3. The button will now show the saved address and navigate to it on next tap

**If a button already has a saved location:**
1. Tap the button — the route selection panel appears immediately for that destination
2. Select a route and tap **Start** to begin navigation

---

### 5.3 Using Recent Search History

After you navigate to any destination, it is automatically saved in your recent search history.

- Your last **8 destinations** are displayed below the quick-access buttons
- Each entry shows a clock icon (🕐) on the left and an arrow (↗) on the right
- Tap any entry to immediately open the route selection panel for that place
- Recent history is preserved after closing and reopening the app

```
│  RECENT                      │
│  🕐 Sunway Pyramid        ↗  │  ← Tap row to select as destination
│  🕐 KLCC Twin Towers      ↗  │
│  🕐 Sunway University     ↗  │
```

> 💡 **Tip:** The most recently visited place always appears at the top of the list.

---

### 5.4 Plan a Drive

**Plan a Drive** lets you compare routes and check toll information before you start driving.

**Step 1** — Tap the **≡ Menu** button (top-left of the home screen)

**Step 2** — Tap **"Plan a Drive"**

**Step 3** — Enter your **starting point** (defaults to current location) and **destination**

**Step 4** — Toggle **"Avoid Tolls"** if you want toll-free routes only

**Step 5** — Tap **"Get Directions"** to fetch available routes

**Step 6** — Browse the route cards at the bottom of the screen:
- Each card shows **duration**, **distance**, and a 🏧 **Toll** badge if the route passes through a toll road
- Tap a card to highlight that route on the map

> 💡 **Tip:** Use Plan a Drive when you want to compare route options or verify toll costs before setting off.

---

### 5.5 Starting AR Navigation

**Step 1** — Tap **"Start"**

**Step 2** — The AR Navigation Screen will open, showing your live camera feed

**Step 3** — Mount your phone on a dashboard or windscreen holder, pointing the camera at the road ahead

**Step 4** — AR arrows and distance information will appear on the camera view

**Step 5** — Follow the arrows to reach your destination!

> 💡 **Tip:** Mount your phone on a windscreen holder at eye level for the best AR overlay alignment. Make sure the camera has a clear view of the road ahead.

---

### 5.6 During Navigation

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

### 5.7 Stopping Navigation / Cancelling a Route

**Before navigation starts (route selection panel):**
- Tap **"Cancel"** to dismiss the route selection panel
- The drawer returns to its default position and the map re-centres on your current location

**During active AR navigation:**
- Tap the **"Stop"** button at the bottom right of the AR Navigation Screen
- The app returns to the Home Screen

Navigation also stops automatically when you **arrive at your destination**, and the app will show:
```
✅ You have arrived!
```

---

### 5.8 If the Route Changes (Rerouting)

If you drive off the planned route, the app will automatically recalculate:

1. You will see the message: **"Recalculating route..."**
2. Wait a few seconds for the new route to load
3. New AR arrows will appear for the updated route

> 💡 **Tip:** If rerouting takes too long, stop navigation and start again with the same destination.

---

## 6. Understanding the AR Overlays

### 6.1 Arrow Types

All arrows are drawn as animated glowing shapes directly on the camera feed. The arrow colour changes as you approach a turn (see Section 6.3).

| Arrow shape | Direction | Meaning |
|---|---|---|
| ^^^ (3 upward chevrons) | Forward | Go straight ahead |
| >>> (3 right chevrons) | Turn right | Turn right at the next junction |
| <<< (3 left chevrons) | Turn left | Turn left at the next junction |
| >> (2 right chevrons, angled up) | Keep right | Bear right / stay on the right lane |
| << (2 left chevrons, angled up) | Keep left | Bear left / stay on the left lane |
| U-arc with downward arrowhead | U-turn | Make a U-turn and go back the way you came |
| 3/4-circle arc with exit arrowhead | Roundabout | Enter the roundabout; take the exit shown by the number inside the arc |

### 6.2 Distance Display

The distance shown next to the arrow is the distance to your **next turn**, not your final destination.

| Display | Meaning |
|---|---|
| `500m` | Your next turn is 500 metres ahead |
| `50m` | Your next turn is coming up soon — get ready |
| `10m` | Turn now! |

### 6.3 Arrow Colour Meaning

The arrow colour changes automatically as you get closer to the next turn. No action is needed — it is a visual cue to help you prepare in time.

| Colour | Distance to next turn | Meaning |
|---|---|---|
| 🟢 Cyan / Green | More than 100 m | Normal navigation — follow the arrow, plenty of time |
| 🟡 Amber / Yellow | 50 – 100 m | Approaching the turn — start preparing to turn |
| 🔴 Red | Less than 50 m | Turn now — the turn is immediately ahead |

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

*End of User Manual — Version 1.1*

*Prepared by: Liew Sau Yang | Sunway University | Bachelor of Software Engineering (Hons)*
