# CircleAlert — iOS Location Tracking & Geofencing App

CircleAlert is an iOS application designed for group location monitoring, geofenced perimeter protection, and real-time exit alerts. It combines **Kotlin Multiplatform (KMP 2.1.0)** for shared domain logic with native **SwiftUI (iOS 17+)**, **CoreLocation**, **MapKit**, and **Firebase**.

---

## Key Features

- **Tracking Groups & Invite Codes**: Create private groups with unambiguous, human-readable 6-character Base-32 invite codes (e.g. `J4JH5Z`).
- **Interactive Safe Zones**: Configure circular perimeters (50m–10,000m) directly on an interactive MapKit view.
- **Hardware-Assisted Geofencing**: Uses CoreLocation `CLCircularRegion` for kernel-level boundary monitoring with minimal battery consumption (< 1% per day).
- **Targeted Group Alerts**: When a member exits, notifications are dispatched **strictly to other group members** (the exiting member is not notified).
- **In-App Simulator**: Built-in boundary exit simulator to test the full event pipeline directly on the iOS Simulator without physical movement or GPX spoofing.
- **Dual-Mode Backend**: Runs out of the box in local persistent evaluation mode (no cloud setup needed) and seamlessly connects to Cloud Firestore when configured.

---

## Tech Stack

| Layer | Technology | Role |
|---|---|---|
| **UI** | SwiftUI (iOS 17+) | Native maps, status pills, sheets, and reactive MVVM views |
| **Shared Core** | Kotlin Multiplatform (KMP 2.1.0) | Models, validation, invite code logic, and Haversine distance math |
| **Location** | CoreLocation | `CLLocationManager`, `CLCircularRegion`, background authorization |
| **Mapping** | MapKit | Interactive map preview, radius overlays (`MapCircle`), markers |
| **Backend** | Firebase Auth & Firestore | User sessions, group rosters, and real-time event logs |
| **Cloud** | Firebase Cloud Functions + APNs | Automated multicast push notifications on boundary exit |

---

## Quick Start (Run on iOS Simulator)

### 1. Open in Xcode
```bash
open iosApp/CircleAlert.xcodeproj
```

### 2. Run the App
1. Select any iOS Simulator (e.g., **iPhone 16 Pro**).
2. Press **`Cmd + R`** (or click the **Play** button in Xcode).

### 3. Test in 4 Simple Steps
1. **Sign In**: Tap **Sign In** (defaults to Alex Rivera demo account).
2. **View Group**: Tap **My Team** on the dashboard.
3. **Set Perimeter**: Tap **Configure Perimeter Map**, choose a radius (e.g. 500m), and tap **Save Safe Zone**.
4. **Trigger Simulation**: Tap **Trigger Exit** next to any member to see instant exit status updates and local alert banners.

---

## Project Structure

```
CircleAlert/
├── shared/               # Kotlin Multiplatform Module (Models, UseCases, Math)
│   └── src/
│       ├── commonMain/   # Shared domain logic, repositories, and utilities
│       └── commonTest/   # KMP Unit tests running on iOS target
├── iosApp/               # Native iOS SwiftUI Application
│   ├── CircleAlert.xcodeproj
│   └── CircleAlert/
│       ├── App/          # App entry point & TabView
│       ├── App Views/    # SwiftUI screens (Home, Groups, Geofence, Alerts)
│       ├── View Models/  # MVVM ViewModels
│       ├── App Models/   # Swift domain data models
│       └── Location and Services/ # LocationManager, Simulator & FirebaseService
├── firebase/             # Backend (firestore.rules, cloud functions)
```

---

## Building from Terminal (Optional)

```bash
# Build KMP Framework for iOS Simulator
./gradlew :shared:linkDebugFrameworkIosSimulatorArm64

# Build Native iOS App
xcodebuild -project iosApp/CircleAlert.xcodeproj \
  -scheme CircleAlert \
  -destination 'generic/platform=iOS Simulator' \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES \
  -derivedDataPath /tmp/DerivedData build CODE_SIGNING_ALLOWED=NO
```

---

## License & Credits

Built as a high-performance cross-platform location safety project using Kotlin Multiplatform and Apple Native frameworks.
