import Foundation
import CoreLocation
import Combine

/// Manager responsible for CoreLocation authorization, current location updates,
/// and CLCircularRegion geofence boundary monitoring.
final class LocationManager: NSObject, ObservableObject {
    static let shared = LocationManager()

    private let locationManager = CLLocationManager()

    // MARK: - Published Properties
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var currentLocation: CLLocation?
    @Published var monitoredRegions: [CLRegion] = []
    @Published var lastRegionEventDescription: String = "No region events yet"
    @Published var isMonitoringActive: Bool = false
    @Published var errorMessage: String?

    // Closure callbacks for geofence transitions
    var onRegionExit: ((CLRegion, CLLocation?) -> Void)?
    var onRegionEnter: ((CLRegion, CLLocation?) -> Void)?

    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10.0 // meters
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Permissions Flow
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }

    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }

    // MARK: - Location Tracking
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }

    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }

    // MARK: - Geofencing Operations
    /// Starts monitoring a circular geofence with specified center coordinate and radius.
    func startMonitoringGeofence(id: String, center: CLLocationCoordinate2D, radiusMeters: Double) {
        guard CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self) else {
            errorMessage = "Geofence monitoring is not supported on this device."
            return
        }

        // Clamp radius to system maximum
        let clampedRadius = min(radiusMeters, locationManager.maximumRegionMonitoringDistance)
        let region = CLCircularRegion(center: center, radius: clampedRadius, identifier: id)
        region.notifyOnExit = true
        region.notifyOnEntry = true

        locationManager.startMonitoring(for: region)
        isMonitoringActive = true
        refreshMonitoredRegions()
    }

    /// Stops monitoring a specific geofence by ID.
    func stopMonitoringGeofence(id: String) {
        for region in locationManager.monitoredRegions where region.identifier == id {
            locationManager.stopMonitoring(for: region)
        }
        refreshMonitoredRegions()
    }

    /// Stops monitoring all active regions.
    func stopAllMonitoring() {
        for region in locationManager.monitoredRegions {
            locationManager.stopMonitoring(for: region)
        }
        isMonitoringActive = false
        refreshMonitoredRegions()
    }

    private func refreshMonitoredRegions() {
        monitoredRegions = Array(locationManager.monitoredRegions)
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationManager: CLLocationManagerDelegate {
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        DispatchQueue.main.async {
            self.authorizationStatus = manager.authorizationStatus
            if manager.authorizationStatus == .authorizedWhenInUse || manager.authorizationStatus == .authorizedAlways {
                self.locationManager.startUpdatingLocation()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        DispatchQueue.main.async {
            self.currentLocation = location
        }
    }

    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.lastRegionEventDescription = "Exited region \(region.identifier) at \(timestamp)"
            self.onRegionExit?(region, self.currentLocation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        DispatchQueue.main.async {
            let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
            self.lastRegionEventDescription = "Entered region \(region.identifier) at \(timestamp)"
            self.onRegionEnter?(region, self.currentLocation)
        }
    }

    func locationManager(_ manager: CLLocationManager, didDetermineState state: CLRegionState, for region: CLRegion) {
        DispatchQueue.main.async {
            switch state {
            case .inside:
                self.lastRegionEventDescription = "Inside region \(region.identifier)"
            case .outside:
                self.lastRegionEventDescription = "Outside region \(region.identifier)"
            case .unknown:
                self.lastRegionEventDescription = "State unknown for \(region.identifier)"
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Monitoring failed for \(region?.identifier ?? "unknown"): \(error.localizedDescription)"
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.errorMessage = "Location error: \(error.localizedDescription)"
        }
    }
}
