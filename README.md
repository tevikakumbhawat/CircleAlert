# CircleAlert — iOS Location Tracking & Geofencing App

CircleAlert is a production-quality iOS MVP designed for group location monitoring, geofence perimeter protection, and real-time exit alerts. It is built using **Kotlin Multiplatform (KMP)** for shared business logic, data models, and use cases, coupled with native **SwiftUI**, **CoreLocation**, **MapKit**, and **Firebase**.

---

## 1. Project Overview

CircleAlert addresses group safety and perimeter monitoring scenarios (e.g. field operations, family tracking, student campus safety, logistics field teams):
1. **Tracking Groups**: Users can create private tracking groups with unique, unambiguous 6-character invite codes, or join existing groups.
2. **Interactive Geofencing**: Groups associate a circular geofenced safe zone (custom center coordinate and radius between 50m and 10,000m) configured on a native MapKit interface.
3. **Automated Exit Detection**: Real-time monitoring with CoreLocation (`CLCircularRegion`, `startMonitoring(for:)`, `didExitRegion`) detects whenever any member exits the safe zone.
4. **Targeted Group Alerts**: When a member exits, the backend records the event and dispatches notifications **strictly to all other group members** (the exiting member does not receive their own alert).
5. **Simulator Testing Mode**: Includes an in-app DEBUG simulation engine allowing full end-to-end exit event testing on the iOS Simulator without requiring physical device mobility or GPX file spoofing.

---

## 2. Technology Stack

| Layer | Technology | Purpose |
|---|---|---|
| **UI Layer** | Native SwiftUI (iOS 17+) | Premium iOS interface, responsive navigation, cards, sheets, status pills |
| **Shared Business Logic** | Kotlin Multiplatform (KMP 2.1.0) | Cross-platform models, use cases, validation, invite code logic, distance math |
| **Native Integration** | Swift 6 / Objective-C Bridge | Native framework consumption of `SharedCircleAlert.framework` |
| **Location & Geofencing** | CoreLocation | `CLLocationManager`, `CLCircularRegion`, background authorization, exit callbacks |
| **Maps & Visualization** | MapKit (`Map`, `MapCircle`, `Marker`) | Interactive map selector, draggable pins, live radius overlays |
| **Authentication** | Firebase Authentication | Email/password sign-in, account creation, session management |
| **Database** | Cloud Firestore | Real-time group documents, member rosters, geofence configs, exit event logs |
| **Push Notifications** | Firebase Cloud Messaging + APNs | Multicast alerts triggered by Firebase Cloud Functions |
| **Build Tools** | Gradle 8.11.1 & Xcode 16/27 | KMP compilation (`iosSimulatorArm64`, `iosArm64`), Xcode project integration |

---

## 3. Architecture

CircleAlert adopts a clean separation of concerns:

```
CircleAlert/
│
├── shared/                                 # Kotlin Multiplatform Module
│   ├── build.gradle.kts                   # Targets: iosArm64, iosSimulatorArm64
│   └── src/
│       ├── commonMain/kotlin/
│       │   ├── models/                    # User, GroupMember, TrackingGroup, GeofenceConfig, ExitEvent
│       │   ├── repository/                # AuthRepository, GroupRepository, MemberRepository, GeofenceRepository
│       │   ├── usecase/                   # CreateGroup, JoinGroup, ConfigureGeofence, ProcessGeofenceExit
│       │   └── utils/                     # InviteCodeGenerator, LocationUtils (Haversine distance)
│       └── commonTest/kotlin/             # KMP Unit Tests running on iOS Simulator
│           ├── InviteCodeGeneratorTest.kt
│           ├── GeofenceValidationTest.kt
│           └── UseCasesTest.kt
│
├── iosApp/                                 # Native iOS SwiftUI Application
│   ├── CircleAlert.xcodeproj              # Configured Xcode Project
│   ├── CircleAlert/
│   │   ├── App/
│   │   │   └── CircleAlertApp.swift       # App lifecycle, CoreLocation background wiring, TabView
│   │   ├── Models/
│   │   │   └── AppModels.swift            # Swift domain models & Codable representations
│   │   ├── ViewModels/                    # MVVM ViewModels
│   │   │   ├── AuthViewModel.swift
│   │   │   ├── HomeViewModel.swift
│   │   │   ├── CreateGroupViewModel.swift
│   │   │   ├── JoinGroupViewModel.swift
│   │   │   ├── GroupDetailViewModel.swift
│   │   │   ├── GeofenceSetupViewModel.swift
│   │   │   └── ActivityAlertsViewModel.swift
│   │   ├── Views/
│   │   │   ├── Authentication/            # LoginView, SignUpView
│   │   │   ├── Home/                      # HomeDashboardView, StatCard, GroupRowCard
│   │   │   ├── Groups/                    # CreateGroupView, JoinGroupView, GroupDetailView
│   │   │   ├── Geofence/                  # GeofenceSetupView (MapKit interactive editor)
│   │   │   ├── Activity/                  # ActivityAlertsView (Exit alert history)
│   │   │   └── Components/                # StatusPillView, PrimaryButton, CustomTextField, EmptyStateCard
│   │   ├── Location/
│   │   │   ├── LocationManager.swift      # CLLocationManagerDelegate, CLCircularRegion monitoring
│   │   │   └── GeofenceSimulator.swift    # DEBUG simulator for boundary entry/exit simulation
│   │   ├── Services/
│   │   │   ├── FirebaseService.swift      # Real-time Firestore sync & local evaluation engine
│   │   │   ├── NotificationService.swift  # UNUserNotificationCenter delegate, banners & APNs
│   │   │   └── SharedKMPBridge.swift      # Bridge to SharedCircleAlert KMP logic
│   │   └── Resources/
│   │       ├── Info.plist                 # Location & Background Modes permissions
│   │       ├── GoogleService-Info.plist   # Firebase configuration placeholder
│   │       └── Assets.xcassets            # App icon, accent color
│   └── CircleAlertTests/
│       └── CircleAlertTests.swift         # Native Swift Unit Tests
│
├── firebase/                               # Backend Infrastructure
│   ├── firestore.rules                    # Granular Firestore security rules
│   ├── firestore.indexes.json             # Compound indexes for exit logs
│   ├── firebase.json                      # Deployment spec
│   └── functions/
│       ├── index.js                       # onGeofenceExitEventCreated notification trigger
│       └── package.json                   # Cloud Functions dependencies
│
├── build.gradle.kts                        # Root Gradle configuration
├── settings.gradle.kts                     # Root project settings
└── gradle.properties                      # Kotlin Native compiler flags
```

