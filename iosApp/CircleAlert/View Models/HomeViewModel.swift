import Foundation
import Combine

final class HomeViewModel: ObservableObject {
    @Published var groups: [TrackingGroupModel] = []
    @Published var recentAlertsCount: Int = 0
    @Published var activeFencesCount: Int = 0
    @Published var showCreateSheet: Bool = false
    @Published var showJoinSheet: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private let firebaseService = FirebaseService.shared

    init() {
        firebaseService.$userGroups
            .receive(on: DispatchQueue.main)
            .sink { [weak self] groups in
                self?.groups = groups
            }
            .store(in: &cancellables)

        firebaseService.$exitEventsMap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] map in
                self?.recentAlertsCount = map.values.flatMap { $0 }.count
            }
            .store(in: &cancellables)

        firebaseService.$activeGeofences
            .receive(on: DispatchQueue.main)
            .sink { [weak self] fences in
                self?.activeFencesCount = fences.count
            }
            .store(in: &cancellables)
    }

    func memberCount(for group: TrackingGroupModel) -> Int {
        firebaseService.groupMembersMap[group.id]?.count ?? group.memberCount
    }

    func hasGeofence(for group: TrackingGroupModel) -> Bool {
        firebaseService.activeGeofences[group.id] != nil
    }
}
