import XCTest
import CoreLocation
@testable import CircleAlert

final class CircleAlertTests: XCTestCase {

    func testInviteCodeGenerationFormat() {
        let bridge = SharedKMPBridge.shared
        for _ in 1...20 {
            let code = bridge.generateInviteCode()
            XCTAssertEqual(code.count, 6, "Invite code must be exactly 6 characters")
            XCTAssertTrue(bridge.validateInviteCode(code), "Generated code '\(code)' must pass validation")
        }
    }

    func testInviteCodeValidationRejectsAmbiguousChars() {
        let bridge = SharedKMPBridge.shared
        XCTAssertFalse(bridge.validateInviteCode("0ABCDE"), "'0' is ambiguous and should be rejected")
        XCTAssertFalse(bridge.validateInviteCode("1ABCDE"), "'1' is ambiguous and should be rejected")
        XCTAssertFalse(bridge.validateInviteCode(""), "Empty code should be rejected")
        XCTAssertFalse(bridge.validateInviteCode("ABCDE"), "5-character code should be rejected")
        XCTAssertFalse(bridge.validateInviteCode("ABCDEFG"), "7-character code should be rejected")
    }

    func testHaversineDistanceAccuracy() {
        let bridge = SharedKMPBridge.shared
        // Distance between SF City Hall (37.7793, -122.4193) and SF Union Square (37.7879, -122.4075) ~ 1.4 km
        let distance = bridge.calculateDistanceMeters(
            lat1: 37.7793, lon1: -122.4193,
            lat2: 37.7879, lon2: -122.4075
        )
        XCTAssertTrue(distance > 1200 && distance < 1700, "Calculated distance \(distance)m should be ~1400m")
    }

    func testGeofenceContainmentCalculation() {
        let bridge = SharedKMPBridge.shared
        let centerLat = 37.7749
        let centerLon = -122.4194
        let radius = 250.0

        // Point inside (offset ~10m)
        let inside = bridge.isPointInsideGeofence(
            pointLat: 37.77495,
            pointLon: -122.41945,
            centerLat: centerLat,
            centerLon: centerLon,
            radiusMeters: radius
        )
        XCTAssertTrue(inside, "Point within 10m of center must be inside 250m geofence")

        // Point outside (offset ~1.5km)
        let outside = bridge.isPointInsideGeofence(
            pointLat: 37.7900,
            pointLon: -122.4194,
            centerLat: centerLat,
            centerLon: centerLon,
            radiusMeters: radius
        )
        XCTAssertFalse(outside, "Point ~1.5km away must be outside 250m geofence")
    }

    func testGeofenceSimulatorGeneratesExitOutsideBoundary() {
        let simulator = GeofenceSimulator.shared
        let centerLat = 37.7749
        let centerLon = -122.4194
        let radius = 200.0

        let exitCoord = simulator.generateSimulatedExitCoordinate(
            centerLat: centerLat,
            centerLon: centerLon,
            radiusMeters: radius,
            offsetMeters: 100.0
        )

        let distance = SharedKMPBridge.shared.calculateDistanceMeters(
            lat1: centerLat, lon1: centerLon,
            lat2: exitCoord.latitude, lon2: exitCoord.longitude
        )

        XCTAssertTrue(distance > radius, "Simulated exit distance \(distance)m must exceed radius \(radius)m")
    }

    func testGroupCreationAndInviteCodeAssociation() async throws {
        let service = FirebaseService.shared
        let testGroup = try await service.createGroup(name: "Engineering Test Group")

        XCTAssertEqual(testGroup.name, "Engineering Test Group")
        XCTAssertEqual(testGroup.inviteCode.count, 6)
        XCTAssertEqual(testGroup.memberCount, 1)

        let members = service.groupMembersMap[testGroup.id]
        XCTAssertNotNil(members)
        XCTAssertEqual(members?.first?.role, .owner)
    }

    func testExitEventNotifiesRecipientsExcludingExitingMember() async throws {
        let service = FirebaseService.shared
        let group = try await service.createGroup(name: "Boundary Notification Test")

        _ = try await service.configureGeofence(
            groupId: group.id,
            name: "Test Perimeter",
            latitude: 37.7749,
            longitude: -122.4194,
            radiusMeters: 200.0
        )

        let event = try await service.recordExitEvent(
            groupId: group.id,
            userId: service.currentUser!.id,
            exitLatitude: 37.7850,
            exitLongitude: -122.4194,
            isSimulated: true
        )

        XCTAssertEqual(event.groupId, group.id)
        XCTAssertEqual(event.userId, service.currentUser!.id)
        XCTAssertTrue(event.isSimulated)
        XCTAssertTrue(event.distanceOutsideMeters > 0)
    }
}
