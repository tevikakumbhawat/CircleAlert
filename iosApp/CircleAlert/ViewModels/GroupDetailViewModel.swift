import Foundation
import Combine
import CoreLocation

final class GroupDetailViewModel: ObservableObject {
    @Published var group: TrackingGroupModel
    @Published var members: [GroupMemberModel] = []
    @Published var geofence: GeofenceConfigModel?
    @Published var recentEvents: [GeofenceExitEventModel] = []
    @Published var showGeofenceSetup: Bool = false
    @Published var showSimulationSuccessBanner: Bool = false
    @Published var simulationBannerMessage: String = ""
    @Published var isSimulating: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let firebaseService = FirebaseService.shared

    init(group: TrackingGroupModel) {
        self.group = group
        observeGroupData()
    }

    private func observeGroupData() {
        firebaseService.$groupMembersMap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] map in
                guard let self = self else { return }
                self.members = map[self.group.id] ?? []
            }
            .store(in: &cancellables)

        firebaseService.$activeGeofences
            .receive(on: DispatchQueue.main)
            .sink { [weak self] map in
                guard let self = self else { return }
                self.geofence = map[self.group.id]
            }
            .store(in: &cancellables)

        firebaseService.$exitEventsMap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] map in
                guard let self = self else { return }
                self.recentEvents = map[self.group.id] ?? []
            }
            .store(in: &cancellables)
    }

    /// Triggers the DEBUG-only geofence exit simulation.
    /// Simulates a group member crossing the boundary and triggers the exact CoreLocation exit pipeline.
    func simulateExit(for member: GroupMemberModel) async {
        guard let geo = geofence else {
            await MainActor.run {
                self.simulationBannerMessage = "Please configure a geofence before running simulation."
                self.showSimulationSuccessBanner = true
            }
            return
        }

        await MainActor.run {
            self.isSimulating = true
        }

        let exitCoord = GeofenceSimulator.shared.generateSimulatedExitCoordinate(
            centerLat: geo.latitude,
            centerLon: geo.longitude,
            radiusMeters: geo.radiusMeters,
            offsetMeters: 180.0
        )

        do {
            let event = try await firebaseService.recordExitEvent(
                groupId: group.id,
                userId: member.userId,
                exitLatitude: exitCoord.latitude,
                exitLongitude: exitCoord.longitude,
                isSimulated: true
            )

            await MainActor.run {
                self.simulationBannerMessage = "Simulated Exit Triggered! \(event.userName) crossed '\(event.geofenceName)'. Alert sent to other group members."
                self.showSimulationSuccessBanner = true
                self.isSimulating = false
            }
        } catch {
            await MainActor.run {
                self.simulationBannerMessage = "Simulation failed: \(error.localizedDescription)"
                self.showSimulationSuccessBanner = true
                self.isSimulating = false
            }
        }
    }
}
