package repository

import kotlinx.coroutines.flow.Flow
import models.CircleAlertResult
import models.GroupMember
import models.MemberGeofenceStatus
import models.MemberLocation

interface MemberRepository {
    fun observeGroupMembers(groupId: String): Flow<List<GroupMember>>
    suspend fun getGroupMembers(groupId: String): CircleAlertResult<List<GroupMember>>
    suspend fun addMemberToGroup(groupId: String, member: GroupMember): CircleAlertResult<Unit>
    suspend fun removeMemberFromGroup(groupId: String, userId: String): CircleAlertResult<Unit>
    suspend fun updateMemberLocation(groupId: String, userId: String, location: MemberLocation): CircleAlertResult<Unit>
    suspend fun updateMemberGeofenceStatus(groupId: String, userId: String, status: MemberGeofenceStatus): CircleAlertResult<Unit>
}
