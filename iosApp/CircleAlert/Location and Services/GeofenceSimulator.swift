import Foundation
import CoreLocation

/// Debug simulator to test geofence entry and exit events in the iOS Simulator
/// without requiring a physical device or external GPX files.
/// Feeds into the identical backend processing pipeline as real CoreLocation events.
final class GeofenceSimulator: ObservableObject {
    static let shared = GeofenceSimulator()

    @Published var isSimulationRunning: Bool = false
    @Published var lastSimulatedEventTime: Date?
    @Published var simulatedStatus: String = "Idle"

    /// Simulates a member exiting a specified geofence boundary.
    /// - Parameters:
    ///   - centerLat: Center latitude of the geofence
    ///   - centerLon: Center longitude of the geofence
    ///   - radiusMeters: Geofence radius in meters
    ///   - offsetMeters: Distance outside the boundary to place the simulated exit
    /// - Returns: Simulated exit coordinate
    func generateSimulatedExitCoordinate(
        centerLat: Double,
        centerLon: Double,
        radiusMeters: Double,
        offsetMeters: Double = 150.0
    ) -> CLLocationCoordinate2D {
        let totalDistance = radiusMeters + offsetMeters
        // Offset due North: 1 degree latitude ~ 111,000 meters
        let deltaLat = totalDistance / 111000.0
        return CLLocationCoordinate2D(
            latitude: centerLat + deltaLat,
            longitude: centerLon
        )
    }

    /// Simulates a member being inside a specified geofence.
    func generateSimulatedInsideCoordinate(
        centerLat: Double,
        centerLon: Double
    ) -> CLLocationCoordinate2D {
        // Offset slightly (~15m North) inside center
        let deltaLat = 15.0 / 111000.0
        return CLLocationCoordinate2D(
            latitude: centerLat + deltaLat,
            longitude: centerLon
        )
    }
}
