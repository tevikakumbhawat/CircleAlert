package models

import kotlinx.serialization.Serializable

@Serializable
data class TrackingGroup(
    val id: String,
    val name: String,
    val inviteCode: String,
    val ownerId: String,
    val createdAtEpochMs: Long = 0L,
    val geofenceId: String? = null,
    val memberCount: Int = 1
)
