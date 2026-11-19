import Foundation
import CoreLocation
import Combine
import MapKit

final class GeofenceSetupViewModel: ObservableObject {
    let groupId: String
    @Published var name: String = "Designated Perimeter"
    @Published var selectedCoordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194)
    @Published var radiusMeters: Double = 250.0
    @Published var isLoading: Bool = false
    @Published var isSaved: Bool = false
    @Published var errorMessage: String?

    private let firebaseService = FirebaseService.shared

    init(groupId: String, existingGeofence: GeofenceConfigModel? = nil) {
        self.groupId = groupId
        if let existing = existingGeofence {
            self.name = existing.name
            self.selectedCoordinate = existing.coordinate
            self.radiusMeters = existing.radiusMeters
        } else if let userLocation = LocationManager.shared.currentLocation {
            self.selectedCoordinate = userLocation.coordinate
        }
    }

    func saveGeofence() async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }

        do {
            _ = try await firebaseService.configureGeofence(
                groupId: groupId,
                name: name,
                latitude: selectedCoordinate.latitude,
                longitude: selectedCoordinate.longitude,
                radiusMeters: radiusMeters
            )

            // Also register with CoreLocation for real device monitoring
            LocationManager.shared.startMonitoringGeofence(
                id: "geo_\(groupId)",
                center: selectedCoordinate,
                radiusMeters: radiusMeters
            )

            await MainActor.run {
                self.isSaved = true
                self.isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}
