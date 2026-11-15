package utils

import kotlin.math.*

object LocationUtils {
    private const val EARTH_RADIUS_METERS = 6371000.0

    /**
     * Calculates great-circle distance between two coordinates in meters using the Haversine formula.
     */
    fun calculateDistanceMeters(
        lat1: Double, lon1: Double,
        lat2: Double, lon2: Double
    ): Double {
        val dLat = (lat2 - lat1).toRadians()
        val dLon = (lon2 - lon1).toRadians()

        val rLat1 = lat1.toRadians()
        val rLat2 = lat2.toRadians()

        val a = sin(dLat / 2.0).pow(2.0) +
                sin(dLon / 2.0).pow(2.0) * cos(rLat1) * cos(rLat2)
        val c = 2.0 * atan2(sqrt(a), sqrt(1.0 - a))

        return EARTH_RADIUS_METERS * c
    }

    /**
     * Checks if a point is within a circular geofence.
     */
    fun isPointInsideGeofence(
        pointLat: Double,
        pointLon: Double,
        fenceCenterLat: Double,
        fenceCenterLon: Double,
        radiusMeters: Double
    ): Boolean {
        val distance = calculateDistanceMeters(pointLat, pointLon, fenceCenterLat, fenceCenterLon)
        return distance <= radiusMeters
    }

    /**
     * Calculates how many meters outside the geofence boundary a point is.
     * Returns 0.0 if inside or on boundary.
     */
    fun distanceOutsideGeofence(
        pointLat: Double,
        pointLon: Double,
        fenceCenterLat: Double,
        fenceCenterLon: Double,
        radiusMeters: Double
    ): Double {
        val distance = calculateDistanceMeters(pointLat, pointLon, fenceCenterLat, fenceCenterLon)
        return max(0.0, distance - radiusMeters)
    }

    private fun Double.toRadians(): Double = this * PI / 180.0
}
