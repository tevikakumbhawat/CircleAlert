package usecase

import kotlinx.coroutines.flow.Flow
import models.CircleAlertResult
import models.GroupMember
import repository.MemberRepository

class GetGroupMembersUseCase(
    private val memberRepository: MemberRepository
) {
    operator fun invoke(groupId: String): Flow<List<GroupMember>> {
        return memberRepository.observeGroupMembers(groupId)
    }

    suspend fun getOnce(groupId: String): CircleAlertResult<List<GroupMember>> {
        return memberRepository.getGroupMembers(groupId)
    }
}
