package usecase

import models.*
import repository.ExitEventRepository
import repository.GeofenceRepository
import repository.GroupRepository
import repository.MemberRepository
import utils.LocationUtils

data class ProcessExitOutcome(
    val exitEvent: GeofenceExitEvent,
    val notifiedRecipients: List<GroupMember>
)

class ProcessGeofenceExitUseCase(
    private val groupRepository: GroupRepository,
    private val memberRepository: MemberRepository,
    private val geofenceRepository: GeofenceRepository,
    private val exitEventRepository: ExitEventRepository
) {
    suspend operator fun invoke(
        groupId: String,
        userId: String,
        exitLatitude: Double,
        exitLongitude: Double,
        currentEpochMs: Long,
        isSimulated: Boolean = false
    ): CircleAlertResult<ProcessExitOutcome> {
        // 1. Fetch group
        val groupResult = groupRepository.getGroupById(groupId)
        val group = when (groupResult) {
            is CircleAlertResult.Success -> groupResult.data
            is CircleAlertResult.Error -> return groupResult
        }

        // 2. Fetch all members
        val membersResult = memberRepository.getGroupMembers(groupId)
        val members = when (membersResult) {
            is CircleAlertResult.Success -> membersResult.data
            is CircleAlertResult.Error -> return membersResult
        }

        val exitingMember = members.find { it.userId == userId }
            ?: return CircleAlertResult.Error(CircleAlertException.GenericException("Member $userId not found in group $groupId"))

        // 3. Fetch geofence if configured
        val geofence = if (group.geofenceId != null) {
            val geoResult = geofenceRepository.getGeofenceById(group.geofenceId)
            when (geoResult) {
                is CircleAlertResult.Success -> geoResult.data
                is CircleAlertResult.Error -> null
            }
        } else {
            null
        }

        val geofenceName = geofence?.name ?: "Group Perimeter"
        val geofenceId = geofence?.id ?: "unknown"

        val distanceOutside = if (geofence != null) {
            LocationUtils.distanceOutsideGeofence(
                pointLat = exitLatitude,
                pointLon = exitLongitude,
                fenceCenterLat = geofence.latitude,
                fenceCenterLon = geofence.longitude,
                radiusMeters = geofence.radiusMeters
            )
        } else {
            0.0
        }

        // 4. Construct exit event
        val eventId = "exit_${groupId}_${userId}_${currentEpochMs}"
        val exitEvent = GeofenceExitEvent(
            id = eventId,
            groupId = groupId,
            groupName = group.name,
            geofenceId = geofenceId,
            geofenceName = geofenceName,
            userId = userId,
            userName = exitingMember.displayName,
            userEmail = exitingMember.email,
            exitLatitude = exitLatitude,
            exitLongitude = exitLongitude,
            distanceOutsideMeters = distanceOutside,
            timestampEpochMs = currentEpochMs,
            isSimulated = isSimulated,
            acknowledgedByUsers = emptyList()
        )

        // 5. Save exit event
        val recordResult = exitEventRepository.recordExitEvent(exitEvent)
        if (recordResult is CircleAlertResult.Error) {
            return recordResult
        }

        // 6. Update member status to OUTSIDE and record location
        memberRepository.updateMemberGeofenceStatus(groupId, userId, MemberGeofenceStatus.OUTSIDE)
        memberRepository.updateMemberLocation(
            groupId = groupId,
            userId = userId,
            location = MemberLocation(
                latitude = exitLatitude,
                longitude = exitLongitude,
                accuracy = 10.0,
                timestampEpochMs = currentEpochMs
            )
        )

        // 7. Filter other members (excluding exiting member) to be notified
        val otherMembers = members.filter { it.userId != userId }

        return CircleAlertResult.Success(
            ProcessExitOutcome(
                exitEvent = exitEvent,
                notifiedRecipients = otherMembers
            )
        )
    }
}
