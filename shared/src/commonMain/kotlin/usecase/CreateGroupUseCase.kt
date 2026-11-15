package usecase

import models.*
import repository.GroupRepository
import repository.MemberRepository
import utils.InviteCodeGenerator

class CreateGroupUseCase(
    private val groupRepository: GroupRepository,
    private val memberRepository: MemberRepository
) {
    suspend operator fun invoke(
        name: String,
        currentUser: User,
        currentEpochMs: Long
    ): CircleAlertResult<TrackingGroup> {
        val trimmedName = name.trim()
        if (trimmedName.length !in 3..50) {
            return CircleAlertResult.Error(CircleAlertException.InvalidGroupNameException())
        }

        // Generate a unique 6-character invite code
        val inviteCode = InviteCodeGenerator.generate()

        val groupResult = groupRepository.createGroup(
            name = trimmedName,
            inviteCode = inviteCode,
            ownerId = currentUser.id
        )

        val createdGroup = when (groupResult) {
            is CircleAlertResult.Success -> groupResult.data
            is CircleAlertResult.Error -> return groupResult
        }

        // Add the creator as the OWNER member of the group
        val ownerMember = GroupMember(
            userId = currentUser.id,
            displayName = currentUser.displayName,
            email = currentUser.email,
            role = MemberRole.OWNER,
            joinedAtEpochMs = currentEpochMs,
            geofenceStatus = MemberGeofenceStatus.UNKNOWN,
            pushToken = currentUser.pushToken
        )

        val addMemberResult = memberRepository.addMemberToGroup(createdGroup.id, ownerMember)
        if (addMemberResult is CircleAlertResult.Error) {
            return CircleAlertResult.Error(addMemberResult.exception)
        }

        return CircleAlertResult.Success(createdGroup)
    }
}
