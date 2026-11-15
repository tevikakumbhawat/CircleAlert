package models

import kotlinx.serialization.Serializable

@Serializable
enum class MemberRole {
    OWNER,
    ADMIN,
    MEMBER
}

@Serializable
enum class MemberGeofenceStatus {
    INSIDE,
    OUTSIDE,
    UNKNOWN
}

@Serializable
data class MemberLocation(
    val latitude: Double,
    val longitude: Double,
    val accuracy: Double = 0.0,
    val timestampEpochMs: Long = 0L
)

@Serializable
data class GroupMember(
    val userId: String,
    val displayName: String,
    val email: String,
    val role: MemberRole = MemberRole.MEMBER,
    val joinedAtEpochMs: Long = 0L,
    val geofenceStatus: MemberGeofenceStatus = MemberGeofenceStatus.UNKNOWN,
    val lastLocation: MemberLocation? = null,
    val lastSeenEpochMs: Long = 0L,
    val pushToken: String? = null
)