---

## 4. Kotlin Multiplatform Responsibilities

The `shared` Kotlin module is compiled to native Apple binary frameworks (`SharedCircleAlert.framework`) for `iosSimulatorArm64` and `iosArm64`. It encapsulates:
- **InviteCodeGenerator**: Generates non-confusing base-32 6-character invitation tokens (omits `0`, `O`, `1`, `I`), and normalizes user input.
- **LocationUtils**: Mathematical implementation of the Haversine formula to compute great-circle distance between coordinates and calculate exact meters a user has moved outside a circular boundary.
- **Use Cases**:
  - `CreateGroupUseCase`: Validates group name length, generates invite code, records creator as `OWNER`.
  - `JoinGroupUseCase`: Validates invite code format, prevents duplicate membership, increments group counter.
  - `ConfigureGeofenceUseCase`: Enforces geographic coordinate bounds and minimum/maximum radius constraints (50m - 10km).
  - `ProcessGeofenceExitUseCase`: Evaluates exit telemetry, produces an immutable exit event log, updates the member status to `OUTSIDE`, and returns the exact subset of group members to notify (excluding the exiting member).

---

## 5. CoreLocation Geofence Monitoring & Background Behavior

### Authorization Workflow
1. The app requests **When In Use** location permissions via `locationManager.requestWhenInUseAuthorization()` on initial launch.
2. For background perimeter tracking, users can upgrade to **Always** authorization via `locationManager.requestAlwaysAuthorization()`.
3. Required `Info.plist` usage descriptions are configured:
   - `NSLocationWhenInUseUsageDescription`
   - `NSLocationAlwaysAndWhenInUseUsageDescription`
   - `NSLocationAlwaysUsageDescription`
   - `UIBackgroundModes`: `location`, `remote-notification`, `fetch`

### Monitoring Mechanism
When a group associates a geofence:
```swift
let region = CLCircularRegion(center: center, radius: radius, identifier: "geo_\(groupId)")
region.notifyOnExit = true
region.notifyOnEntry = true
locationManager.startMonitoring(for: region)
```
Upon perimeter boundary breach, iOS invokes:
```swift
func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion)
```
The callback identifies the group, calculates distance outside the safe zone, writes an exit record to Firestore, and notifies other members.

---

## 6. How to Run on iOS Simulator & Test Geofence Exit Simulation

The application includes a built-in **DEBUG Simulation Engine** so reviewers and developers can evaluate the entire geofencing pipeline in the iOS Simulator without needing a physical device or GPX files:

### Step 1: Launch the App
1. Open the project in Xcode:
   ```bash
   open iosApp/CircleAlert.xcodeproj
   ```
2. Select any iOS Simulator (e.g. iPhone 16 Pro) and press **Cmd + R** (Run).

### Step 2: Explore the Home Dashboard
- On first launch, the app starts in technical evaluation mode with a seeded group: **SF Team Field Operations**.
- You can create a new group (press **Create Group**) or join with an invite code.

### Step 3: Set Up a Geofence
- Tap on any tracking group in the list to open **Group Details**.
- Tap **Set Up** or **Edit** in the *Geofenced Safe Zone* card.
- A full-screen interactive MapKit view opens:
  - Tap anywhere on the map to set the center point.
  - Drag the radius slider (or tap quick presets: 100m, 250m, 500m, 1000m) to adjust the safe perimeter.
  - Tap **Save & Activate Geofence**.

