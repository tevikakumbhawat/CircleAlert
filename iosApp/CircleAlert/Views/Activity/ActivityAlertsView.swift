import SwiftUI

struct ActivityAlertsView: View {
    @StateObject private var viewModel = ActivityAlertsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 16) {
                        // Filter Segment
                        Picker("Filter", selection: $viewModel.filterBySimulated) {
                            Text("All Alerts (\(viewModel.allEvents.count))").tag(false)
                            Text("Simulated (\(viewModel.allEvents.filter { $0.isSimulated }.count))").tag(true)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                        if viewModel.filteredEvents.isEmpty {
                            EmptyStateCard(
                                icon: "bell.slash.fill",
                                title: "No Alerts Recorded",
                                message: "When a member leaves a configured geofence perimeter, notifications and exit logs will appear here in real time."
                            )
                            .padding(.horizontal, 16)
                            .padding(.top, 20)
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(viewModel.filteredEvents) { event in
                                    ActivityAlertCard(event: event)
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .navigationTitle("Activity & Alerts")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct ActivityAlertCard: View {
    let event: GeofenceExitEventModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.12))
                        .frame(width: 42, height: 42)
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(event.userName)
                            .font(.headline)
                            .fontWeight(.bold)

                        Spacer()

                        if event.isSimulated {
                            Text("SIMULATED")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.orange.opacity(0.15))
                                .foregroundColor(.orange)
                                .cornerRadius(5)
                        } else {
                            Text("REAL CORELOCATION")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 3)
                                .background(Color.green.opacity(0.15))
                                .foregroundColor(.green)
                                .cornerRadius(5)
                        }
                    }

                    Text("Group: \(event.groupName)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            HStack(spacing: 16) {
                Label("\(Int(event.distanceOutsideMeters))m outside", systemImage: "arrow.triangle.pull")
                    .font(.caption)
                    .foregroundColor(.red)

                Label(event.geofenceName, systemImage: "shield")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Label(event.formattedDate, systemImage: "clock")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}
