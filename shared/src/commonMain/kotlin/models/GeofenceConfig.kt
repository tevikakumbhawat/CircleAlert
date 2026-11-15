package models

import kotlinx.serialization.Serializable

@Serializable
data class GeofenceConfig(
    val id: String,
    val groupId: String,
    val name: String,
    val latitude: Double,
    val longitude: Double,
    val radiusMeters: Double,
    val createdBy: String,
    val createdAtEpochMs: Long = 0L,
    val isActive: Boolean = true
) {
    companion object {
        const val MIN_RADIUS_METERS: Double = 50.0
        const val MAX_RADIUS_METERS: Double = 10000.0 // 10 km
        const val DEFAULT_RADIUS_METERS: Double = 250.0

        fun isValidCoordinate(latitude: Double, longitude: Double): Boolean {
            return latitude in -90.0..90.0 && longitude in -180.0..180.0
        }

        fun isValidRadius(radiusMeters: Double): Boolean {
            return radiusMeters in MIN_RADIUS_METERS..MAX_RADIUS_METERS
        }
    }
}
