package models

import kotlinx.serialization.Serializable

@Serializable
data class User(
    val id: String,
    val email: String,
    val displayName: String,
    val photoUrl: String? = null,
    val pushToken: String? = null,
    val createdAtEpochMs: Long = 0L
)
