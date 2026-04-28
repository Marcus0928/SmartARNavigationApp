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
| **Version** | 1.0 |
| **Last Updated** | October 2025 |

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
10. [Test Results Summary Table](#10-test-results-summary-table)

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
| Turn arrow trigger point | ± 15 metres from actual turn |
| AR overlay alignment | Visually aligned — no precise pixel measurement |

---

## 3. Test Environment

| Item | Details |
|---|---|
| **Test Device** | OPPO Reno 7 5G (CPH2371) |
| **Operating System** | Android 11 / 12 |
| **ARCore Version** | Pre-installed (Google Play Services for AR) |
| **Internet Connection** | Mobile data (4G/LTE) |
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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

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
| **Actual Result** | *(fill during testing)* |
| **Status** | ⏳ Not tested |

---

## 10. Test Results Summary Table

Fill in this table after completing all tests.

| Test ID | Feature | Description | Status | Notes |
|---|---|---|---|---|
| TC-001 | Startup | App Launch | ⏳ | |
| TC-002 | Permissions | Camera Permission | ⏳ | |
| TC-003 | Permissions | Location Permission | ⏳ | |
| TC-004 | Startup | Navigate to Home Screen | ⏳ | |
| TC-005 | Search | Search Bar Visible | ⏳ | |
| TC-006 | Search | Autocomplete Results | ⏳ | |
| TC-007 | Search | Select Destination | ⏳ | |
| TC-008 | Error | Search No Internet | ⏳ | |
| TC-009 | AR Nav | AR Screen Opens | ⏳ | |
| TC-010 | AR Nav | AR Overlay Appears | ⏳ | |
| TC-011 | AR Nav | Distance Displays | ⏳ | |
| TC-012 | AR Nav | Stop Navigation | ⏳ | |
| TC-013 | AR Nav | Arrival Detection | ⏳ | |
| TC-014 | Direction | Forward Arrow | ⏳ | |
| TC-015 | Direction | Left Arrow | ⏳ | |
| TC-016 | Direction | Right Arrow | ⏳ | |
| TC-017 | Direction | Keep Left Arrow | ⏳ | |
| TC-018 | Direction | Keep Right Arrow | ⏳ | |
| TC-019 | Direction | U-Turn Arrow | ⏳ | |
| TC-020 | Direction | Arrow Updates After Turn | ⏳ | |
| TC-021 | Direction | Full Route End-to-End | ⏳ | |
| TC-022 | Distance | Distance Counts Down | ⏳ | |
| TC-023 | Distance | Distance at Known Location | ⏳ | |
| TC-024 | Distance | Distance Resets After Turn | ⏳ | |
| TC-025 | Error | GPS Signal Lost | ⏳ | |
| TC-026 | Error | Internet Lost During Nav | ⏳ | |
| TC-027 | Rerouting | Off-Route Detection | ⏳ | |
| TC-028 | Lifecycle | App Backgrounded | ⏳ | |

---

### Summary Statistics *(fill after testing)*

| Result | Count |
|---|---|
| ✅ PASS | — |
| ❌ FAIL | — |
| ⚠️ PARTIAL | — |
| ⏭️ SKIP | — |
| **Total** | **28** |

---

> 📝 **How to use this document:**
> After you build the app, go through each test case one by one on your OPPO Reno 7.
> Fill in the "Actual Result" and update the "Status" column.
> The completed table becomes part of your FYP submission as evidence of testing.

---

*End of Test Plan Document — Version 1.0*

*Prepared by: Liew Sau Yang | Sunway University | Bachelor of Software Engineering (Hons)*
