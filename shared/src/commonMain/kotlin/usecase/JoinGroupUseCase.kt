package usecase

import models.*
import repository.GroupRepository
import repository.MemberRepository
import utils.InviteCodeGenerator

class JoinGroupUseCase(
    private val groupRepository: GroupRepository,
    private val memberRepository: MemberRepository
) {
    suspend operator fun invoke(
        rawInviteCode: String,
        currentUser: User,
        currentEpochMs: Long
    ): CircleAlertResult<TrackingGroup> {
        val normalizedCode = InviteCodeGenerator.normalize(rawInviteCode)
        if (!InviteCodeGenerator.isValid(normalizedCode)) {
            return CircleAlertResult.Error(CircleAlertException.InvalidInviteCodeException())
        }

        // Look up group by invite code
        val groupResult = groupRepository.findGroupByInviteCode(normalizedCode)
        val group = when (groupResult) {
            is CircleAlertResult.Success -> groupResult.data
            is CircleAlertResult.Error -> return groupResult
        }

        // Check if member already in group
        val existingMembersResult = memberRepository.getGroupMembers(group.id)
        if (existingMembersResult is CircleAlertResult.Success) {
            val alreadyJoined = existingMembersResult.data.any { it.userId == currentUser.id }
            if (alreadyJoined) {
                return CircleAlertResult.Error(CircleAlertException.MemberAlreadyExistsException())
            }
        }

        // Add user as regular MEMBER
        val newMember = GroupMember(
            userId = currentUser.id,
            displayName = currentUser.displayName,
            email = currentUser.email,
            role = MemberRole.MEMBER,
            joinedAtEpochMs = currentEpochMs,
            geofenceStatus = MemberGeofenceStatus.UNKNOWN,
            pushToken = currentUser.pushToken
        )

        val addResult = memberRepository.addMemberToGroup(group.id, newMember)
        if (addResult is CircleAlertResult.Error) {
            return CircleAlertResult.Error(addResult.exception)
        }

        // Increment member count on the group
        groupRepository.incrementMemberCount(group.id, 1)

        return CircleAlertResult.Success(group.copy(memberCount = group.memberCount + 1))
    }
}
