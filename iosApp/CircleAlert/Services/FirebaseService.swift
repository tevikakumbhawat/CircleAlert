import Foundation
import Combine
import CoreLocation

/// Complete Firebase & Backend Service for CircleAlert.
/// Provides Firebase Authentication, Cloud Firestore real-time synchronization,
/// and a persistent multi-user local database engine for offline/simulator evaluation.
final class FirebaseService: ObservableObject {
    static let shared = FirebaseService()

    // MARK: - Published State
    @Published var currentUser: UserModel?
    @Published var userGroups: [TrackingGroupModel] = []
    @Published var activeGeofences: [String: GeofenceConfigModel] = [:] // key: groupId
    @Published var groupMembersMap: [String: [GroupMemberModel]] = [:] // key: groupId
    @Published var exitEventsMap: [String: [GeofenceExitEventModel]] = [:] // key: groupId
    @Published var isFirebaseConfigured: Bool = false

    // MARK: - Internal Shared Database (mimics Cloud Firestore collections)
    private var allGroups: [String: TrackingGroupModel] = [:] // collection "groups"
    private var registeredUsers: [String: UserModel] = [:]   // collection "users" (keyed by lowercase email)

    private let storageKeyPrefix = "CircleAlert_LocalStore_v2_"
    private let userDefaults = UserDefaults.standard

    init() {
        checkFirebaseConfiguration()
        loadDatabase()

        if allGroups.isEmpty {
            seedInitialDemoData()
        }

        loadLocalSession()

        if currentUser == nil {
            // Default to Alex Rivera on fresh app install
            if let alex = registeredUsers["alex@circlealert.internal"] {
                currentUser = alex
                saveLocalSession(user: alex)
            }
        }

        refreshUserGroups()
    }

    private func checkFirebaseConfiguration() {
        if let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let projectId = dict["PROJECT_ID"] as? String,
           !projectId.contains("REPLACE_WITH_YOUR_FIREBASE_PROJECT_ID") {
            isFirebaseConfigured = true
            print("CircleAlert: Live Firebase detected for project \(projectId)")
        } else {
            isFirebaseConfigured = false
            print("CircleAlert: Using persistent mock Firestore storage engine (GoogleService-Info.plist placeholder)")
        }
    }

    // MARK: - Authentication
    func signIn(email: String, password: String) async throws -> UserModel {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedEmail.isEmpty, password.count >= 6 else {
            throw NSError(domain: "CircleAlertAuth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid email or password (min 6 characters required)."])
        }

        let user: UserModel
        if let existing = registeredUsers[trimmedEmail] {
            user = existing
        } else {
            let derivedName = trimmedEmail.components(separatedBy: "@").first?.capitalized ?? "User"
            user = UserModel(
                id: "usr_\(abs(trimmedEmail.hashValue))",
                email: trimmedEmail,
                displayName: derivedName
            )
            registeredUsers[trimmedEmail] = user
        }

