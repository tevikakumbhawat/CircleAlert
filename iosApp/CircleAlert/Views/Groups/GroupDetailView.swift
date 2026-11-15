import SwiftUI
import MapKit

struct GroupDetailView: View {
    @StateObject private var viewModel: GroupDetailViewModel

    init(group: TrackingGroupModel) {
        _viewModel = StateObject(wrappedValue: GroupDetailViewModel(group: group))
    }

    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    // Simulation Feedback Banner
                    if viewModel.showSimulationSuccessBanner {
                        HStack(spacing: 10) {
                            Image(systemName: "bolt.badge.clock.fill")
                                .foregroundColor(.orange)
                            Text(viewModel.simulationBannerMessage)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            Spacer()
                            Button(action: { viewModel.showSimulationSuccessBanner = false }) {
                                Image(systemName: "xmark")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(12)
                        .background(Color.orange.opacity(0.15))
                        .cornerRadius(12)
                        .transition(.move(edge: .top).combined(with: .opacity))
                    }

                    // Group Header Card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(viewModel.group.name)
                                    .font(.title2)
                                    .fontWeight(.bold)

                                Text("Tracking Group")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // Invite Code Badge
                            Button(action: {
                                UIPasteboard.general.string = viewModel.group.inviteCode
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: "key.fill")
                                    Text(viewModel.group.inviteCode)
                                        .fontWeight(.bold)
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption2)
                                }
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.blue.opacity(0.12))
                                .foregroundColor(.blue)
                                .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)

                    // Geofence Association Card
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label("Geofenced Safe Zone", systemImage: "shield.checkered")
                                .font(.headline)
                                .foregroundColor(.primary)

                            Spacer()

                            Button(action: { viewModel.showGeofenceSetup = true }) {
                                Text(viewModel.geofence == nil ? "Set Up" : "Edit")
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }

                        if let fence = viewModel.geofence {
                            VStack(spacing: 12) {
                                HStack(spacing: 12) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.blue.opacity(0.12))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "mappin.circle.fill")
                                            .font(.title3)
                                            .foregroundColor(.blue)
                                    }

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(fence.name)
                                            .font(.subheadline)
                                            .fontWeight(.semibold)

                                        Text("Radius: \(Int(fence.radiusMeters))m • Active Boundary")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    Text("MONITORED")
                                        .font(.system(size: 9, weight: .bold))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 3)
                                        .background(Color.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .cornerRadius(4)
                                }

                                // Interactive mini-map preview
                                Map(initialPosition: .region(MKCoordinateRegion(
                                    center: fence.coordinate,
                                    latitudinalMeters: fence.radiusMeters * 3,
                                    longitudinalMeters: fence.radiusMeters * 3
                                ))) {
                                    Marker(fence.name, coordinate: fence.coordinate)
                                        .tint(.blue)

                                    MapCircle(center: fence.coordinate, radius: fence.radiusMeters)
                                        .foregroundStyle(Color.blue.opacity(0.2))
                                        .stroke(Color.blue, lineWidth: 2)
                                }
                                .frame(height: 140)
                                .cornerRadius(12)
                                .disabled(true) // preview only
                            }
                        } else {
                            VStack(spacing: 8) {
                                Text("No geofence perimeter associated.")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Button(action: { viewModel.showGeofenceSetup = true }) {
                                    Label("Configure Perimeter Map", systemImage: "plus.circle.fill")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundColor(.blue)
                                }
                                .padding(.top, 4)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)

                    // Members List Section
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Group Members")
                                .font(.headline)
                                .fontWeight(.bold)

                            Spacer()

                            Text("\(viewModel.members.count) members")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        ForEach(viewModel.members) { member in
                            VStack(spacing: 10) {
                                HStack(spacing: 12) {
                                    Circle()
                                        .fill(Color.gray.opacity(0.2))
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Text(String(member.displayName.prefix(1)))
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                        )

                                    VStack(alignment: .leading, spacing: 2) {
                                        HStack(spacing: 6) {
                                            Text(member.displayName)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)

                                            if member.role == .owner {
                                                Text("CREATOR")
                                                    .font(.system(size: 8, weight: .bold))
                                                    .padding(.horizontal, 5)
                                                    .padding(.vertical, 2)
                                                    .background(Color.blue.opacity(0.12))
                                                    .foregroundColor(.blue)
                                                    .cornerRadius(4)
                                            }
                                        }

                                        Text(member.email)
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }

                                    Spacer()

                                    StatusPillView(status: member.geofenceStatus)
                                }

                                // Simulator action button (DEBUG testing requirement)
                                HStack {
                                    Text("Simulate boundary exit:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)

                                    Spacer()

                                    Button(action: {
                                        Task {
                                            await viewModel.simulateExit(for: member)
                                        }
                                    }) {
                                        HStack(spacing: 4) {
                                            Image(systemName: "arrow.up.right.circle.fill")
                                            Text("Trigger Exit")
                                        }
                                        .font(.caption)
                                        .fontWeight(.semibold)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 5)
                                        .background(Color.orange.opacity(0.15))
                                        .foregroundColor(.orange)
                                        .cornerRadius(8)
                                    }
                                    .disabled(viewModel.isSimulating)
                                }
                                .padding(.top, 2)
                            }
                            .padding(12)
                            .background(Color(uiColor: .tertiarySystemGroupedBackground))
                            .cornerRadius(12)
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)

                    // Recent Exit Events Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Recent Exit Events")
                            .font(.headline)
                            .fontWeight(.bold)

                        if viewModel.recentEvents.isEmpty {
                            Text("No exit events recorded for this group yet.")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.vertical, 8)
                        } else {
                            ForEach(viewModel.recentEvents) { event in
                                ExitEventCard(event: event)
                            }
                        }
                    }
                    .padding(16)
                    .background(Color(uiColor: .secondarySystemGroupedBackground))
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
                }
                .padding(16)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $viewModel.showGeofenceSetup) {
            GeofenceSetupView(
                groupId: viewModel.group.id,
                existingGeofence: viewModel.geofence
            )
        }
    }
}

struct ExitEventCard: View {
    let event: GeofenceExitEventModel

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.red.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.red)
                    .font(.subheadline)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.userName)
                        .font(.subheadline)
                        .fontWeight(.semibold)

                    Spacer()

                    if event.isSimulated {
                        Text("SIMULATED")
                            .font(.system(size: 8, weight: .bold))
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.15))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }

                Text("Exited '\(event.geofenceName)' (\(Int(event.distanceOutsideMeters))m outside)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text(event.formattedDate)
                    .font(.caption2)
                    .foregroundColor(.secondary.opacity(0.8))
            }
        }
        .padding(12)
        .background(Color(uiColor: .tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
