import Foundation
import CoreLocation

// MARK: - User Model
public struct UserModel: Identifiable, Codable, Equatable {
    public let id: String
    public let email: String
    public let displayName: String
    public let photoUrl: String?
    public let pushToken: String?
    public let createdAtEpochMs: Int64

    public init(
        id: String,
        email: String,
        displayName: String,
        photoUrl: String? = nil,
        pushToken: String? = nil,
        createdAtEpochMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.photoUrl = photoUrl
        self.pushToken = pushToken
        self.createdAtEpochMs = createdAtEpochMs
    }
}

// MARK: - Member Status & Role
public enum MemberRoleModel: String, Codable, CaseIterable {
    case owner = "OWNER"
    case admin = "ADMIN"
    case member = "MEMBER"
}

public enum MemberGeofenceStatusModel: String, Codable, CaseIterable {
    case inside = "INSIDE"
    case outside = "OUTSIDE"
    case unknown = "UNKNOWN"

    public var title: String {
        switch self {
        case .inside: return "Inside Safe Zone"
        case .outside: return "Outside Zone!"
        case .unknown: return "Status Pending"
        }
    }
}

public struct MemberLocationModel: Codable, Equatable {
    public let latitude: Double
    public let longitude: Double
    public let accuracy: Double
    public let timestampEpochMs: Int64

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public init(latitude: Double, longitude: Double, accuracy: Double = 5.0, timestampEpochMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000)) {
        self.latitude = latitude
        self.longitude = longitude
        self.accuracy = accuracy
        self.timestampEpochMs = timestampEpochMs
    }
}

public struct GroupMemberModel: Identifiable, Codable, Equatable {
    public var id: String { userId }
    public let userId: String
    public let displayName: String
    public let email: String
    public let role: MemberRoleModel
    public let joinedAtEpochMs: Int64
    public var geofenceStatus: MemberGeofenceStatusModel
    public var lastLocation: MemberLocationModel?
    public var lastSeenEpochMs: Int64
    public var pushToken: String?

    public init(
        userId: String,
        displayName: String,
        email: String,
        role: MemberRoleModel = .member,
        joinedAtEpochMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        geofenceStatus: MemberGeofenceStatusModel = .unknown,
        lastLocation: MemberLocationModel? = nil,
        lastSeenEpochMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        pushToken: String? = nil
    ) {
        self.userId = userId
        self.displayName = displayName
        self.email = email
        self.role = role
        self.joinedAtEpochMs = joinedAtEpochMs
        self.geofenceStatus = geofenceStatus
        self.lastLocation = lastLocation
        self.lastSeenEpochMs = lastSeenEpochMs
        self.pushToken = pushToken
    }
}

// MARK: - Tracking Group Model
public struct TrackingGroupModel: Identifiable, Codable, Equatable {
    public let id: String
    public var name: String
    public let inviteCode: String
    public let ownerId: String
    public let createdAtEpochMs: Int64
    public var geofenceId: String?
    public var memberCount: Int

    public init(
        id: String,
        name: String,
        inviteCode: String,
        ownerId: String,
        createdAtEpochMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        geofenceId: String? = nil,
        memberCount: Int = 1
    ) {
        self.id = id
        self.name = name
        self.inviteCode = inviteCode
        self.ownerId = ownerId
        self.createdAtEpochMs = createdAtEpochMs
        self.geofenceId = geofenceId
        self.memberCount = memberCount
    }
}

// MARK: - Geofence Configuration Model
public struct GeofenceConfigModel: Identifiable, Codable, Equatable {
    public let id: String
    public let groupId: String
    public var name: String
    public var latitude: Double
    public var longitude: Double
    public var radiusMeters: Double
    public let createdBy: String
    public let createdAtEpochMs: Int64
    public var isActive: Bool

    public var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }

    public init(
        id: String,
        groupId: String,
        name: String,
        latitude: Double,
        longitude: Double,
        radiusMeters: Double,
        createdBy: String,
        createdAtEpochMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        isActive: Bool = true
    ) {
        self.id = id
        self.groupId = groupId
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.radiusMeters = radiusMeters
        self.createdBy = createdBy
        self.createdAtEpochMs = createdAtEpochMs
        self.isActive = isActive
    }
}

// MARK: - Geofence Exit Event Model
public struct GeofenceExitEventModel: Identifiable, Codable, Equatable {
    public let id: String
    public let groupId: String
    public let groupName: String
    public let geofenceId: String
    public let geofenceName: String
    public let userId: String
    public let userName: String
    public let userEmail: String
    public let exitLatitude: Double
    public let exitLongitude: Double
    public let distanceOutsideMeters: Double
    public let timestampEpochMs: Int64
    public let isSimulated: Bool
    public var acknowledgedByUsers: [String]

    public var exitCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: exitLatitude, longitude: exitLongitude)
    }

    public var formattedDate: String {
        let date = Date(timeIntervalSince1970: Double(timestampEpochMs) / 1000.0)
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }

    public init(
        id: String,
        groupId: String,
        groupName: String,
        geofenceId: String,
        geofenceName: String,
        userId: String,
        userName: String,
        userEmail: String,
        exitLatitude: Double,
        exitLongitude: Double,
        distanceOutsideMeters: Double = 0.0,
        timestampEpochMs: Int64 = Int64(Date().timeIntervalSince1970 * 1000),
        isSimulated: Bool = false,
        acknowledgedByUsers: [String] = []
    ) {
        self.id = id
        self.groupId = groupId
        self.groupName = groupName
        self.geofenceId = geofenceId
        self.geofenceName = geofenceName
        self.userId = userId
        self.userName = userName
        self.userEmail = userEmail
        self.exitLatitude = exitLatitude
        self.exitLongitude = exitLongitude
        self.distanceOutsideMeters = distanceOutsideMeters
        self.timestampEpochMs = timestampEpochMs
        self.isSimulated = isSimulated
        self.acknowledgedByUsers = acknowledgedByUsers
    }
}