### Step 4: Trigger the Geofence Exit Simulation
- In the **Group Details** screen under *Group Members*, locate any member (e.g. *Elena Rostova* or *Marcus Chen*).
- Tap the **Trigger Exit** button.
- The simulator:
  1. Computes a location coordinate outside the geofence perimeter using `GeofenceSimulator`.
  2. Passes the event through the identical `FirebaseService.recordExitEvent` pipeline.
  3. Updates the member's status pill to **Outside Zone!** (red).
  4. Appends a new entry to the *Recent Exit Events* section.
  5. Fires a local notification banner: `[SIMULATION] Geofence Alert: <Name> has exited <Perimeter>!`.
  6. Logs the event to the global **Activity & Alerts** tab with a distinct `SIMULATED` badge.

---

## 7. Firebase Backend Setup Instructions

CircleAlert includes a dual-mode backend architecture:
- **Offline / Evaluation Mode**: Enabled by default out of the box so the app runs immediately without external credentials.
- **Live Firebase Cloud Mode**: Automatically activates once a valid `GoogleService-Info.plist` is dropped into `iosApp/CircleAlert/Resources/`.

### Steps to Connect Live Firebase:
1. Go to the [Firebase Console](https://console.firebase.google.com/) and create a project named `CircleAlert`.
2. Add an iOS App with Bundle ID: `com.circlealert.ios`.
3. Download `GoogleService-Info.plist` and replace `iosApp/CircleAlert/Resources/GoogleService-Info.plist`.
4. Enable **Firebase Authentication** (Email/Password provider).
5. Enable **Cloud Firestore** and deploy rules:
   ```bash
   cd firebase
   firebase deploy --only firestore:rules,firestore:indexes
   ```
6. Deploy the Cloud Function for push notifications:
   ```bash
   cd firebase/functions
   npm install
   firebase deploy --only functions
   ```

---

## 8. Building the Project from Terminal

### Compile Shared Kotlin Multiplatform Framework
```bash
export JAVA_HOME="/opt/homebrew/opt/openjdk@21/libexec/openjdk.jdk/Contents/Home"
export DEVELOPER_DIR="/Applications/Xcode.app/Contents/Developer"

# Run KMP tests on iOS Simulator target
./gradlew :shared:iosSimulatorArm64Test

# Build KMP Framework for iOS Simulator
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64

# Build KMP Framework for iOS Device
./gradlew :shared:linkDebugFrameworkIosArm64
```

### Build iOS Application with Xcode
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project iosApp/CircleAlert.xcodeproj \
  -scheme CircleAlert \
  -destination 'generic/platform=iOS Simulator' \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  -derivedDataPath /tmp/DerivedData \
  build \
  CODE_SIGNING_ALLOWED=NO
```

### Build iOS Test Suite
```bash
DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer xcodebuild \
  -project iosApp/CircleAlert.xcodeproj \
  -scheme CircleAlert \
  -destination 'generic/platform=iOS Simulator' \
  ARCHS=arm64 \
  ONLY_ACTIVE_ARCH=YES \
  -derivedDataPath /tmp/DerivedData \
  build-for-testing \
  CODE_SIGNING_ALLOWED=NO
```

---

## 9. Known Simulator Limitations & Real Device Configuration

1. **Simulator CoreLocation Region Monitoring**:
   - The iOS Simulator does not natively emit `didExitRegion` / `didEnterRegion` events from synthetic GPS movements without an explicit simulated GPX route or the app's built-in simulation trigger.
   - The built-in **Simulation Engine** bypasses this simulator limitation by running the exact same event processing logic and payload structure as real device triggers.
2. **Push Notifications on Simulator**:
   - APNs remote push notifications require a physical device running iOS 16+ with an Apple Developer provisioning profile, or local simulator APNs simulation via `xcrun simctl push`.
   - Local alert banners (`UNUserNotificationCenter`) are displayed immediately in both simulator and device modes.
3. **Physical Device Deployment**:
   - In Xcode, select the `CircleAlert` target -> **Signing & Capabilities**.
   - Select your Apple Developer Team to generate personal provisioning profiles.
   - Ensure `Location updates` and `Remote notifications` background modes remain checked.

---

## 10. Checklist of Remaining Manual Configuration Steps

- [x] Shared Kotlin Multiplatform module configured and compiled (`SharedCircleAlert.framework`).
- [x] KMP unit tests created and verified passing on iOS target.
- [x] Native SwiftUI screens built (Auth, Home, Create Group, Join Group, Group Details, MapKit Geofence Setup, Activity Alerts, Settings).
- [x] CoreLocation `CLLocationManager` and `CLCircularRegion` monitoring implemented.
- [x] In-app DEBUG simulation engine implemented for simulator testing.
- [x] Firestore security rules and Cloud Functions notification pipeline authored.
- [x] Native Swift unit test suite implemented and compiled.
- [x] Xcode project generated and verified (`** BUILD SUCCEEDED **` and `** TEST BUILD SUCCEEDED **`).
- [ ] *(Optional for production)* Replace placeholder `GoogleService-Info.plist` with active production Firebase project credentials.
- [ ] *(Optional for physical device)* Select personal development signing team in Xcode for real device deployment.
