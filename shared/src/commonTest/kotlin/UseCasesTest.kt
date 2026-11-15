import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import models.*
import repository.*
import usecase.*
import kotlin.test.*

class FakeGroupRepository : GroupRepository {
    val groups = mutableMapOf<String, TrackingGroup>()

    override fun observeUserGroups(userId: String): Flow<List<TrackingGroup>> = flowOf(groups.values.toList())
    override fun observeGroup(groupId: String): Flow<TrackingGroup?> = flowOf(groups[groupId])

    override suspend fun getGroupById(groupId: String): CircleAlertResult<TrackingGroup> {
        val group = groups[groupId] ?: return CircleAlertResult.Error(CircleAlertException.GroupNotFoundException())
        return CircleAlertResult.Success(group)
    }

    override suspend fun findGroupByInviteCode(inviteCode: String): CircleAlertResult<TrackingGroup> {
        val group = groups.values.find { it.inviteCode == inviteCode }
            ?: return CircleAlertResult.Error(CircleAlertException.GroupNotFoundException())
        return CircleAlertResult.Success(group)
    }

    override suspend fun createGroup(name: String, inviteCode: String, ownerId: String): CircleAlertResult<TrackingGroup> {
        val group = TrackingGroup(
            id = "grp_${groups.size + 1}",
            name = name,
            inviteCode = inviteCode,
            ownerId = ownerId,
            createdAtEpochMs = 1000L,
            memberCount = 1
        )
        groups[group.id] = group
        return CircleAlertResult.Success(group)
    }

    override suspend fun updateGroupGeofence(groupId: String, geofenceId: String): CircleAlertResult<Unit> {
        val existing = groups[groupId] ?: return CircleAlertResult.Error(CircleAlertException.GroupNotFoundException())
        groups[groupId] = existing.copy(geofenceId = geofenceId)
        return CircleAlertResult.Success(Unit)
    }

    override suspend fun incrementMemberCount(groupId: String, delta: Int): CircleAlertResult<Unit> {
        val existing = groups[groupId] ?: return CircleAlertResult.Error(CircleAlertException.GroupNotFoundException())
        groups[groupId] = existing.copy(memberCount = existing.memberCount + delta)
        return CircleAlertResult.Success(Unit)
    }
}

class FakeMemberRepository : MemberRepository {
    val members = mutableMapOf<String, MutableList<GroupMember>>()

    override fun observeGroupMembers(groupId: String): Flow<List<GroupMember>> =
        flowOf(members[groupId] ?: emptyList())

    override suspend fun getGroupMembers(groupId: String): CircleAlertResult<List<GroupMember>> {
        return CircleAlertResult.Success(members[groupId] ?: emptyList())
    }

    override suspend fun addMemberToGroup(groupId: String, member: GroupMember): CircleAlertResult<Unit> {
        val list = members.getOrPut(groupId) { mutableListOf() }
        list.add(member)
        return CircleAlertResult.Success(Unit)
    }

    override suspend fun removeMemberFromGroup(groupId: String, userId: String): CircleAlertResult<Unit> {
        members[groupId]?.removeAll { it.userId == userId }
        return CircleAlertResult.Success(Unit)
    }

    override suspend fun updateMemberLocation(groupId: String, userId: String, location: MemberLocation): CircleAlertResult<Unit> {
        val list = members[groupId] ?: return CircleAlertResult.Success(Unit)
        val idx = list.indexOfFirst { it.userId == userId }
        if (idx >= 0) {
            list[idx] = list[idx].copy(lastLocation = location)
        }
        return CircleAlertResult.Success(Unit)
    }

    override suspend fun updateMemberGeofenceStatus(groupId: String, userId: String, status: MemberGeofenceStatus): CircleAlertResult<Unit> {
        val list = members[groupId] ?: return CircleAlertResult.Success(Unit)
        val idx = list.indexOfFirst { it.userId == userId }
        if (idx >= 0) {
            list[idx] = list[idx].copy(geofenceStatus = status)
        }
        return CircleAlertResult.Success(Unit)
    }
}

class FakeGeofenceRepository : GeofenceRepository {
    val fences = mutableMapOf<String, GeofenceConfig>()

    override fun observeGeofence(geofenceId: String): Flow<GeofenceConfig?> = flowOf(fences[geofenceId])
    override suspend fun getGeofenceById(geofenceId: String): CircleAlertResult<GeofenceConfig> {
        val fence = fences[geofenceId] ?: return CircleAlertResult.Error(CircleAlertException.GenericException("Geofence not found"))
        return CircleAlertResult.Success(fence)
    }
    override suspend fun getGeofenceForGroup(groupId: String): CircleAlertResult<GeofenceConfig?> {
        val fence = fences.values.find { it.groupId == groupId }
        return CircleAlertResult.Success(fence)
    }
    override suspend fun saveGeofence(config: GeofenceConfig): CircleAlertResult<GeofenceConfig> {
        fences[config.id] = config
        return CircleAlertResult.Success(config)
    }
    override suspend fun deleteGeofence(geofenceId: String): CircleAlertResult<Unit> {
        fences.remove(geofenceId)
        return CircleAlertResult.Success(Unit)
    }
}

class FakeExitEventRepository : ExitEventRepository {
    val events = mutableListOf<GeofenceExitEvent>()

    override fun observeRecentExitEvents(groupId: String, limit: Int): Flow<List<GeofenceExitEvent>> =
        flowOf(events.filter { it.groupId == groupId })

    override suspend fun recordExitEvent(event: GeofenceExitEvent): CircleAlertResult<GeofenceExitEvent> {
        events.add(event)
        return CircleAlertResult.Success(event)
    }

