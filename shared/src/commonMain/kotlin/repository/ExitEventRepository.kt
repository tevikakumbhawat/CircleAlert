package repository

import kotlinx.coroutines.flow.Flow
import models.CircleAlertResult
import models.GeofenceExitEvent

interface ExitEventRepository {
    fun observeRecentExitEvents(groupId: String, limit: Int = 50): Flow<List<GeofenceExitEvent>>
    suspend fun recordExitEvent(event: GeofenceExitEvent): CircleAlertResult<GeofenceExitEvent>
    suspend fun getRecentExitEvents(groupId: String, limit: Int = 50): CircleAlertResult<List<GeofenceExitEvent>>
    suspend fun acknowledgeExitEvent(eventId: String, userId: String): CircleAlertResult<Unit>
}
