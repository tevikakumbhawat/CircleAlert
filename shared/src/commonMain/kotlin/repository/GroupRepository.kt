package repository

import kotlinx.coroutines.flow.Flow
import models.CircleAlertResult
import models.TrackingGroup

interface GroupRepository {
    fun observeUserGroups(userId: String): Flow<List<TrackingGroup>>
    fun observeGroup(groupId: String): Flow<TrackingGroup?>

    suspend fun getGroupById(groupId: String): CircleAlertResult<TrackingGroup>
    suspend fun findGroupByInviteCode(inviteCode: String): CircleAlertResult<TrackingGroup>
    suspend fun createGroup(name: String, inviteCode: String, ownerId: String): CircleAlertResult<TrackingGroup>
    suspend fun updateGroupGeofence(groupId: String, geofenceId: String): CircleAlertResult<Unit>
    suspend fun incrementMemberCount(groupId: String, delta: Int = 1): CircleAlertResult<Unit>
}
