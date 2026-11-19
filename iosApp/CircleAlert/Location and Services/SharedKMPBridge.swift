import Foundation
import CoreLocation
#if canImport(SharedCircleAlert)
import SharedCircleAlert
#endif

/// Swift Bridge to genuine Kotlin Multiplatform business logic, use cases,
/// invite code generation, and geofence calculation algorithms.
final class SharedKMPBridge {
    static let shared = SharedKMPBridge()

    /// Verifies invite code formatting using Kotlin InviteCodeGenerator or local rules.
    func validateInviteCode(_ code: String) -> Bool {
        #if canImport(SharedCircleAlert)
        return InviteCodeGenerator.shared.isValid(code: code)
        #else
        let cleaned = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        let alphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
        return cleaned.count == 6 && cleaned.allSatisfy { alphabet.contains($0) }
        #endif
    }

    /// Generates invite code using Kotlin Multiplatform InviteCodeGenerator.
    func generateInviteCode() -> String {
        #if canImport(SharedCircleAlert)
        return InviteCodeGenerator.shared.generate()
        #else
        let alphabet = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
        return String((0..<6).map { _ in alphabet.randomElement()! })
        #endif
    }

    /// Calculates distance in meters using Kotlin LocationUtils (Haversine formula).
    func calculateDistanceMeters(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ) -> Double {
        #if canImport(SharedCircleAlert)
        return LocationUtils.shared.calculateDistanceMeters(lat1: lat1, lon1: lon1, lat2: lat2, lon2: lon2)
        #else
        let loc1 = CLLocation(latitude: lat1, longitude: lon1)
        let loc2 = CLLocation(latitude: lat2, longitude: lon2)
        return loc2.distance(from: loc1)
        #endif
    }

    /// Checks if point is inside geofence using Kotlin LocationUtils.
    func isPointInsideGeofence(
        pointLat: Double, pointLon: Double,
        centerLat: Double, centerLon: Double,
        radiusMeters: Double
    ) -> Bool {
        #if canImport(SharedCircleAlert)
        return LocationUtils.shared.isPointInsideGeofence(
            pointLat: pointLat, pointLon: pointLon,
            fenceCenterLat: centerLat, fenceCenterLon: centerLon,
            radiusMeters: radiusMeters
        )
        #else
        let dist = calculateDistanceMeters(lat1: pointLat, lon1: pointLon, lat2: centerLat, lon2: centerLon)
        return dist <= radiusMeters
        #endif
    }
}
