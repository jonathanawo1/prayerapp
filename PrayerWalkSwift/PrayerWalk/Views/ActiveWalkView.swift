// ActiveWalkView.swift
// PrayerWalk

import SwiftUI
import MapKit

struct ActiveWalkView: View {
    let locationService: LocationService
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var walksVM: WalksViewModel

    @StateObject private var walkVM: ActiveWalkViewModel
    @Environment(\.dismiss) var dismiss

    @State private var walkDraft: WalkDraft?
    @State private var showSummary: Bool = false

    init(locationService: LocationService) {
        self.locationService = locationService
        _walkVM = StateObject(wrappedValue: ActiveWalkViewModel(locationService: locationService))
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top stats
                VStack(spacing: 4) {
                    Text(formatDuration(Int(walkVM.duration)))
                        .font(.system(size: 52, weight: .bold, design: .monospaced))
                        .foregroundColor(.appTextPrimary)
                        .padding(.top, 16)

                    HStack(spacing: 32) {
                        VStack(spacing: 2) {
                            Text(formatDistance(walkVM.distance))
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                            Text("Distance")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }

                        VStack(spacing: 2) {
                            Text(formatPace(distanceMeters: walkVM.distance, durationSeconds: Int(walkVM.duration)))
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                            Text("Pace")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }

                        VStack(spacing: 2) {
                            Text("\(walkVM.path.count)")
                                .font(.system(size: 20, weight: .semibold, design: .rounded))
                                .foregroundColor(.appTextPrimary)
                            Text("Points")
                                .font(.caption)
                                .foregroundColor(.appTextSecondary)
                        }
                    }
                    .padding(.bottom, 12)

                    if walkVM.isPaused {
                        Label("Paused", systemImage: "pause.fill")
                            .font(.caption.bold())
                            .foregroundColor(.appWarning)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(Color.appWarning.opacity(0.15))
                            .clipShape(Capsule())
                            .padding(.bottom, 8)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(Color.appSurface)

                // Live map
                LiveRouteMapView(path: walkVM.path, locationService: locationService)
                    .ignoresSafeArea(edges: .horizontal)

                // Controls
                HStack(spacing: 20) {
                    // Pause / Resume
                    Button {
                        if walkVM.isPaused {
                            walkVM.resumeWalk()
                        } else {
                            walkVM.pauseWalk()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(Color.appSurface)
                                .frame(width: 64, height: 64)
                            Image(systemName: walkVM.isPaused ? "play.fill" : "pause.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.appTextPrimary)
                        }
                    }

                    // End Walk
                    Button {
                        let draft = walkVM.endWalk()
                        walkDraft = draft
                        showSummary = true
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.appPrimary)
                                .frame(height: 64)
                            Label("End Walk", systemImage: "stop.fill")
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .background(Color.appSurface)
            }
        }
        .onAppear {
            walkVM.startWalk()
        }
        .sheet(isPresented: $showSummary, onDismiss: {
            dismiss()
        }) {
            if let draft = walkDraft {
                WalkSummaryView(draft: draft, onDismiss: { dismiss() })
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Live Route Map

struct LiveRouteMapView: UIViewRepresentable {
    let path: [WalkCoordinate]
    let locationService: LocationService

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        mapView.overrideUserInterfaceStyle = .dark
        mapView.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        guard path.count >= 2 else { return }
        let coords = path.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        polyline.title = "current"
        mapView.addOverlay(polyline, level: .aboveRoads)
    }

    func makeCoordinator() -> LiveMapCoordinator { LiveMapCoordinator() }
}

final class LiveMapCoordinator: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = UIColor.appPrimary
        renderer.lineWidth = 4
        renderer.lineCap = .round
        renderer.lineJoin = .round
        return renderer
    }
}
