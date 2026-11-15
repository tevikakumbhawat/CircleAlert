import SwiftUI

struct HomeDashboardView: View {
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var firebaseService = FirebaseService.shared
    @State private var selectedGroup: TrackingGroupModel?

    var body: some View {
        NavigationStack {
            ZStack {
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // User Profile & Status Card
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.blue.gradient)
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(firebaseService.currentUser?.displayName.prefix(1) ?? "U"))
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                )

                            VStack(alignment: .leading, spacing: 3) {
                                Text(firebaseService.currentUser?.displayName ?? "User")
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Text(firebaseService.currentUser?.email ?? "")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            // Status badge
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 8, height: 8)
                                Text("Active")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .padding(16)
                        .background(Color(uiColor: .secondarySystemGroupedBackground))
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)

                        // Quick Stats Row
                        HStack(spacing: 12) {
                            StatCard(
                                title: "Tracking Groups",
                                value: "\(viewModel.groups.count)",
                                icon: "person.3.fill",
                                color: .blue
                            )

                            StatCard(
                                title: "Active Geofences",
                                value: "\(viewModel.activeFencesCount)",
                                icon: "shield.checkered",
                                color: .indigo
                            )

                            StatCard(
                                title: "Exit Alerts",
                                value: "\(viewModel.recentAlertsCount)",
                                icon: "exclamationmark.triangle.fill",
                                color: .orange
                            )
                        }

                        // Action Buttons: Create & Join Group
                        HStack(spacing: 12) {
                            Button(action: { viewModel.showCreateSheet = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Create Group")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(color: Color.blue.opacity(0.2), radius: 4, x: 0, y: 2)
                            }

                            Button(action: { viewModel.showJoinSheet = true }) {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 16, weight: .semibold))
                                    Text("Join Group")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 48)
                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                                .foregroundColor(.blue)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.blue.opacity(0.4), lineWidth: 1)
                                )
                            }
                        }

                        // Tracking Groups Section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Your Tracking Groups")
                                    .font(.headline)
                                    .fontWeight(.bold)

                                Spacer()

                                Text("\(viewModel.groups.count) total")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            if viewModel.groups.isEmpty {
                                EmptyStateCard(
                                    icon: "person.3.sequence.fill",
                                    title: "No Tracking Groups Yet",
                                    message: "Create a tracking group or join one using an invitation code.",
                                    actionTitle: "Create First Group"
                                ) {
                                    viewModel.showCreateSheet = true
                                }
                            } else {
                                ForEach(viewModel.groups) { group in
                                    NavigationLink(destination: GroupDetailView(group: group)) {
                                        GroupRowCard(
                                            group: group,
                                            memberCount: viewModel.memberCount(for: group),
                                            hasGeofence: viewModel.hasGeofence(for: group)
                                        )
                                    }
                                    .buttonStyle(PlainButtonStyle())
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(16)
                }
            }
            .navigationTitle("CircleAlert")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $viewModel.showCreateSheet) {
                CreateGroupView()
            }
            .sheet(isPresented: $viewModel.showJoinSheet) {
                JoinGroupView()
            }
        }
    }
}

// MARK: - Subcomponents
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.primary)

            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.02), radius: 4, x: 0, y: 1)
    }
}

struct GroupRowCard: View {
    let group: TrackingGroupModel
    let memberCount: Int
    let hasGeofence: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.blue.opacity(0.12))
                    .frame(width: 48, height: 48)

                Image(systemName: "location.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)

                HStack(spacing: 8) {
                    Label("\(memberCount) members", systemImage: "person.2.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("•")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack(spacing: 3) {
                        Image(systemName: "key.fill")
                        Text(group.inviteCode)
                    }
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.blue)
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if hasGeofence {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption2)
                        Text("Active Fence")
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.green.opacity(0.12))
                    .clipShape(Capsule())
                } else {
                    Text("No Fence")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.gray.opacity(0.12))
                        .clipShape(Capsule())
                }

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .padding(14)
        .background(Color(uiColor: .secondarySystemGroupedBackground))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 2)
    }
}
