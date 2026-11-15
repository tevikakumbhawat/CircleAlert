package models

import kotlinx.serialization.Serializable

@Serializable
data class GeofenceExitEvent(
    val id: String,
    val groupId: String,
    val groupName: String,
    val geofenceId: String,
    val geofenceName: String,
    val userId: String,
    val userName: String,
    val userEmail: String,
    val exitLatitude: Double,
    val exitLongitude: Double,
    val distanceOutsideMeters: Double = 0.0,
    val timestampEpochMs: Long = 0L,
    val isSimulated: Boolean = false,
    val acknowledgedByUsers: List<String> = emptyList()
)
