package repository

import kotlinx.coroutines.flow.Flow
import models.CircleAlertResult
import models.GeofenceConfig

interface GeofenceRepository {
    fun observeGeofence(geofenceId: String): Flow<GeofenceConfig?>
    suspend fun getGeofenceById(geofenceId: String): CircleAlertResult<GeofenceConfig>
    suspend fun getGeofenceForGroup(groupId: String): CircleAlertResult<GeofenceConfig?>
    suspend fun saveGeofence(config: GeofenceConfig): CircleAlertResult<GeofenceConfig>
    suspend fun deleteGeofence(geofenceId: String): CircleAlertResult<Unit>
}
