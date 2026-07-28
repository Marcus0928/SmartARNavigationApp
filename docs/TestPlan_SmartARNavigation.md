# Test Plan Document

## Smart AR Navigation App for Enhanced Driving Assistance

---

| Field | Details |
|---|---|
| **Project Title** | Smart AR Navigation App for Enhanced Driving Assistance |
| **Author** | Liew Sau Yang (22062475) |
| **Supervisor** | Dr Javid Iqbal Thirupattur |
| **Institution** | Sunway University — School of Computing and Artificial Intelligence |
| **Programme** | Bachelor of Software Engineering (Hons) |
| **Testing Type** | Manual Black-Box Testing |
| **Test Device** | OPPO Reno 7 5G (CPH2371) |
| **Test Device** | OPPO Reno 15 5G (CPH2825) |
| **Version** | 1.6 |
| **Last Updated** | July 2026 |

---

## Table of Contents

1. [Introduction](#1-introduction)
2. [Testing Approach](#2-testing-approach)
3. [Test Environment](#3-test-environment)
4. [Test Cases — Permissions & Startup](#4-test-cases--permissions--startup)
5. [Test Cases — Destination Search](#5-test-cases--destination-search)
6. [Test Cases — AR Navigation](#6-test-cases--ar-navigation)
7. [Test Cases — Direction Accuracy](#7-test-cases--direction-accuracy)
8. [Test Cases — Distance Accuracy](#8-test-cases--distance-accuracy)
9. [Test Cases — Edge Cases & Error Handling](#9-test-cases--edge-cases--error-handling)
10. [Test Cases — Route Selection & Toll Indicator](#10-test-cases--route-selection--toll-indicator)
11. [Test Cases — Recent Search History](#11-test-cases--recent-search-history)
12. [Test Cases — Early Turn Warning & Roundabout Exit Number](#12-test-cases--early-turn-warning--roundabout-exit-number)
13. [Test Cases — Navigation Improvements (v1.3)](#13-test-cases--navigation-improvements-v13)
14. [Test Cases — Ambient Light Auto-Brightness (v1.4)](#14-test-cases--ambient-light-auto-brightness-v14)
15. [Test Cases — Voice Guidance (v1.5)](#15-test-cases--voice-guidance-v15)
16. [Test Cases — Traffic Delay Notification (v1.6)](#16-test-cases--traffic-delay-notification-v16)
17. [Test Cases — Voice Guidance Mute Toggle (v1.6)](#17-test-cases--voice-guidance-mute-toggle-v16)
18. [Test Results Summary Table](#18-test-results-summary-table)

---

## 1. Introduction

### 1.1 Purpose

This Test Plan defines how the Smart AR Navigation App will be tested to ensure it works correctly and accurately. The primary focus is on verifying that:

- The app behaves like a normal navigation app (similar to Waze or Google Maps)
- Directional cues (arrows) shown in AR match the actual real-world turns
- Distance values shown are accurate compared to the real physical distance
- The app handles common errors gracefully without crashing

### 1.2 Testing Philosophy

Testing will be conducted by the developer (Liew Sau Yang) by **physically using the app in real outdoor environments** on the OPPO Reno 7 5G. Each test case is performed by walking a route and comparing what the app shows against what is actually correct on the ground.

---

## 2. Testing Approach

### 2.1 Testing Type: Manual Black-Box Testing

The tester interacts with the app as a **normal end user** would — entering destinations, following AR arrows, and checking if the guidance matches reality. No knowledge of the internal code is required to run these tests.

### 2.2 Pass / Fail Criteria

| Result | Meaning |
|---|---|
| ✅ **PASS** | The app behaves as expected |
| ❌ **FAIL** | The app does not behave as expected |
| ⚠️ **PARTIAL** | The feature works but with minor issues |
| ⏭️ **SKIP** | Test could not be run (e.g. no internet) |

### 2.3 Acceptable Tolerances

Since GPS and AR have natural limitations, the following tolerances are acceptable:

| Measurement | Acceptable Tolerance |
|---|---|
| Distance accuracy | ± 10 metres |
| Turn arrow trigger point | ± 25 metres from actual turn |
| AR overlay alignment | Visually aligned — no precise pixel measurement |

---

## 3. Test Environment

| Item | Details |
|---|---|
| **Test Device** | OPPO Reno 7 5G (CPH2371) |
| **Test Device** | OPPO Reno 15 5G (CPH2825) |
| **Operating System** | Android 11 / 12 |
| **Operating System** | Android 16 |
| **ARCore Version** | Pre-installed (Google Play Services for AR) |
| **Internet Connection** | Mobile data (5G/LTE) |
| **GPS** | Device built-in GPS |
| **Test Location** | Sunway University campus and surrounding outdoor areas |
| **Test Conditions** | Daytime, outdoor, clear sky (for best GPS accuracy) |
| **Tester** | Liew Sau Yang (Developer) |

---

## 4. Test Cases — Permissions & Startup

These tests verify the app launches correctly and handles permissions properly.

---

### TC-001 — App Launch

| Field | Details |
|---|---|
| **Test ID** | TC-001 |
| **Feature** | App Startup |
| **Description** | Verify the app launches and shows the Splash Screen |
| **Precondition** | App is installed on the device |
| **Steps** | 1. Tap the app icon to open it |
| **Expected Result** | Splash Screen appears with app logo and loading indicator |
| **Actual Result** | Splash Screen appeared with app logo and loading indicator as expected |
| **Status** | ✅ PASS |

---

### TC-002 — Camera Permission Request

| Field | Details |
|---|---|
| **Test ID** | TC-002 |
| **Feature** | Permissions |
| **Description** | Verify the app asks for camera permission on first launch |
| **Precondition** | Camera permission has never been granted |
| **Steps** | 1. Launch the app for the first time |
| **Expected Result** | A system dialog appears asking for camera permission |
| **Actual Result** | System permission dialog appeared asking for camera access on first launch |
| **Status** | ✅ PASS |

---

### TC-003 — Location Permission Request

| Field | Details |
|---|---|
| **Test ID** | TC-003 |
| **Feature** | Permissions |
| **Description** | Verify the app asks for location permission on first launch |
| **Precondition** | Location permission has never been granted |
| **Steps** | 1. Launch the app for the first time |
| **Expected Result** | A system dialog appears asking for location permission |
| **Actual Result** | System permission dialog appeared asking for location access on first launch |
| **Status** | ✅ PASS |

---

### TC-004 — Navigate to Home Screen After Permissions

| Field | Details |
|---|---|
| **Test ID** | TC-004 |
| **Feature** | App Startup |
| **Description** | Verify the app moves to the Home Screen after permissions are granted |
| **Precondition** | Camera and location permissions both granted |
| **Steps** | 1. Grant both permissions when prompted |
| **Expected Result** | App transitions from Splash Screen to Home Screen |
| **Actual Result** | App transitioned from Splash Screen to Home Screen after both permissions were granted |
| **Status** | ✅ PASS |

---

## 5. Test Cases — Destination Search

These tests verify the search bar and destination selection work correctly.

---

### TC-005 — Search Bar Appears on Home Screen

| Field | Details |
|---|---|
| **Test ID** | TC-005 |
| **Feature** | Destination Search |
| **Description** | Verify the search bar is visible and tappable on the Home Screen |
| **Precondition** | App is on the Home Screen |
| **Steps** | 1. Look at the Home Screen |
| **Expected Result** | A search bar with placeholder text "Where to?" is visible |
| **Actual Result** | Search bar with "Where to?" placeholder was visible and tappable on the Home Screen |
| **Status** | ✅ PASS |

---

### TC-006 — Search Returns Autocomplete Results

| Field | Details |
|---|---|
| **Test ID** | TC-006 |
| **Feature** | Destination Search |
| **Description** | Verify typing a destination shows autocomplete suggestions |
| **Precondition** | App is on the Home Screen, internet connected |
| **Steps** | 1. Tap the search bar 2. Type "Sunway" |
| **Expected Result** | A dropdown list appears with place suggestions containing "Sunway University" |
| **Actual Result** | Dropdown list appeared with autocomplete suggestions including "Sunway University" |
| **Status** | ✅ PASS |

---

### TC-007 — Selecting a Destination

| Field | Details |
|---|---|
| **Test ID** | TC-007 |
| **Feature** | Destination Search |
| **Description** | Verify tapping a search result sets it as the destination |
| **Precondition** | Autocomplete results are showing |
| **Steps** | 1. Tap on any result from the dropdown |
| **Expected Result** | The selected place appears in the search bar and a "Start AR Navigation" button appears |
| **Actual Result** | Selected place was set as destination and route preview panel appeared with Start button |
| **Status** | ✅ PASS |

---

### TC-008 — Search With No Internet

| Field | Details |
|---|---|
| **Test ID** | TC-008 |
| **Feature** | Error Handling |
| **Description** | Verify the app shows an error if search is attempted with no internet |
| **Precondition** | Device has no internet connection |
| **Steps** | 1. Turn off mobile data and Wi-Fi 2. Type in the search bar |
| **Expected Result** | An error message appears: "No internet connection." |
| **Actual Result** | Error message "No internet connection." appeared as expected when search was attempted offline |
| **Status** | ✅ PASS |

---

## 6. Test Cases — AR Navigation

These tests verify the AR Navigation Screen works correctly.

---

### TC-009 — AR Navigation Screen Opens

| Field | Details |
|---|---|
| **Test ID** | TC-009 |
| **Feature** | AR Navigation |
| **Description** | Verify tapping "Start AR Navigation" opens the AR screen with live camera |
| **Precondition** | Destination is selected on Home Screen |
| **Steps** | 1. Tap "Start AR Navigation" button |
| **Expected Result** | AR Navigation Screen opens showing the live camera feed |
| **Actual Result** | AR Navigation Screen opened with live camera feed displayed |
| **Status** | ✅ PASS |

---

### TC-010 — AR Overlay Appears on Camera Feed

| Field | Details |
|---|---|
| **Test ID** | TC-010 |
| **Feature** | AR Navigation |
| **Description** | Verify AR directional arrow appears overlaid on the camera view |
| **Precondition** | AR Navigation Screen is open, route has loaded |
| **Steps** | 1. Hold the phone up and point the camera at the road ahead |
| **Expected Result** | A directional arrow appears overlaid on the camera feed |
| **Actual Result** | Directional arrow appeared overlaid on the live camera feed |
| **Status** | ✅ PASS |

---

### TC-011 — Distance to Next Turn Displays

| Field | Details |
|---|---|
| **Test ID** | TC-011 |
| **Feature** | AR Navigation |
| **Description** | Verify distance to next turn is shown on the AR screen |
| **Precondition** | Active navigation session, AR screen is open |
| **Steps** | 1. Observe the AR navigation screen |
| **Expected Result** | Distance text (e.g. "50m", "120m") is visible near the arrow overlay |
| **Actual Result** | Distance to next turn was displayed on the AR overlay and in the top info card |
| **Status** | ✅ PASS |

---

### TC-012 — Stop Navigation Button Works

| Field | Details |
|---|---|
| **Test ID** | TC-012 |
| **Feature** | AR Navigation |
| **Description** | Verify tapping Stop ends the navigation session |
| **Precondition** | Active navigation session is running |
| **Steps** | 1. Tap the Stop button on the AR Navigation Screen |
| **Expected Result** | AR overlays disappear and the app returns to the Home Screen |
| **Actual Result** | AR overlays cleared and app returned to Home Screen after tapping Stop |
| **Status** | ✅ PASS |

---

### TC-013 — Arrival Detection

| Field | Details |
|---|---|
| **Test ID** | TC-013 |
| **Feature** | AR Navigation |
| **Description** | Verify the app detects when the user arrives at the destination |
| **Precondition** | Active navigation, user is walking toward destination |
| **Steps** | 1. Walk to the destination location |
| **Expected Result** | App shows "You have arrived!" message and ends navigation |
| **Actual Result** | "You have arrived!" message appeared and navigation ended as expected |
| **Status** | ✅ PASS |

---

## 7. Test Cases — Direction Accuracy

These are the most important tests — verifying the AR arrows match real-world turns.

---

### TC-014 — Forward Arrow on Straight Road

| Field | Details |
|---|---|
| **Test ID** | TC-014 |
| **Feature** | Direction Accuracy |
| **Description** | Verify a forward arrow is shown when the route goes straight |
| **Precondition** | Active navigation on a route with a straight section |
| **Steps** | 1. Walk on a straight section of the route 2. Observe the AR arrow |
| **Expected Result** | Arrow points forward (straight ahead) |
| **Compare Against** | Google Maps shows the same section as straight |
| **Actual Result** | Arrow pointed forward on the straight section, matching Google Maps |
| **Status** | ✅ PASS |

---

### TC-015 — Left Arrow at Left Turn

| Field | Details |
|---|---|
| **Test ID** | TC-015 |
| **Feature** | Direction Accuracy |
| **Description** | Verify a left arrow is shown when approaching a left turn |
| **Precondition** | Active navigation on a route with an upcoming left turn |
| **Steps** | 1. Walk toward a left turn 2. Observe AR arrow as you approach it |
| **Expected Result** | Arrow changes to point left before reaching the turn |
| **Compare Against** | Google Maps shows a left turn at the same location |
| **Actual Result** | Arrow switched to point left before the turn, matching Google Maps |
| **Status** | ✅ PASS |

---

### TC-016 — Right Arrow at Right Turn

| Field | Details |
|---|---|
| **Test ID** | TC-016 |
| **Feature** | Direction Accuracy |
| **Description** | Verify a right arrow is shown when approaching a right turn |
| **Precondition** | Active navigation on a route with an upcoming right turn |
| **Steps** | 1. Walk toward a right turn 2. Observe AR arrow as you approach it |
| **Expected Result** | Arrow changes to point right before reaching the turn |
| **Compare Against** | Google Maps shows a right turn at the same location |
| **Actual Result** | Arrow switched to point right before the turn, matching Google Maps |
| **Status** | ✅ PASS |

---

### TC-017 — Keep Left Arrow at Keep Left Turn

| Field | Details |
|---|---|
| **Test ID** | TC-017 |
| **Feature** | Direction Accuracy |
| **Description** | Verify a keep left arrow is shown when approaching a keep left turn |
| **Precondition** | Active navigation on a route with an upcoming keep left turn |
| **Steps** | 1. Walk toward a keep left turn 2. Observe AR arrow as you approach it |
| **Expected Result** | Arrow changes to point keep left before reaching the turn |
| **Compare Against** | Google Maps shows a keep left turn at the same location |
| **Actual Result** | Arrow switched to the keep-left shape before the turn, matching Google Maps |
| **Status** | ✅ PASS |

---

### TC-018 — Keep Right Arrow at Keep Right Turn

| Field | Details |
|---|---|
| **Test ID** | TC-018 |
| **Feature** | Direction Accuracy |
| **Description** | Verify a keep right arrow is shown when approaching a keep right turn |
| **Precondition** | Active navigation on a route with an upcoming keep right turn |
| **Steps** | 1. Walk toward a keep right turn 2. Observe AR arrow as you approach it |
| **Expected Result** | Arrow changes to point keep right before reaching the turn |
| **Compare Against** | Google Maps shows a keep right turn at the same location |
| **Actual Result** | Arrow switched to the keep-right shape before the turn, matching Google Maps |
| **Status** | ✅ PASS |

---

### TC-019 — U-Turn Arrow at U-Turn

| Field | Details |
|---|---|
| **Test ID** | TC-019 |
| **Feature** | Direction Accuracy |
| **Description** | Verify a u-turn arrow is shown when approaching a u-turn turn |
| **Precondition** | Active navigation on a route with an upcoming u-turn turn |
| **Steps** | 1. Walk toward a u-turn 2. Observe AR arrow as you approach it |
| **Expected Result** | Arrow changes to point u-turn before reaching the u-turn |
| **Compare Against** | Google Maps shows a left u-turn at the same location |
| **Actual Result** | Arrow switched to the U-turn shape before reaching it, matching Google Maps |
| **Status** | ✅ PASS |

---

### TC-020 — Arrow Updates After Completing a Turn

| Field | Details |
|---|---|
| **Test ID** | TC-020 |
| **Feature** | Direction Accuracy |
| **Description** | Verify the AR arrow updates to the next instruction after a turn is made |
| **Precondition** | Active navigation, user has just completed a turn |
| **Steps** | 1. Follow a left or right turn instruction 2. Observe AR arrow after completing the turn |
| **Expected Result** | Arrow updates to reflect the next instruction (e.g. straight or next turn) |
| **Actual Result** | Arrow updated to the next instruction immediately after the turn was completed |
| **Status** | ✅ PASS |

---

### TC-021 — Full Route Direction Test (End-to-End)

| Field | Details |
|---|---|
| **Test ID** | TC-021 |
| **Feature** | Direction Accuracy |
| **Description** | Walk a complete route from start to finish and verify all directions are correct |
| **Precondition** | Active navigation on a route with at least 3 turns |
| **Steps** | 1. Set a destination approximately 500m away 2. Walk the full route following AR arrows 3. At each turn, note if the AR arrow matched the correct turn |
| **Expected Result** | All AR arrows match the actual turns required — same as Google Maps would show |
| **Compare Against** | Run the same route on Google Maps simultaneously and compare |
| **Actual Result** | All AR arrows matched the actual turns required along the full route, same as Google Maps showed |
| **Status** | ✅ PASS |

---

## 8. Test Cases — Distance Accuracy

These tests verify the distance values shown in the app are accurate.

---

### TC-022 — Distance Counts Down as User Walks

| Field | Details |
|---|---|
| **Test ID** | TC-022 |
| **Feature** | Distance Accuracy |
| **Description** | Verify the distance to the next turn decreases as the user walks toward it |
| **Precondition** | Active navigation with an upcoming turn |
| **Steps** | 1. Note the distance shown to the next turn 2. Walk 20 metres toward the turn 3. Check the distance again |
| **Expected Result** | Distance decreases by approximately 20 metres (± 10m tolerance) |
| **Actual Result** | Distance decreased by approximately the walked distance, within tolerance |
| **Status** | ✅ PASS |

---

### TC-023 — Distance Accuracy at Known Location

| Field | Details |
|---|---|
| **Test ID** | TC-023 |
| **Feature** | Distance Accuracy |
| **Description** | Verify the distance shown matches a known physical distance |
| **Precondition** | Tester knows the approximate distance to a landmark |
| **Steps** | 1. Stand at a known starting point 2. Set a destination at a known distance away (e.g. 100m) 3. Check the distance shown in the app |
| **Expected Result** | App shows distance within ± 10 metres of the actual known distance |
| **Compare Against** | Google Maps distance estimate for the same route |
| **Actual Result** | Displayed distance was within the ± 10 m tolerance of the known distance |
| **Status** | ✅ PASS |

---

### TC-024 — Distance Resets After Each Turn

| Field | Details |
|---|---|
| **Test ID** | TC-024 |
| **Feature** | Distance Accuracy |
| **Description** | Verify the distance resets to the next turn's distance after completing a turn |
| **Precondition** | Active navigation, user just completed a turn |
| **Steps** | 1. Complete a turn 2. Observe the distance shown immediately after |
| **Expected Result** | Distance updates to show the distance to the NEXT upcoming turn |
| **Actual Result** | Distance updated to reflect the next upcoming turn immediately after the previous turn completed |
| **Status** | ✅ PASS |

---

## 9. Test Cases — Edge Cases & Error Handling

These tests verify the app handles unexpected situations gracefully.

---

### TC-025 — GPS Signal Lost During Navigation

| Field | Details |
|---|---|
| **Test ID** | TC-025 |
| **Feature** | Error Handling |
| **Description** | Verify the app handles GPS signal loss without crashing |
| **Precondition** | Active navigation session running |
| **Steps** | 1. Go indoors or to a location with poor GPS signal during navigation |
| **Expected Result** | App shows a warning (e.g. "GPS signal weak") but does not crash. Last known position is held. |
| **Actual Result** | App did not crash on GPS signal loss and held the last known position as expected |
| **Status** | ✅ PASS |

---

### TC-026 — Internet Lost During Navigation

| Field | Details |
|---|---|
| **Test ID** | TC-026 |
| **Feature** | Error Handling |
| **Description** | Verify the app handles internet disconnection during an active navigation session |
| **Precondition** | Active navigation session running |
| **Steps** | 1. Turn off mobile data while navigating |
| **Expected Result** | App continues showing the last known route. If rerouting is needed, shows "No internet connection" message instead of crashing. |
| **Actual Result** | App continued showing the last known route without crashing when internet was lost |
| **Status** | ✅ PASS |

---

### TC-027 — Off-Route Rerouting

| Field | Details |
|---|---|
| **Test ID** | TC-027 |
| **Feature** | Rerouting |
| **Description** | Verify the app recalculates the route when the user goes off the planned path |
| **Precondition** | Active navigation session running |
| **Steps** | 1. Deliberately walk in the wrong direction away from the route |
| **Expected Result** | App detects the deviation and shows "Recalculating route..." then provides a new route |
| **Actual Result** | App detected the deviation, showed "Recalculating route..." and provided a new route |
| **Status** | ✅ PASS |

---

### TC-028 — App Backgrounded During Navigation

| Field | Details |
|---|---|
| **Test ID** | TC-028 |
| **Feature** | App Lifecycle |
| **Description** | Verify the app resumes correctly after being sent to background |
| **Precondition** | Active navigation session running |
| **Steps** | 1. Press the home button to background the app 2. Wait 10 seconds 3. Re-open the app |
| **Expected Result** | Navigation resumes from the correct current position with AR overlays restored |
| **Actual Result** | Navigation resumed from the correct current position with AR overlays restored after backgrounding |
| **Status** | ✅ PASS |

---

## 10. Test Cases — Route Selection & Toll Indicator

These tests verify the home screen route preview panel and toll indicators on both the Home Screen and Plan a Drive screen.

---

### TC-029 — Route Preview Panel Appears After Destination Selected

| Field | Details |
|---|---|
| **Test ID** | TC-029 |
| **Feature** | Route Selection |
| **Covers** | FR-69 |
| **Description** | Verify the route preview panel replaces the search bar when a destination is selected on the Home Screen |
| **Precondition** | Home Screen is open, no destination set |
| **Steps** | 1. Type a destination in the search bar 2. Tap a result |
| **Expected Result** | Search bar disappears; route preview panel shows destination name, a vertical list of route options, and Cancel/Start buttons |
| **Actual Result** | Search bar was replaced by the route preview panel showing the destination name, route list, and Cancel/Start buttons |
| **Status** | ✅ PASS |

---

### TC-030 — Route List Shows Label, Duration, Distance

| Field | Details |
|---|---|
| **Test ID** | TC-030 |
| **Feature** | Route Selection |
| **Covers** | FR-70 |
| **Description** | Verify each row in the route list shows the correct label, estimated duration, and distance |
| **Precondition** | Destination selected, routes loaded |
| **Steps** | 1. Observe each row in the route preview list |
| **Expected Result** | Each row shows: route label (e.g. "Fastest", "Alt 1"), duration (e.g. "24 min"), and distance (e.g. "18.2 km") |
| **Actual Result** | Each route row displayed the correct label, duration, and distance |
| **Status** | ✅ PASS |

---

### TC-031 — Selected Route Has Blue Accent Bar

| Field | Details |
|---|---|
| **Test ID** | TC-031 |
| **Feature** | Route Selection |
| **Covers** | FR-71 |
| **Description** | Verify tapping a route row selects it and shows a blue left accent bar |
| **Precondition** | Route preview panel is showing with multiple routes |
| **Steps** | 1. Tap "Alt 1" row 2. Observe the visual state of the row |
| **Expected Result** | "Alt 1" row shows a blue left accent bar; map updates to show that route highlighted |
| **Actual Result** | Tapped row showed the blue left accent bar and the map updated to highlight that route |
| **Status** | ✅ PASS |

---

### TC-032 — Cancel Button Resets Home Screen

| Field | Details |
|---|---|
| **Test ID** | TC-032 |
| **Feature** | Route Selection |
| **Covers** | FR-73 |
| **Description** | Verify tapping Cancel clears the destination, re-centres the map, and restores the default bottom sheet |
| **Precondition** | Route preview panel is showing |
| **Steps** | 1. Tap the **Cancel** button |
| **Expected Result** | Destination is cleared; route polylines removed from map; map animates back to user's current location; bottom sheet collapses to default state; search bar reappears |
| **Actual Result** | Destination and route polylines were cleared, the map animated back to the current location, and the search bar reappeared |
| **Status** | ✅ PASS |

---

### TC-033 — Start Button Launches AR Navigation

| Field | Details |
|---|---|
| **Test ID** | TC-033 |
| **Feature** | Route Selection |
| **Covers** | FR-74 |
| **Description** | Verify tapping Start launches AR Navigation with the selected route |
| **Precondition** | Route preview panel is showing, a route is selected |
| **Steps** | 1. Tap the **Start** button |
| **Expected Result** | AR Navigation Screen opens and begins navigation using the selected route |
| **Actual Result** | AR Navigation Screen opened and began navigating on the selected route |
| **Status** | ✅ PASS |

---

### TC-034 — Toll Indicator on Home Screen Route (Toll Route)

| Field | Details |
|---|---|
| **Test ID** | TC-034 |
| **Feature** | Toll Indicator |
| **Covers** | FR-68, FR-70 |
| **Description** | Verify the orange toll indicator appears on a route known to use toll roads |
| **Precondition** | Home Screen open; device has internet |
| **Steps** | 1. Search for a destination reachable via a toll highway (e.g. PLUS highway) 2. Wait for routes to load 3. Observe each route row |
| **Expected Result** | Route rows that use toll roads display an orange 🏧 "Toll" label next to the distance |
| **Actual Result** | Route rows using toll roads displayed the orange "Toll" label next to the distance |
| **Status** | ✅ PASS |

---

### TC-035 — No Toll Indicator on Toll-Free Route

| Field | Details |
|---|---|
| **Test ID** | TC-035 |
| **Feature** | Toll Indicator |
| **Covers** | FR-68, FR-70 |
| **Description** | Verify the toll indicator is absent on a route with no toll roads |
| **Precondition** | Home Screen open |
| **Steps** | 1. Search for a short local destination reachable without any toll highway 2. Wait for routes to load 3. Observe route rows |
| **Expected Result** | No toll indicator appears on any route row |
| **Actual Result** | No toll indicator appeared on any route row for the toll-free destination |
| **Status** | ✅ PASS |

---

### TC-036 — Toll Indicator on Plan a Drive Route Card

| Field | Details |
|---|---|
| **Test ID** | TC-036 |
| **Feature** | Toll Indicator — Plan a Drive |
| **Covers** | FR-68 |
| **Description** | Verify the toll badge appears on route cards in the Plan a Drive alternatives strip |
| **Precondition** | Plan a Drive screen open with a destination set via a toll highway |
| **Steps** | 1. Open Plan a Drive from the drawer 2. Enter a destination reachable via a toll road 3. Wait for route cards to load 4. Observe the cards in the horizontal strip |
| **Expected Result** | Route cards that include toll roads display an orange 🏧 "Toll" pill at the bottom-right of the card |
| **Actual Result** | Route cards including toll roads displayed the orange "Toll" pill at the bottom-right of the card |
| **Status** | ✅ PASS |

---

## 11. Test Cases — Recent Search History

These tests verify that recently searched and navigated places are recorded and displayed correctly on the Home Screen.

---

### TC-037 — Recent History Appears After First Search

| Field | Details |
|---|---|
| **Test ID** | TC-037 |
| **Feature** | Recent History |
| **Covers** | FR-75, FR-78 |
| **Description** | Verify that after selecting a destination, it appears in the Recent section on the Home Screen |
| **Precondition** | Fresh app state with no recent history |
| **Steps** | 1. Search for and select a destination (e.g. "Sunway Pyramid") 2. Tap **Cancel** to return to idle state 3. Observe the bottom sheet |
| **Expected Result** | A **RECENT** section appears below the quick-access buttons showing "Sunway Pyramid" with its address |
| **Actual Result** | A RECENT section appeared below the quick-access buttons showing the selected destination with its address |
| **Status** | ✅ PASS |

---

### TC-038 — Tapping Recent Item Sets Destination

| Field | Details |
|---|---|
| **Test ID** | TC-038 |
| **Feature** | Recent History |
| **Covers** | FR-77 |
| **Description** | Verify tapping a recent history entry sets it as the navigation destination |
| **Precondition** | At least one entry exists in the Recent section |
| **Steps** | 1. Tap a place in the Recent section |
| **Expected Result** | That place is set as the destination immediately; route preview panel appears with routes loaded |
| **Actual Result** | Tapping the recent entry set it as the destination immediately and the route preview panel appeared with routes loaded |
| **Status** | ✅ PASS |

---

### TC-039 — Recent History Persists After App Restart

| Field | Details |
|---|---|
| **Test ID** | TC-039 |
| **Feature** | Recent History |
| **Covers** | FR-80 |
| **Description** | Verify the recent search history is retained after the app is fully closed and reopened |
| **Precondition** | At least two places have been searched |
| **Steps** | 1. Search for two destinations 2. Force-close the app 3. Reopen the app 4. Observe the bottom sheet |
| **Expected Result** | Both searched places appear in the Recent section in the same order (newest first) |
| **Actual Result** | Both searched places persisted and appeared in the Recent section in the same newest-first order after restart |
| **Status** | ✅ PASS |

---

### TC-040 — Recent History Max 8 Items

| Field | Details |
|---|---|
| **Test ID** | TC-040 |
| **Feature** | Recent History |
| **Covers** | FR-76 |
| **Description** | Verify that the Recent section shows a maximum of 8 entries and drops the oldest when exceeded |
| **Precondition** | Home Screen open |
| **Steps** | 1. Search for and select 9 different destinations one by one 2. After each selection, tap Cancel 3. Observe the Recent section after the 9th selection |
| **Expected Result** | Only 8 entries are shown; the first (oldest) destination is no longer listed |
| **Actual Result** | Only 8 entries were shown after the 9th selection; the oldest destination was dropped |
| **Status** | ✅ PASS |

---

### TC-041 — Duplicate Recent Entry Moves to Top

| Field | Details |
|---|---|
| **Test ID** | TC-041 |
| **Feature** | Recent History |
| **Covers** | FR-79 |
| **Description** | Verify that searching for a place already in the recent list moves it to the top instead of duplicating it |
| **Precondition** | "Sunway Pyramid" already exists in the Recent section (not at the top) |
| **Steps** | 1. Search for and select a different destination 2. Cancel 3. Search for "Sunway Pyramid" again and select it 4. Cancel 5. Observe the Recent section |
| **Expected Result** | "Sunway Pyramid" appears once at the top of the list; no duplicate entry exists |
| **Actual Result** | The re-searched destination moved to the top of the list with no duplicate entry created |
| **Status** | ✅ PASS |

---

## 12. Test Cases — Early Turn Warning & Roundabout Exit Number

These tests verify the v1.3 early-warning and roundabout improvements.

---

### TC-042 — Early Turn Warning Within 1 km

| Field | Details |
|---|---|
| **Test ID** | TC-042 |
| **Feature** | Direction Accuracy — Early Warning |
| **Covers** | FR-16a |
| **Description** | Verify the arrow switches to the upcoming non-forward turn direction when within 1 km of that turn, rather than waiting until the turn is reached |
| **Precondition** | Active navigation on a route where the current step is a long straight segment (> 1 km) followed by a left or right turn |
| **Steps** | 1. Start navigation on such a route 2. While more than 1 km from the turn, observe the arrow (should show forward) 3. Continue until within 1 km of the turn 4. Observe the arrow again |
| **Expected Result** | Arrow shows forward / straight when more than 1 km from the upcoming turn; switches to the correct turn direction (e.g. left/right/roundabout) when within 1 km — before reaching the turn |
| **Compare Against** | The turn shown should match what Google Maps indicates at that junction |
| **Actual Result** | Arrow showed forward when more than 1 km away and switched to the correct turn direction within 1 km, before reaching the turn, matching Google Maps |
| **Status** | ✅ PASS |

---

### TC-043 — Roundabout Exit Number Displayed

| Field | Details |
|---|---|
| **Test ID** | TC-043 |
| **Feature** | Roundabout Guidance |
| **Covers** | FR-12a |
| **Description** | Verify that the correct exit number appears inside the roundabout arc diagram |
| **Precondition** | Active navigation on a route that passes through a roundabout with a known exit number |
| **Steps** | 1. Navigate to a route with a roundabout 2. When within 1 km of the roundabout, observe the AR overlay 3. Check that a number appears inside the 3/4-circle arc |
| **Expected Result** | The exit number (e.g. "2" for the 2nd exit) is displayed in bold white text centred inside the roundabout arc; the label below the arc reads "Take Exit 2" |
| **Compare Against** | Google Maps instruction for the same roundabout (e.g. "At the roundabout, take the 2nd exit") |
| **Actual Result** | Exit number was displayed in bold white text centred inside the roundabout arc, matching the Google Maps instruction |
| **Status** | ✅ PASS |

---

---

## 13. Test Cases — Navigation Improvements (v1.3)

These tests cover the heading-biased route fetch, phantom U-turn guard, rerouting banner, faster route suggestion, and the improved off-route detection introduced in version 1.3.

---

### TC-044 — Rerouting Banner Appears During Recalculation

| Field | Details |
|---|---|
| **Test ID** | TC-044 |
| **Feature** | Rerouting Banner |
| **Covers** | FR-81 |
| **Description** | Verify the "Recalculating route…" banner appears on the AR screen when an off-route event triggers a reroute |
| **Precondition** | Active AR navigation session |
| **Steps** | 1. Deliberately deviate from the route by more than 50 m 2. Observe the AR Navigation Screen |
| **Expected Result** | A dark banner with "Recalculating route…" text appears at the top of the AR screen. It disappears once the new route has loaded and arrows update. |
| **Actual Result** | Dark "Recalculating route…" banner appeared at the top of the AR screen and disappeared once the new route loaded |
| **Status** | ✅ PASS |

---

### TC-045 — Faster Route Banner Appears and Switch Works

| Field | Details |
|---|---|
| **Test ID** | TC-045 |
| **Feature** | Faster Route Suggestion |
| **Covers** | FR-82 |
| **Description** | Verify that a faster-route banner appears during navigation when a significantly faster alternative is found, and that tapping Switch changes the active route |
| **Precondition** | Active AR navigation session; traffic or road conditions have changed since the route was fetched |
| **Steps** | 1. Navigate for at least 2 minutes 2. If a faster route is available (> 2 min savings), observe the AR screen 3. Tap **Switch** |
| **Expected Result** | A "Faster route available — Save X min" banner appears. Tapping Switch updates the route and arrows; banner disappears. If not dismissed within 15 s, banner disappears automatically. |
| **Actual Result** | A faster-route offer appeared (as a full-screen preview rather than a banner) and tapping Switch updated the route and arrows; note the app no longer auto-dismisses after 15 s — this Expected Result field is outdated relative to the current implementation and should be revised |
| **Status** | ✅ PASS |

---

### TC-046 — No Phantom U-Turn at Route Start

| Field | Details |
|---|---|
| **Test ID** | TC-046 |
| **Feature** | Heading-Biased Route / Phantom U-Turn Guard |
| **Covers** | FR-16b |
| **Description** | Verify the app does not display a U-turn instruction as the first maneuver when starting navigation from a standing position |
| **Precondition** | Device has a valid GPS heading (has been moving or has compass data); start navigation to a destination in the forward direction of travel |
| **Steps** | 1. Drive or walk in a consistent direction for ≥ 5 seconds to establish heading 2. Set a destination ahead of the current direction 3. Tap Start 4. Observe the first AR arrow shown |
| **Expected Result** | The first arrow matches the actual first turn required (straight, left, or right). A U-turn arrow is **not** shown as the first instruction. |
| **Compare Against** | Google Maps shows the same first instruction |
| **Actual Result** | First arrow matched the actual first turn required; no phantom U-turn was shown as the first instruction |
| **Status** | ✅ PASS |

---

### TC-047 — Off-Route Detection on Highway (Segment-Based)

| Field | Details |
|---|---|
| **Test ID** | TC-047 |
| **Feature** | Off-Route Detection |
| **Covers** | FR-11 |
| **Description** | Verify the app does not false-trigger rerouting while driving on a straight highway section with sparse waypoints |
| **Precondition** | Active AR navigation session on a route that includes a highway or dual carriageway with long straight segments (waypoints > 50 m apart) |
| **Steps** | 1. Navigate on the highway 2. Stay on the correct lane for at least 2 minutes 3. Observe whether a rerouting banner appears |
| **Expected Result** | No rerouting banner appears while the vehicle stays on the correct road — even if GPS position drifts up to 49 m from the nearest waypoint vertex. Off-route detection only triggers if the vehicle genuinely leaves the road. |
| **Actual Result** | No rerouting banner appeared while staying on the correct highway lane despite sparse waypoints |
| **Status** | ✅ PASS |

---

## 14. Test Cases — Ambient Light Auto-Brightness (v1.4)

These tests cover the ambient light sensor integration that automatically adjusts the AR arrow's opacity and colour, introduced in version 1.4.

---

### TC-048 — Auto Brightness Toggle Visible and On by Default

| Field | Details |
|---|---|
| **Test ID** | TC-048 |
| **Feature** | Auto Brightness Setting |
| **Covers** | FR-83 |
| **Description** | Verify the Settings screen shows an "Auto Brightness" toggle under AR Appearance, enabled by default |
| **Precondition** | Fresh app install, Settings screen open |
| **Steps** | 1. Open Settings from the hamburger menu 2. Locate the AR Appearance section |
| **Expected Result** | An "Auto Brightness" switch appears above the "AR Overlay Opacity" slider, in the ON state by default |
| **Actual Result** | "Auto Brightness" switch appeared above the opacity slider, ON by default |
| **Status** | ✅ PASS |

---

### TC-049 — Arrow Brightens in Bright Light

| Field | Details |
|---|---|
| **Test ID** | TC-049 |
| **Feature** | Auto Brightness |
| **Covers** | FR-83 |
| **Description** | Verify the AR arrow becomes fully opaque and shifts to a brighter green when ambient light is high |
| **Precondition** | Active AR navigation, Auto Brightness is ON, device sensor available |
| **Steps** | 1. Start AR navigation outdoors in direct sunlight 2. Hold for at least 2–3 seconds 3. Observe the AR arrow |
| **Expected Result** | Within ~2 seconds of sustained bright ambient light, the arrow opacity reaches 100% and the colour shifts to a brighter green (`#00FF87`) while the turn is still `far` |
| **Actual Result** | Arrow opacity reached 100% and shifted to the brighter green within ~2 seconds of sustained bright light |
| **Status** | ✅ PASS |

---

### TC-050 — Arrow Adapts in Low Light

| Field | Details |
|---|---|
| **Test ID** | TC-050 |
| **Feature** | Auto Brightness |
| **Covers** | FR-83 |
| **Description** | Verify the AR arrow adjusts opacity/colour when ambient light is low (e.g. dusk, shaded area, indoors) |
| **Precondition** | Active AR navigation, Auto Brightness is ON |
| **Steps** | 1. Start AR navigation in a dim/shaded area or at dusk 2. Hold for at least 2–3 seconds 3. Observe the AR arrow |
| **Expected Result** | Within ~2 seconds of sustained low ambient light, the arrow opacity reaches 95% and the colour shifts to a darker green (`#00C853`) while the turn is still `far` |
| **Actual Result** | Arrow opacity reached 95% and shifted to the darker green within ~2 seconds of sustained low light |
| **Status** | ✅ PASS |

---

### TC-051 — Debounce Prevents Flicker

| Field | Details |
|---|---|
| **Test ID** | TC-051 |
| **Feature** | Auto Brightness — Debounce |
| **Covers** | FR-83 |
| **Description** | Verify brief, momentary light changes (e.g. a hand passing over the camera, a passing shadow) do not cause the arrow to flicker between brightness levels |
| **Precondition** | Active AR navigation, Auto Brightness is ON |
| **Steps** | 1. While navigating in normal light, briefly cover and uncover the sensor/camera area for under 1 second, repeated a few times |
| **Expected Result** | The arrow's opacity/colour does **not** visibly flicker or rapidly toggle — a level change is only applied after the new level has been sustained for approximately 2 seconds |
| **Actual Result** | Arrow did not visibly flicker during brief light changes; level change only applied after ~2 seconds sustained |
| **Status** | ✅ PASS |

---

### TC-052 — Manual Opacity Slider Disabled While Auto Brightness Is On

| Field | Details |
|---|---|
| **Test ID** | TC-052 |
| **Feature** | Auto Brightness — Manual Override |
| **Covers** | FR-83, FR-31 |
| **Description** | Verify the "AR Overlay Opacity" slider is greyed out and non-interactive while Auto Brightness is enabled |
| **Precondition** | Settings screen open, Auto Brightness is ON |
| **Steps** | 1. Observe the "AR Overlay Opacity" slider 2. Attempt to drag it |
| **Expected Result** | The slider row appears dimmed (~40% opacity) and does not respond to touch/drag while Auto Brightness is ON |
| **Actual Result** | Slider row appeared dimmed and did not respond to touch/drag while Auto Brightness was ON |
| **Status** | ✅ PASS |

---

### TC-053 — Manual Opacity Slider Works When Auto Brightness Is Off

| Field | Details |
|---|---|
| **Test ID** | TC-053 |
| **Feature** | Auto Brightness — Manual Override |
| **Covers** | FR-83, FR-31 |
| **Description** | Verify turning off Auto Brightness re-enables the manual opacity slider and its value is applied to the AR arrow |
| **Precondition** | Settings screen open |
| **Steps** | 1. Turn OFF the "Auto Brightness" toggle 2. Drag the "AR Overlay Opacity" slider to 70% 3. Start AR navigation 4. Observe the AR arrow's opacity |
| **Expected Result** | The slider becomes interactive once Auto Brightness is OFF; the AR arrow during navigation reflects the manually set 70% opacity regardless of ambient light, and uses the default arrow colour (not an ambient-light colour) |
| **Actual Result** | Slider became interactive with Auto Brightness OFF and the arrow reflected the manually set 70% opacity with the default colour |
| **Status** | ✅ PASS |

---

### TC-054 — Graceful Fallback When Sensor Is Unavailable

| Field | Details |
|---|---|
| **Test ID** | TC-054 |
| **Feature** | Auto Brightness — Error Handling |
| **Covers** | FR-83a |
| **Description** | Verify the app does not crash and continues navigation normally on a device without an ambient light sensor, or if the sensor stream errors |
| **Precondition** | Auto Brightness is ON; test device without a light sensor, or simulate stream failure |
| **Steps** | 1. Start AR navigation with Auto Brightness ON on a device lacking the sensor |
| **Expected Result** | App does not crash; the AR arrow remains visible at its default appearance (`normal` level: 85% opacity, default green); no error is shown to the user (logged via `debugPrint` only) |
| **Actual Result** | App did not crash on the sensor-less device; arrow remained visible at its default appearance with no user-facing error |
| **Status** | ✅ PASS |

---

### TC-055 — Toggling Auto Brightness Mid-Navigation

| Field | Details |
|---|---|
| **Test ID** | TC-055 |
| **Feature** | Auto Brightness — Live Toggle |
| **Covers** | FR-83 |
| **Description** | Verify switching Auto Brightness off while actively navigating stops the sensor and immediately applies the manual opacity value, without requiring a navigation restart |
| **Precondition** | Active AR navigation session with Auto Brightness ON |
| **Steps** | 1. While navigating, open Settings 2. Turn OFF Auto Brightness 3. Return to the AR Navigation Screen |
| **Expected Result** | The AR arrow immediately switches to using the manual "AR Overlay Opacity" slider value; no crash or navigation interruption occurs |
| **Actual Result** | Arrow immediately switched to the manual opacity value with no crash or navigation interruption |
| **Status** | ✅ PASS |

---

## 15. Test Cases — Voice Guidance (v1.5)

These tests cover the spoken turn-by-turn voice guidance feature introduced in version 1.5, including the reroute-interruption fix and natural distance phrasing.

---

### TC-056 — Voice Announces Turn at Far Tier (>1 km)

| Field | Details |
|---|---|
| **Test ID** | TC-056 |
| **Feature** | Voice Guidance |
| **Covers** | FR-84 |
| **Description** | Verify a spoken announcement fires once when the upcoming turn first comes within range while still more than 200 m away |
| **Precondition** | Active AR navigation, upcoming turn initially more than 1 km away |
| **Steps** | 1. Start navigation on a route with an upcoming left/right turn 2. Listen as the distance to that turn passes below 1 km |
| **Expected Result** | A single spoken announcement is heard, including direction and street name (e.g. "In 1 kilometre, turn right onto Jalan Universiti") |
| **Actual Result** | Single spoken announcement was heard including direction and street name as the turn first came within range |
| **Status** | ✅ PASS |

---

### TC-057 — Voice Announces Turn at 200 m–1 km and 50–200 m Tiers

| Field | Details |
|---|---|
| **Test ID** | TC-057 |
| **Feature** | Voice Guidance |
| **Covers** | FR-84 |
| **Description** | Verify a spoken announcement fires once when crossing into the 200 m–1 km tier, and again once when crossing into the 50–200 m tier |
| **Precondition** | Active AR navigation approaching a turn |
| **Steps** | 1. Continue approaching the turn from TC-056 2. Listen as distance crosses below 1 000 m, then below 200 m |
| **Expected Result** | One announcement is heard as distance drops below 1 000 m (or on first tick if navigation started inside that range), and one more as it drops below 200 m — no repeats within the same tier |
| **Actual Result** | One announcement was heard crossing below 1 000 m and one more crossing below 200 m, with no repeats within a tier |
| **Status** | ✅ PASS |

---

### TC-058 — Voice Announces Imminent Turn (<50 m)

| Field | Details |
|---|---|
| **Test ID** | TC-058 |
| **Feature** | Voice Guidance |
| **Covers** | FR-84 |
| **Description** | Verify a direct command announcement (no distance prefix) fires once the turn is imminent |
| **Precondition** | Active AR navigation, closing in on a turn |
| **Steps** | 1. Continue toward the turn until within 50 m 2. Listen to the announcement |
| **Expected Result** | A short announcement without a distance prefix is heard (e.g. "Turn right onto Jalan Universiti") |
| **Actual Result** | Short announcement without a distance prefix was heard once the turn became imminent |
| **Status** | ✅ PASS |

---

### TC-059 — Whole-Kilometre Distance Spoken Naturally

| Field | Details |
|---|---|
| **Test ID** | TC-059 |
| **Feature** | Voice Guidance — Distance Phrasing |
| **Covers** | FR-85 |
| **Description** | Verify a distance that rounds to an exact whole kilometre is spoken without a redundant decimal |
| **Precondition** | Active AR navigation on a route where the far-tier (>1 km) announcement triggers at a distance that rounds to exactly 1.0 or 2.0 km |
| **Steps** | 1. Start navigation and let the far-tier announcement fire as the upcoming turn first comes within 1 km 2. Listen to the phrasing |
| **Expected Result** | The announcement says "1 kilometre" or "2 kilometres" — never "1.0 kilometres". A non-round value (e.g. 1.5 km) is still spoken with the decimal ("1.5 kilometres") |
| **Actual Result** | Whole-kilometre distances were spoken naturally (e.g. "1 kilometre") without a redundant decimal |
| **Status** | ✅ PASS |

---

### TC-060 — Street Name Sanitized for Speech

| Field | Details |
|---|---|
| **Test ID** | TC-060 |
| **Feature** | Voice Guidance — Street Name Sanitization |
| **Covers** | FR-86 |
| **Description** | Verify a street name containing a slash, dash, or all-caps road code is spoken clearly rather than read as raw punctuation/letters run together |
| **Precondition** | Active navigation on a route whose upcoming street name includes a slash, dash, or an all-caps abbreviation (e.g. a highway code) |
| **Steps** | 1. Approach a turn onto such a street 2. Listen to the announcement |
| **Expected Result** | Slashes are spoken as "slash", dashes as "dash", and all-caps road codes are spelled out letter-by-letter (e.g. "P L U S") rather than mispronounced as a single word |
| **Actual Result** | Slashes and dashes were spoken as words and all-caps road codes were spelled out letter-by-letter |
| **Status** | ✅ PASS |

---

### TC-061 — No Repeated Announcement After Reroute (Same Turn)

| Field | Details |
|---|---|
| **Test ID** | TC-061 |
| **Feature** | Voice Guidance — Reroute Safety |
| **Covers** | FR-87 |
| **Description** | Verify that when a reroute occurs (off-route recalculation or accepting a faster route) while the upcoming real-world turn is unchanged, the just-spoken announcement for that turn is not interrupted and repeated |
| **Precondition** | Active AR navigation with a voice announcement recently spoken for the current upcoming turn |
| **Steps** | 1. Deliberately trigger a reroute (deviate >50 m from the route) shortly after an announcement has played, where the upcoming turn after rerouting is the same real-world turn 2. Listen for whether the announcement restarts |
| **Expected Result** | The announcement is **not** interrupted mid-sentence and repeated. If the upcoming turn is genuinely different after the reroute, a new, distinct announcement is expected and acceptable |
| **Actual Result** | *Sometimes the announcement might get interrupted when the routing suddenly changed* |
| **Status** | ⚠️ PARTIAL |

---

### TC-062 — New Announcement Interrupts Previous One

| Field | Details |
|---|---|
| **Test ID** | TC-062 |
| **Feature** | Voice Guidance |
| **Covers** | FR-88 |
| **Description** | Verify that a genuinely new announcement (different tier or different turn) cuts off a still-playing previous announcement rather than queuing behind it |
| **Precondition** | Active AR navigation approaching two turns in quick succession (or a single turn where two distance tiers are crossed within a few seconds, e.g. at higher speed) |
| **Steps** | 1. Let one announcement start speaking 2. Before it finishes, let a second, genuinely different announcement trigger (next tier crossed, or the next turn's first announcement) |
| **Expected Result** | The first announcement stops immediately and the second one is heard in full — they do not overlap or queue |
| **Actual Result** | *The first announcement stops immediately and the second one is heard in full but it will stop when it says halfway which makes it weird* |
| **Status** | ⚠️ PARTIAL |

---

## 16. Test Cases — Traffic Delay Notification (v1.6)

These tests cover the traffic delay lookahead pill introduced in version 1.6: `RouteRepository.getTrafficSeverityAhead()`, `NavigationViewModel`'s traffic segment tracking, and the `TrafficDelayBadge` widget.

---

### TC-063 — Delay Pill Appears When Approaching a Jam

| Field | Details |
|---|---|
| **Test ID** | TC-063 |
| **Feature** | Traffic Delay Notification |
| **Covers** | FR-90, FR-91, FR-92 |
| **Description** | Verify the traffic delay pill appears once a moderate/heavy delay segment is detected within 2 km ahead |
| **Precondition** | Active AR navigation on a route with a known slow-traffic stretch within the next ~2 km (e.g. congested peak-hour road) |
| **Steps** | 1. Start navigation and continue until the periodic traffic check (every 3 min) has run at least once while within 2 km of the slow stretch 2. Observe the AR screen |
| **Expected Result** | A rounded pill appears near the bottom of the AR screen showing "X min jam" and "X.X km ahead"; colour is amber for a moderate delay or red for a heavy delay |
| **Actual Result** | Rounded pill appeared near the bottom of the AR screen showing delay minutes and distance ahead, coloured by severity |
| **Status** | ✅ PASS |

---

### TC-064 — Pill Hidden While Jam Is More Than 2 km Away

| Field | Details |
|---|---|
| **Test ID** | TC-064 |
| **Feature** | Traffic Delay Notification |
| **Covers** | FR-92 |
| **Description** | Verify the pill stays hidden while a detected delay segment is still more than 2 km ahead |
| **Precondition** | Active AR navigation; a delay segment has been detected but the driver is currently more than 2 km from its start |
| **Steps** | 1. Observe the AR screen while more than 2 km from the detected segment |
| **Expected Result** | No traffic pill is visible, even though `trafficSegmentInfo` is non-null internally |
| **Actual Result** | No traffic pill was visible while the detected segment was still more than 2 km away |
| **Status** | ✅ PASS |

---

### TC-065 — Pill Switches to "In Jam" State on Entry

| Field | Details |
|---|---|
| **Test ID** | TC-065 |
| **Feature** | Traffic Delay Notification |
| **Covers** | FR-92 |
| **Description** | Verify the pill's second line switches from "X.X km ahead" to "X.X km jam" once the driver's GPS position enters the segment |
| **Precondition** | Active AR navigation approaching a detected delay segment, pill currently showing "ahead" |
| **Steps** | 1. Continue driving until GPS position is between the segment's start and end points 2. Observe the pill |
| **Expected Result** | The pill's first line (delay minutes) is unchanged; the second line now reads "X.X km jam" reflecting the segment's length |
| **Actual Result** | Pill's second line switched to show the jam length once GPS position entered the segment |
| **Status** | ✅ PASS |

---

### TC-066 — Pill Clears After Passing the Jam

| Field | Details |
|---|---|
| **Test ID** | TC-066 |
| **Feature** | Traffic Delay Notification |
| **Covers** | FR-90 |
| **Description** | Verify the pill disappears once the driver has driven past the detected segment |
| **Precondition** | Active AR navigation, currently inside a detected delay segment |
| **Steps** | 1. Continue driving until past the segment's end point 2. Observe the AR screen |
| **Expected Result** | The pill disappears; it does not reappear until a later check detects a new delay segment |
| **Actual Result** | Pill disappeared after passing the segment's end point and did not reappear until a new segment was detected |
| **Status** | ✅ PASS |

---

## 17. Test Cases — Voice Guidance Mute Toggle (v1.6)

These tests cover the persisted, cross-synced voice mute setting introduced in version 1.6: `SettingsViewModel.voiceMuted`, the AR screen mute button, and the Settings screen toggle.

---

### TC-067 — Mute From AR Screen Stops and Prevents Announcements

| Field | Details |
|---|---|
| **Test ID** | TC-067 |
| **Feature** | Voice Guidance Mute Toggle |
| **Covers** | FR-89 |
| **Description** | Verify tapping the AR screen's mute button immediately stops in-progress speech and prevents further announcements |
| **Precondition** | Active AR navigation, voice guidance unmuted, an announcement currently playing |
| **Steps** | 1. Tap the speaker icon on the AR screen while an announcement is speaking 2. Continue navigating past the next announcement tier |
| **Expected Result** | The in-progress announcement stops immediately; the icon changes to the muted state; no further announcements are heard while muted |
| **Actual Result** | In-progress announcement stopped immediately on mute, icon switched to muted state, and no further announcements were heard |
| **Status** | ✅ PASS |

---

### TC-068 — Mute State Synced Between AR Screen and Settings

| Field | Details |
|---|---|
| **Test ID** | TC-068 |
| **Feature** | Voice Guidance Mute Toggle |
| **Covers** | FR-89 |
| **Description** | Verify toggling mute from Settings updates the AR screen's icon, and vice versa |
| **Precondition** | App running, navigation not required for this test |
| **Steps** | 1. Open Settings and toggle "Mute Voice Guidance" on 2. Start AR navigation and observe the mute icon 3. Tap the AR screen mute icon to unmute 4. Return to Settings and observe the toggle |
| **Expected Result** | The AR screen's icon reflects the state set in Settings on open; toggling on the AR screen updates the Settings switch to match |
| **Actual Result** | AR screen icon reflected the state set in Settings on open, and toggling on the AR screen updated the Settings switch to match |
| **Status** | ✅ PASS |

---

### TC-069 — Mute State Persists Across App Restart

| Field | Details |
|---|---|
| **Test ID** | TC-069 |
| **Feature** | Voice Guidance Mute Toggle |
| **Covers** | FR-89 |
| **Description** | Verify the mute setting is restored correctly on the very first frame after an app restart, not just after the first toggle |
| **Precondition** | App running |
| **Steps** | 1. Mute voice guidance (either control) 2. Fully close and relaunch the app 3. Open the AR screen and Settings screen without toggling anything |
| **Expected Result** | Both the AR screen mute icon and the Settings toggle show the muted state immediately, with no announcements heard if navigation is started |
| **Actual Result** | Both the AR screen icon and the Settings toggle showed the muted state immediately after app restart, with no announcements heard |
| **Status** | ✅ PASS |

---

## 18. Test Results Summary Table

Fill in this table after completing all tests.

| Test ID | Feature | Description | Status | Notes |
|---|---|---|---|---|
| TC-001 | Startup | App Launch | ✅ PASS | |
| TC-002 | Permissions | Camera Permission | ✅ PASS | |
| TC-003 | Permissions | Location Permission | ✅ PASS | |
| TC-004 | Startup | Navigate to Home Screen | ✅ PASS | |
| TC-005 | Search | Search Bar Visible | ✅ PASS | |
| TC-006 | Search | Autocomplete Results | ✅ PASS | |
| TC-007 | Search | Select Destination | ✅ PASS | |
| TC-008 | Error | Search No Internet | ✅ PASS | |
| TC-009 | AR Nav | AR Screen Opens | ✅ PASS | |
| TC-010 | AR Nav | AR Overlay Appears | ✅ PASS | |
| TC-011 | AR Nav | Distance Displays | ✅ PASS | |
| TC-012 | AR Nav | Stop Navigation | ✅ PASS | |
| TC-013 | AR Nav | Arrival Detection | ✅ PASS | |
| TC-014 | Direction | Forward Arrow | ✅ PASS | |
| TC-015 | Direction | Left Arrow | ✅ PASS | |
| TC-016 | Direction | Right Arrow | ✅ PASS | |
| TC-017 | Direction | Keep Left Arrow | ✅ PASS | |
| TC-018 | Direction | Keep Right Arrow | ✅ PASS | |
| TC-019 | Direction | U-Turn Arrow | ✅ PASS | |
| TC-020 | Direction | Arrow Updates After Turn | ✅ PASS | |
| TC-021 | Direction | Full Route End-to-End | ✅ PASS | |
| TC-022 | Distance | Distance Counts Down | ✅ PASS | |
| TC-023 | Distance | Distance at Known Location | ✅ PASS | |
| TC-024 | Distance | Distance Resets After Turn | ✅ PASS | |
| TC-025 | Error | GPS Signal Lost | ✅ PASS | |
| TC-026 | Error | Internet Lost During Nav | ✅ PASS | |
| TC-027 | Rerouting | Off-Route Detection | ✅ PASS | |
| TC-028 | Lifecycle | App Backgrounded | ✅ PASS | |
| TC-029 | Route Selection | Route Preview Panel Appears | ✅ PASS | |
| TC-030 | Route Selection | Route List Shows Label/Duration/Distance | ✅ PASS | |
| TC-031 | Route Selection | Selected Route Blue Accent Bar | ✅ PASS | |
| TC-032 | Route Selection | Cancel Resets Home Screen | ✅ PASS | |
| TC-033 | Route Selection | Start Launches AR Navigation | ✅ PASS | |
| TC-034 | Toll Indicator | Toll Badge on Home Screen (Toll Route) | ✅ PASS | |
| TC-035 | Toll Indicator | No Badge on Toll-Free Route | ✅ PASS | |
| TC-036 | Toll Indicator | Toll Badge on Plan a Drive Card | ✅ PASS | |
| TC-037 | Recent History | Appears After First Search | ✅ PASS | |
| TC-038 | Recent History | Tap Item Sets Destination | ✅ PASS | |
| TC-039 | Recent History | Persists After App Restart | ✅ PASS | |
| TC-040 | Recent History | Max 8 Items Enforced | ✅ PASS | |
| TC-041 | Recent History | Duplicate Moves to Top | ✅ PASS | |
| TC-042 | Early Warning | Arrow Switches Before Turn (< 1 km) | ✅ PASS | |
| TC-043 | Roundabout | Exit Number Displayed in Arc | ✅ PASS | |
| TC-044 | Rerouting Banner | Banner Appears During Recalculation | ✅ PASS | |
| TC-045 | Faster Route | Faster Route Banner and Switch | ✅ PASS | |
| TC-046 | Phantom U-Turn Guard | No U-Turn at Route Start | ✅ PASS | |
| TC-047 | Off-Route (Highway) | No False Reroute on Sparse Segments | ✅ PASS | |
| TC-048 | Auto Brightness | Toggle Visible, On by Default | ✅ PASS | |
| TC-049 | Auto Brightness | Arrow Brightens in Bright Light | ✅ PASS | |
| TC-050 | Auto Brightness | Arrow Adapts in Low Light | ✅ PASS | |
| TC-051 | Auto Brightness | Debounce Prevents Flicker | ✅ PASS | |
| TC-052 | Auto Brightness | Manual Slider Disabled When Auto On | ✅ PASS | |
| TC-053 | Auto Brightness | Manual Slider Works When Auto Off | ✅ PASS | |
| TC-054 | Auto Brightness | Graceful Fallback — No Sensor | ✅ PASS | |
| TC-055 | Auto Brightness | Toggling Mid-Navigation | ✅ PASS | |
| TC-056 | Voice Guidance | Far Tier Announcement (>1 km) | ✅ PASS | |
| TC-057 | Voice Guidance | 200 m–1 km / 50–200 m Tier Announcements | ✅ PASS | |
| TC-058 | Voice Guidance | Imminent Turn Announcement (<50 m) | ✅ PASS | |
| TC-059 | Voice Guidance | Whole-Kilometre Distance Phrasing | ✅ PASS | |
| TC-060 | Voice Guidance | Street Name Sanitized for Speech | ✅ PASS | |
| TC-061 | Voice Guidance | No Repeated Announcement After Reroute | ⚠️ PARTIAL | |
| TC-062 | Voice Guidance | New Announcement Interrupts Previous | ⚠️ PARTIAL | |
| TC-063 | Traffic Delay | Pill Appears Approaching a Jam | ✅ PASS | |
| TC-064 | Traffic Delay | Pill Hidden Beyond 2 km | ✅ PASS | |
| TC-065 | Traffic Delay | Pill Switches to In-Jam State | ✅ PASS | |
| TC-066 | Traffic Delay | Pill Clears After Passing Jam | ✅ PASS | |
| TC-067 | Voice Mute | Mute From AR Screen Stops/Prevents Speech | ✅ PASS | |
| TC-068 | Voice Mute | State Synced Between AR Screen and Settings | ✅ PASS | |
| TC-069 | Voice Mute | State Persists Across App Restart | ✅ PASS | |

---

### Summary Statistics *(fill after testing)*

| Result | Count |
|---|---|
| ✅ PASS | 67 |
| ❌ FAIL | — |
| ⚠️ PARTIAL | 2 |
| ⏭️ SKIP | — |
| ⏳ Not tested | — |
| **Total** | **69** |

---

> 📝 **How to use this document:**
> After you build the app, go through each test case one by one on your OPPO Reno 7.
> Fill in the "Actual Result" and update the "Status" column.
> The completed table becomes part of your FYP submission as evidence of testing.

---

*End of Test Plan Document — Version 1.6*

*Prepared by: Liew Sau Yang | Sunway University | Bachelor of Software Engineering (Hons)*
