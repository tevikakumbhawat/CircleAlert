import SwiftUI
import CoreLocation

@main
struct CircleAlertApp: App {
    @StateObject private var firebaseService = FirebaseService.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var notificationService = NotificationService.shared

    init() {
        setupLocationAndNotificationHandlers()
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if firebaseService.currentUser != nil {
                    MainTabView()
                } else {
                    LoginView()
                }
            }
            .onAppear {
                notificationService.requestAuthorization()
                locationManager.requestWhenInUseAuthorization()
            }
        }
    }

    private func setupLocationAndNotificationHandlers() {
        let lm = LocationManager.shared
        let fb = FirebaseService.shared

        // Real CoreLocation exit delegate handler
        lm.onRegionExit = { region, location in
            guard let user = fb.currentUser else { return }

            // Region identifier format: "geo_<groupId>"
            let regionId = region.identifier
            let groupId = regionId.replacingOccurrences(of: "geo_", with: "")

            let exitCoord = location?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)

            Task {
                do {
                    _ = try await fb.recordExitEvent(
                        groupId: groupId,
                        userId: user.id,
                        exitLatitude: exitCoord.latitude,
                        exitLongitude: exitCoord.longitude,
                        isSimulated: false
                    )
                } catch {
                    print("Failed to record CoreLocation exit event: \(error)")
                }
            }
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
    @ObservedObject private var firebaseService = FirebaseService.shared

    var body: some View {
        TabView {
            HomeDashboardView()
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }

            ActivityAlertsView()
                .tabItem {
                    Label("Alerts", systemImage: "bell.badge.fill")
                }

            SettingsProfileView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
        .tint(.blue)
    }
}

// MARK: - Settings / Profile View
struct SettingsProfileView: View {
    @ObservedObject private var firebaseService = FirebaseService.shared
    @ObservedObject private var locationManager = LocationManager.shared
    @ObservedObject private var notificationService = NotificationService.shared

    var body: some View {
        NavigationStack {
            List {
                Section(header: Text("User Profile")) {
                    HStack(spacing: 12) {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 44, height: 44)
                            .overlay(
                                Text(String(firebaseService.currentUser?.displayName.prefix(1) ?? "U"))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(firebaseService.currentUser?.displayName ?? "User")
                                .font(.headline)
                            Text(firebaseService.currentUser?.email ?? "")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 4)
                }

                Section(header: Text("CoreLocation Status")) {
                    HStack {
                        Text("Authorization")
                        Spacer()
                        Text(authorizationText)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Monitored Regions")
                        Spacer()
                        Text("\(locationManager.monitoredRegions.count) active")
                            .foregroundColor(.secondary)
                    }

                    if locationManager.authorizationStatus == .authorizedWhenInUse {
                        Button(action: { locationManager.requestAlwaysAuthorization() }) {
                            Text("Upgrade to Always Authorization")
                                .font(.subheadline)
                                .foregroundColor(.blue)
                        }
                    }
                }

                Section(header: Text("Backend Configuration")) {
                    HStack {
                        Text("Backend Service")
                        Spacer()
                        Text(firebaseService.isFirebaseConfigured ? "Firebase Cloud" : "Local Mock Storage")
                            .foregroundColor(firebaseService.isFirebaseConfigured ? .green : .orange)
                    }

                    HStack {
                        Text("Push Notifications")
                        Spacer()
                        Text(notificationService.isPermissionGranted ? "Granted" : "Not Determined")
                            .foregroundColor(notificationService.isPermissionGranted ? .green : .secondary)
                    }
                }

                Section {
                    Button(role: .destructive, action: { firebaseService.signOut() }) {
                        HStack {
                            Spacer()
                            Text("Sign Out")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Settings & Info")
        }
    }

    private var authorizationText: String {
        switch locationManager.authorizationStatus {
        case .notDetermined: return "Not Determined"
        case .restricted: return "Restricted"
        case .denied: return "Denied"
        case .authorizedAlways: return "Always Authorized"
        case .authorizedWhenInUse: return "When In Use"
        @unknown default: return "Unknown"
        }
    }
}