    override suspend fun getRecentExitEvents(groupId: String, limit: Int): CircleAlertResult<List<GeofenceExitEvent>> {
        return CircleAlertResult.Success(events.filter { it.groupId == groupId })
    }

    override suspend fun acknowledgeExitEvent(eventId: String, userId: String): CircleAlertResult<Unit> {
        val idx = events.indexOfFirst { it.id == eventId }
        if (idx >= 0) {
            val curr = events[idx]
            events[idx] = curr.copy(acknowledgedByUsers = curr.acknowledgedByUsers + userId)
        }
        return CircleAlertResult.Success(Unit)
    }
}

class UseCasesTest {

    private lateinit var groupRepo: FakeGroupRepository
    private lateinit var memberRepo: FakeMemberRepository
    private lateinit var geofenceRepo: FakeGeofenceRepository
    private lateinit var exitRepo: FakeExitEventRepository

    private val userAlice = User("user_1", "alice@example.com", "Alice Smith")
    private val userBob = User("user_2", "bob@example.com", "Bob Jones")

    @BeforeTest
    fun setUp() {
        groupRepo = FakeGroupRepository()
        memberRepo = FakeMemberRepository()
        geofenceRepo = FakeGeofenceRepository()
        exitRepo = FakeExitEventRepository()
    }

    @Test
    fun testCreateGroupUseCaseSuccess() = runTest {
        val useCase = CreateGroupUseCase(groupRepo, memberRepo)
        val result = useCase("Family Trip", userAlice, 1000L)

        assertTrue(result.isSuccess)
        val group = result.getOrNull()!!
        assertEquals("Family Trip", group.name)
        assertEquals(userAlice.id, group.ownerId)
        assertEquals(6, group.inviteCode.length)

        val members = memberRepo.getGroupMembers(group.id).getOrNull()!!
        assertEquals(1, members.size)
        assertEquals(userAlice.id, members.first().userId)
        assertEquals(MemberRole.OWNER, members.first().role)
    }

    @Test
    fun testCreateGroupValidation() = runTest {
        val useCase = CreateGroupUseCase(groupRepo, memberRepo)
        val shortResult = useCase("AB", userAlice, 1000L)
        assertTrue(shortResult.isError)
        assertIs<CircleAlertException.InvalidGroupNameException>(shortResult.exceptionOrNull())
    }

    @Test
    fun testJoinGroupUseCaseSuccess() = runTest {
        val createUseCase = CreateGroupUseCase(groupRepo, memberRepo)
        val created = createUseCase("Team Beta", userAlice, 1000L).getOrNull()!!

        val joinUseCase = JoinGroupUseCase(groupRepo, memberRepo)
        val joinResult = joinUseCase(created.inviteCode, userBob, 2000L)

        assertTrue(joinResult.isSuccess)
        val members = memberRepo.getGroupMembers(created.id).getOrNull()!!
        assertEquals(2, members.size)
        assertTrue(members.any { it.userId == userBob.id && it.role == MemberRole.MEMBER })
    }

    @Test
    fun testJoinGroupDuplicateRejection() = runTest {
        val createUseCase = CreateGroupUseCase(groupRepo, memberRepo)
        val created = createUseCase("Team Gamma", userAlice, 1000L).getOrNull()!!

        val joinUseCase = JoinGroupUseCase(groupRepo, memberRepo)
        val duplicateResult = joinUseCase(created.inviteCode, userAlice, 2000L)

        assertTrue(duplicateResult.isError)
        assertIs<CircleAlertException.MemberAlreadyExistsException>(duplicateResult.exceptionOrNull())
    }

    @Test
    fun testProcessGeofenceExitNotifiesOnlyOtherMembers() = runTest {
        // Setup group with Alice (creator) and Bob
        val createUseCase = CreateGroupUseCase(groupRepo, memberRepo)
        val group = createUseCase("Campus Patrol", userAlice, 1000L).getOrNull()!!

        val joinUseCase = JoinGroupUseCase(groupRepo, memberRepo)
        joinUseCase(group.inviteCode, userBob, 2000L)

        // Setup geofence
        val configUseCase = ConfigureGeofenceUseCase(geofenceRepo, groupRepo)
        configUseCase(
            groupId = group.id,
            name = "Campus Area",
            latitude = 37.7749,
            longitude = -122.4194,
            radiusMeters = 200.0,
            creatorId = userAlice.id,
            currentEpochMs = 2500L
        )

        // Bob leaves geofence
        val exitUseCase = ProcessGeofenceExitUseCase(groupRepo, memberRepo, geofenceRepo, exitRepo)
        val exitResult = exitUseCase(
            groupId = group.id,
            userId = userBob.id,
            exitLatitude = 37.7850,
            exitLongitude = -122.4194,
            currentEpochMs = 3000L,
            isSimulated = false
        )

        assertTrue(exitResult.isSuccess)
        val outcome = exitResult.getOrNull()!!

        // Exiting member is Bob
        assertEquals(userBob.id, outcome.exitEvent.userId)
        assertEquals("Campus Area", outcome.exitEvent.geofenceName)
        assertTrue(outcome.exitEvent.distanceOutsideMeters > 0.0)

        // Recipient to notify MUST be Alice, NOT Bob!
        assertEquals(1, outcome.notifiedRecipients.size)
        assertEquals(userAlice.id, outcome.notifiedRecipients.first().userId)
        assertFalse(outcome.notifiedRecipients.any { it.userId == userBob.id })

        // Check member status updated
        val members = memberRepo.getGroupMembers(group.id).getOrNull()!!
        val updatedBob = members.find { it.userId == userBob.id }!!
        assertEquals(MemberGeofenceStatus.OUTSIDE, updatedBob.geofenceStatus)
    }
}