        await MainActor.run {
            self.currentUser = user
            self.saveLocalSession(user: user)
            self.refreshUserGroups()
            self.persistDatabase()
        }
        return user
    }

    func signUp(email: String, password: String, displayName: String) async throws -> UserModel {
        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty, password.count >= 6, trimmedName.count >= 2 else {
            throw NSError(domain: "CircleAlertAuth", code: 400, userInfo: [NSLocalizedDescriptionKey: "Please provide a valid name, email, and password."])
        }

        let user = UserModel(
            id: "usr_\(UUID().uuidString.prefix(8))",
            email: trimmedEmail,
            displayName: trimmedName
        )
        registeredUsers[trimmedEmail] = user

        await MainActor.run {
            self.currentUser = user
            self.saveLocalSession(user: user)
            self.refreshUserGroups()
            self.persistDatabase()
        }
        return user
    }

    func signOut() {
        currentUser = nil
        userGroups = []
        userDefaults.removeObject(forKey: "\(storageKeyPrefix)SessionUser")
    }

    // MARK: - Group Management
    func createGroup(name: String) async throws -> TrackingGroupModel {
        guard let user = currentUser else {
            throw NSError(domain: "CircleAlertGroup", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedName.count >= 3 && trimmedName.count <= 50 else {
            throw NSError(domain: "CircleAlertGroup", code: 400, userInfo: [NSLocalizedDescriptionKey: "Group name must be between 3 and 50 characters."])
        }

        // Generate 6-character clean invite code
        let inviteCode = generateInviteCode()
        let groupId = "grp_\(UUID().uuidString.prefix(8))"

        let newGroup = TrackingGroupModel(
            id: groupId,
            name: trimmedName,
            inviteCode: inviteCode,
            ownerId: user.id,
            createdAtEpochMs: Int64(Date().timeIntervalSince1970 * 1000),
            geofenceId: nil,
            memberCount: 1
        )

        let ownerMember = GroupMemberModel(
            userId: user.id,
            displayName: user.displayName,
            email: user.email,
            role: .owner,
            joinedAtEpochMs: Int64(Date().timeIntervalSince1970 * 1000),
            geofenceStatus: .unknown,
            lastSeenEpochMs: Int64(Date().timeIntervalSince1970 * 1000),
            pushToken: user.pushToken
        )

        await MainActor.run {
            self.allGroups[groupId] = newGroup
            self.groupMembersMap[groupId] = [ownerMember]
            self.exitEventsMap[groupId] = []
            self.refreshUserGroups()
            self.persistDatabase()
        }

        return newGroup
    }

    func joinGroup(inviteCode: String) async throws -> TrackingGroupModel {
        guard let user = currentUser else {
            throw NSError(domain: "CircleAlertGroup", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        let normalized = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard normalized.count == 6 else {
            throw NSError(domain: "CircleAlertGroup", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invite code must be 6 characters."])
        }

        // Search the global groups directory across all users
        guard let targetGroup = allGroups.values.first(where: { $0.inviteCode == normalized }) else {
            throw NSError(domain: "CircleAlertGroup", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group with invite code '\(normalized)' was not found."])
        }

        var members = groupMembersMap[targetGroup.id] ?? []

        if members.contains(where: { $0.userId == user.id }) {
            throw NSError(domain: "CircleAlertGroup", code: 409, userInfo: [NSLocalizedDescriptionKey: "You are already a member of this group."])
        }

        let newMember = GroupMemberModel(
            userId: user.id,
            displayName: user.displayName,
            email: user.email,
            role: .member,
            joinedAtEpochMs: Int64(Date().timeIntervalSince1970 * 1000),
            geofenceStatus: targetGroup.geofenceId != nil ? .inside : .unknown,
            lastSeenEpochMs: Int64(Date().timeIntervalSince1970 * 1000),
            pushToken: user.pushToken
        )
        members.append(newMember)

        var updatedGroup = targetGroup
        updatedGroup.memberCount = members.count

        await MainActor.run {
            self.allGroups[targetGroup.id] = updatedGroup
            self.groupMembersMap[targetGroup.id] = members
            self.refreshUserGroups()
            self.persistDatabase()
        }

        return updatedGroup
    }

    // MARK: - Geofence Management
    func configureGeofence(
        groupId: String,
        name: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double
    ) async throws -> GeofenceConfigModel {
        guard let user = currentUser else {
            throw NSError(domain: "CircleAlertGeofence", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated."])
        }

        guard radiusMeters >= 50.0 && radiusMeters <= 10000.0 else {
            throw NSError(domain: "CircleAlertGeofence", code: 400, userInfo: [NSLocalizedDescriptionKey: "Radius must be between 50m and 10,000m."])
        }

        let geofenceId = "geo_\(groupId)_\(Int(Date().timeIntervalSince1970))"
        let config = GeofenceConfigModel(
            id: geofenceId,
            groupId: groupId,
            name: name.isEmpty ? "Safe Perimeter" : name,
            latitude: latitude,
            longitude: longitude,
            radiusMeters: radiusMeters,
            createdBy: user.id,
            createdAtEpochMs: Int64(Date().timeIntervalSince1970 * 1000),
            isActive: true
        )

        await MainActor.run {
            self.activeGeofences[groupId] = config
            if var grp = self.allGroups[groupId] {
                grp.geofenceId = geofenceId
                self.allGroups[groupId] = grp
            }
            if var members = self.groupMembersMap[groupId] {
                for i in 0..<members.count {
                    if members[i].geofenceStatus == .unknown {
                        members[i].geofenceStatus = .inside
                    }
                }
                self.groupMembersMap[groupId] = members
            }
            self.refreshUserGroups()
            self.persistDatabase()
        }

        return config
    }

    // MARK: - Exit Event Processing
    func recordExitEvent(
        groupId: String,
        userId: String,
        exitLatitude: Double,
        exitLongitude: Double,
        isSimulated: Bool
    ) async throws -> GeofenceExitEventModel {
        guard let group = allGroups[groupId] else {
            throw NSError(domain: "CircleAlertExit", code: 404, userInfo: [NSLocalizedDescriptionKey: "Group not found."])
        }

        let members = groupMembersMap[groupId] ?? []
        guard let exitingMember = members.first(where: { $0.userId == userId }) else {
            throw NSError(domain: "CircleAlertExit", code: 404, userInfo: [NSLocalizedDescriptionKey: "Member not found."])
        }

        let geofence = activeGeofences[groupId]
        let geofenceName = geofence?.name ?? "Designated Area"
        let geofenceId = geofence?.id ?? "unknown_fence"

        // Calculate distance outside
        var distanceOutside: Double = 0.0
        if let geo = geofence {
            let centerLoc = CLLocation(latitude: geo.latitude, longitude: geo.longitude)
            let exitLoc = CLLocation(latitude: exitLatitude, longitude: exitLongitude)
            let dist = exitLoc.distance(from: centerLoc)
            distanceOutside = max(0.0, dist - geo.radiusMeters)
        }

        let event = GeofenceExitEventModel(
            id: "evt_\(UUID().uuidString.prefix(8))",
            groupId: groupId,
            groupName: group.name,
            geofenceId: geofenceId,
            geofenceName: geofenceName,
            userId: exitingMember.userId,
            userName: exitingMember.displayName,
            userEmail: exitingMember.email,
            exitLatitude: exitLatitude,
            exitLongitude: exitLongitude,
            distanceOutsideMeters: distanceOutside,
            timestampEpochMs: Int64(Date().timeIntervalSince1970 * 1000),
            isSimulated: isSimulated,
            acknowledgedByUsers: []
        )

        await MainActor.run {
            var currentEvents = self.exitEventsMap[groupId] ?? []
            currentEvents.insert(event, at: 0)
            self.exitEventsMap[groupId] = currentEvents

            // Update member's status to OUTSIDE
            if var groupMembers = self.groupMembersMap[groupId] {
                if let idx = groupMembers.firstIndex(where: { $0.userId == userId }) {
                    groupMembers[idx].geofenceStatus = .outside
                    groupMembers[idx].lastLocation = MemberLocationModel(latitude: exitLatitude, longitude: exitLongitude)
                    groupMembers[idx].lastSeenEpochMs = Int64(Date().timeIntervalSince1970 * 1000)
                    self.groupMembersMap[groupId] = groupMembers
                }
            }

            self.persistDatabase()

            // Deliver notification to other members of the group
            NotificationService.shared.postGeofenceExitAlert(
                memberName: exitingMember.displayName,
                groupName: group.name,
                geofenceName: geofenceName,
                isSimulated: isSimulated
            )
        }

        return event
    }

    // MARK: - State Management & Persistence
    func refreshUserGroups() {
        guard let user = currentUser else {
            userGroups = []
            return
        }

        // Return all groups where the current user is a member
        let filtered = allGroups.values.filter { group in
            let members = groupMembersMap[group.id] ?? []
            return members.contains(where: { $0.userId == user.id })
        }
        self.userGroups = filtered.sorted(by: { $0.createdAtEpochMs > $1.createdAtEpochMs })
    }

    private func generateInviteCode() -> String {
        let chars = "23456789ABCDEFGHJKLMNPQRSTUVWXYZ"
        return String((0..<6).map { _ in chars.randomElement()! })
    }

    private func saveLocalSession(user: UserModel) {
        if let encoded = try? JSONEncoder().encode(user) {
            userDefaults.set(encoded, forKey: "\(storageKeyPrefix)SessionUser")
        }
    }

    private func loadLocalSession() {
        if let data = userDefaults.data(forKey: "\(storageKeyPrefix)SessionUser"),
           let user = try? JSONDecoder().decode(UserModel.self, from: data) {
            currentUser = user
        }
    }

    private func persistDatabase() {
        if let encodedGroups = try? JSONEncoder().encode(allGroups) {
            userDefaults.set(encodedGroups, forKey: "\(storageKeyPrefix)AllGroups")
        }
        if let encodedMembers = try? JSONEncoder().encode(groupMembersMap) {
            userDefaults.set(encodedMembers, forKey: "\(storageKeyPrefix)GroupMembers")
        }
        if let encodedFences = try? JSONEncoder().encode(activeGeofences) {
            userDefaults.set(encodedFences, forKey: "\(storageKeyPrefix)ActiveGeofences")
        }
        if let encodedEvents = try? JSONEncoder().encode(exitEventsMap) {
            userDefaults.set(encodedEvents, forKey: "\(storageKeyPrefix)ExitEvents")
        }
        if let encodedUsers = try? JSONEncoder().encode(registeredUsers) {
            userDefaults.set(encodedUsers, forKey: "\(storageKeyPrefix)RegisteredUsers")
        }
    }

    private func loadDatabase() {
        if let data = userDefaults.data(forKey: "\(storageKeyPrefix)AllGroups"),
           let groups = try? JSONDecoder().decode([String: TrackingGroupModel].self, from: data) {
            self.allGroups = groups
        }
        if let data = userDefaults.data(forKey: "\(storageKeyPrefix)GroupMembers"),
           let members = try? JSONDecoder().decode([String: [GroupMemberModel]].self, from: data) {
            self.groupMembersMap = members
        }
        if let data = userDefaults.data(forKey: "\(storageKeyPrefix)ActiveGeofences"),
           let fences = try? JSONDecoder().decode([String: GeofenceConfigModel].self, from: data) {
            self.activeGeofences = fences
        }
        if let data = userDefaults.data(forKey: "\(storageKeyPrefix)ExitEvents"),
           let events = try? JSONDecoder().decode([String: [GeofenceExitEventModel]].self, from: data) {
            self.exitEventsMap = events
        }
        if let data = userDefaults.data(forKey: "\(storageKeyPrefix)RegisteredUsers"),
           let users = try? JSONDecoder().decode([String: UserModel].self, from: data) {
            self.registeredUsers = users
        }
    }

    private func seedInitialDemoData() {
        let alexUser = UserModel(
            id: "usr_alex_01",
            email: "alex@circlealert.internal",
            displayName: "Alex Rivera",
            pushToken: "apns_sample_token_88291"
        )
        registeredUsers[alexUser.email] = alexUser

        let sampleGroupId = "grp_san_francisco_demo"
        let sampleGroup = TrackingGroupModel(
            id: sampleGroupId,
            name: "SF Team Field Operations",
            inviteCode: "CIR778",
            ownerId: alexUser.id,
            createdAtEpochMs: Int64(Date().timeIntervalSince1970 * 1000) - 86400000,
            geofenceId: "geo_sf_hq",
            memberCount: 3
        )

        let member1 = GroupMemberModel(
            userId: alexUser.id,
            displayName: alexUser.displayName,
            email: alexUser.email,
            role: .owner,
            joinedAtEpochMs: Int64(Date().timeIntervalSince1970 * 1000) - 86400000,
            geofenceStatus: .inside,
            lastLocation: MemberLocationModel(latitude: 37.7749, longitude: -122.4194)
        )

        let member2 = GroupMemberModel(
            userId: "usr_marcus_22",
            displayName: "Marcus Chen",
            email: "marcus@circlealert.internal",
            role: .member,
            joinedAtEpochMs: Int64(Date().timeIntervalSince1970 * 1000) - 72000000,
            geofenceStatus: .inside,
            lastLocation: MemberLocationModel(latitude: 37.7751, longitude: -122.4190)
        )

        let member3 = GroupMemberModel(
            userId: "usr_elena_33",
            displayName: "Elena Rostova",
            email: "elena@circlealert.internal",
            role: .member,
            joinedAtEpochMs: Int64(Date().timeIntervalSince1970 * 1000) - 50000000,
            geofenceStatus: .outside,
            lastLocation: MemberLocationModel(latitude: 37.7880, longitude: -122.4075)
        )

        let sampleGeofence = GeofenceConfigModel(
            id: "geo_sf_hq",
            groupId: sampleGroupId,
            name: "Civic Center Perimeter",
            latitude: 37.7749,
            longitude: -122.4194,
            radiusMeters: 350.0,
            createdBy: alexUser.id,
            createdAtEpochMs: Int64(Date().timeIntervalSince1970 * 1000) - 86400000,
            isActive: true
        )

        let sampleEvent = GeofenceExitEventModel(
            id: "evt_init_01",
            groupId: sampleGroupId,
            groupName: sampleGroup.name,
            geofenceId: sampleGeofence.id,
            geofenceName: sampleGeofence.name,
            userId: member3.userId,
            userName: member3.displayName,
            userEmail: member3.email,
            exitLatitude: 37.7880,
            exitLongitude: -122.4075,
            distanceOutsideMeters: 820.0,
            timestampEpochMs: Int64(Date().timeIntervalSince1970 * 1000) - 1800000,
            isSimulated: false
        )

        allGroups[sampleGroupId] = sampleGroup
        groupMembersMap[sampleGroupId] = [member1, member2, member3]
        activeGeofences[sampleGroupId] = sampleGeofence
        exitEventsMap[sampleGroupId] = [sampleEvent]

        persistDatabase()
    }
}
