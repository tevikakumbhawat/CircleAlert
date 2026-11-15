import Foundation
import Combine

final class ActivityAlertsViewModel: ObservableObject {
    @Published var allEvents: [GeofenceExitEventModel] = []
    @Published var filterBySimulated: Bool = false
    @Published var selectedGroupId: String? = nil

    private var cancellables = Set<AnyCancellable>()
    private let firebaseService = FirebaseService.shared

    init() {
        firebaseService.$exitEventsMap
            .receive(on: DispatchQueue.main)
            .sink { [weak self] map in
                self?.allEvents = map.values.flatMap { $0 }.sorted(by: { $0.timestampEpochMs > $1.timestampEpochMs })
            }
            .store(in: &cancellables)
    }

    var filteredEvents: [GeofenceExitEventModel] {
        allEvents.filter { event in
            if filterBySimulated && !event.isSimulated {
                return false
            }
            if let groupId = selectedGroupId, event.groupId != groupId {
                return false
            }
            return true
        }
    }
}
