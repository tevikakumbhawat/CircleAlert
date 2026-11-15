import SwiftUI
import MapKit
import CoreLocation

struct GeofenceSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: GeofenceSetupViewModel
    @State private var cameraPosition: MapCameraPosition = .automatic

    init(groupId: String, existingGeofence: GeofenceConfigModel? = nil) {
        _viewModel = StateObject(wrappedValue: GeofenceSetupViewModel(groupId: groupId, existingGeofence: existingGeofence))
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                // Interactive MapKit Map
                MapReader { proxy in
                    Map(position: $cameraPosition) {
                        Marker(viewModel.name, coordinate: viewModel.selectedCoordinate)
                            .tint(.blue)

                        MapCircle(center: viewModel.selectedCoordinate, radius: viewModel.radiusMeters)
                            .foregroundStyle(Color.blue.opacity(0.2))
                            .stroke(Color.blue, lineWidth: 2)
                    }
                    .mapControls {
                        MapCompass()
                        MapScaleView()
                        MapPitchToggle()
                    }
                    .onTapGesture { screenCoord in
                        if let coordinate = proxy.convert(screenCoord, from: .local) {
                            withAnimation(.spring()) {
                                viewModel.selectedCoordinate = coordinate
                            }
                        }
                    }
                }
                .ignoresSafeArea()

                // Configuration Floating Bottom Sheet
                VStack(spacing: 16) {
                    // Grabber indicator
                    Capsule()
                        .fill(Color.secondary.opacity(0.3))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Text("Configure Geofence Perimeter")
                                .font(.headline)
                                .fontWeight(.bold)

                            Spacer()

                            // Current Location button
                            Button(action: centerOnCurrentLocation) {
                                Image(systemName: "location.fill")
                                    .padding(8)
                                    .background(Color.blue.opacity(0.12))
                                    .foregroundColor(.blue)
                                    .clipShape(Circle())
                            }
                        }

                        CustomTextField(
                            title: "Perimeter Name (e.g. SF Headquarters)",
                            icon: "tag.fill",
                            text: $viewModel.name
                        )

                        // Radius Slider & Quick Presets
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Radius:")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)

                                Text("\(Int(viewModel.radiusMeters)) meters")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.blue)

                                Spacer()

                                Text("(Tap map to reposition center)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            Slider(
                                value: $viewModel.radiusMeters,
                                in: 50...1000,
                                step: 25
                            )
                            .tint(.blue)

                            // Quick radius preset chips
                            HStack(spacing: 8) {
                                ForEach([100.0, 250.0, 500.0, 1000.0], id: \.self) { radius in
                                    Button(action: {
                                        withAnimation {
                                            viewModel.radiusMeters = radius
                                            cameraPosition = .region(MKCoordinateRegion(
                                                center: viewModel.selectedCoordinate,
                                                latitudinalMeters: radius * 3,
                                                longitudinalMeters: radius * 3
                                            ))
                                        }
                                    }) {
                                        Text("\(Int(radius))m")
                                            .font(.caption)
                                            .fontWeight(.semibold)
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 5)
                                            .background(viewModel.radiusMeters == radius ? Color.blue : Color(uiColor: .tertiarySystemGroupedBackground))
                                            .foregroundColor(viewModel.radiusMeters == radius ? .white : .primary)
                                            .cornerRadius(8)
                                    }
                                }
                            }
                        }

                        if let error = viewModel.errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }

                        PrimaryButton(
                            title: "Save & Activate Geofence",
                            icon: "checkmark.shield.fill",
                            isLoading: viewModel.isLoading
                        ) {
                            Task {
                                await viewModel.saveGeofence()
                                if viewModel.isSaved {
                                    dismiss()
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                }
                .background(Color(uiColor: .secondarySystemGroupedBackground))
                .cornerRadius(24)
                .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: -4)
            }
            .navigationTitle("Geofence Setup")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                cameraPosition = .region(MKCoordinateRegion(
                    center: viewModel.selectedCoordinate,
                    latitudinalMeters: viewModel.radiusMeters * 3,
                    longitudinalMeters: viewModel.radiusMeters * 3
                ))
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func centerOnCurrentLocation() {
        if let current = LocationManager.shared.currentLocation {
            withAnimation(.easeInOut) {
                viewModel.selectedCoordinate = current.coordinate
                cameraPosition = .region(MKCoordinateRegion(
                    center: current.coordinate,
                    latitudinalMeters: viewModel.radiusMeters * 3,
                    longitudinalMeters: viewModel.radiusMeters * 3
                ))
            }
        }
    }
}
