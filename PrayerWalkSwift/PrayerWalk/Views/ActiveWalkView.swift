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
    @State private var showSummary = false
    @State private var showEndConfirm = false
    @State private var pulsing = false

    init(locationService: LocationService) {
        self.locationService = locationService
        _walkVM = StateObject(wrappedValue: ActiveWalkViewModel(locationService: locationService))
    }

    var body: some View {
        ZStack {
            // Map takes full screen
            LiveRouteMapView(path: walkVM.path, locationService: locationService)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top stats panel (floating)
                VStack(spacing: 0) {
                    // Main metric: time
                    Text(formatDuration(Int(walkVM.duration)))
                        .font(.system(size: 58, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.appTextPrimary)
                        .contentTransition(.numericText())
                        .padding(.top, 60)

                    // Secondary metrics
                    HStack(spacing: 0) {
                        LiveStatCell(value: formatDistance(walkVM.distance), label: "KM")
                        LiveDivider()
                        LiveStatCell(
                            value: formatPace(distanceMeters: walkVM.distance, durationSeconds: Int(walkVM.duration)),
                            label: "PACE"
                        )
                        LiveDivider()
                        LiveStatCell(value: "\(walkVM.path.count)", label: "POINTS")
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20)

                    // Paused badge
                    if walkVM.isPaused {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.appWarning)
                                .frame(width: 8, height: 8)
                                .scaleEffect(pulsing ? 1.4 : 1.0)
                                .animation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true), value: pulsing)
                                .onAppear { pulsing = true }
                                .onDisappear { pulsing = false }
                            Text("PAUSED")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(Color.appWarning)
                                .tracking(1.5)
                        }
                        .padding(.bottom, 12)
                    } else {
                        // Recording indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.appPrimary)
                                .frame(width: 8, height: 8)
                                .scaleEffect(pulsing ? 1.4 : 1.0)
                                .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: pulsing)
                                .onAppear { pulsing = true }
                                .onDisappear { pulsing = false }
                            Text("RECORDING")
                                .font(.system(size: 11, weight: .black))
                                .foregroundStyle(Color.appPrimary)
                                .tracking(1.5)
                        }
                        .padding(.bottom, 12)
                    }
                }
                .frame(maxWidth: .infinity)
                .background(
                    LinearGradient(
                        colors: [Color(hex: "060D1A").opacity(0.95), Color(hex: "060D1A").opacity(0.0)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                Spacer()

                // Bottom controls panel
                VStack(spacing: 0) {
                    // Gradient fade up
                    LinearGradient(
                        colors: [Color(hex: "060D1A").opacity(0), Color(hex: "060D1A").opacity(0.95)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 60)

                    HStack(spacing: 20) {
                        // Pause / Resume
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                if walkVM.isPaused { walkVM.resumeWalk() } else { walkVM.pauseWalk() }
                            }
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.appSurface)
                                    .frame(width: 66, height: 66)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                                    )
                                Image(systemName: walkVM.isPaused ? "play.fill" : "pause.fill")
                                    .font(.system(size: 24, weight: .semibold))
                                    .foregroundStyle(Color.appTextPrimary)
                            }
                        }

                        // End Walk
                        Button {
                            showEndConfirm = true
                        } label: {
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FF6B35"), Color.appPrimary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 66)
                                    .shadow(color: Color.appPrimary.opacity(0.5), radius: 16, x: 0, y: 6)

                                HStack(spacing: 10) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 16, weight: .bold))
                                    Text("Finish")
                                        .font(.system(size: 18, weight: .black))
                                }
                                .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                    .background(Color(hex: "060D1A").opacity(0.95))
                }
            }
        }
        .onAppear { walkVM.startWalk() }
        .confirmationDialog(
            "End your walk?",
            isPresented: $showEndConfirm,
            titleVisibility: .visible
        ) {
            Button("Save Walk", role: .none) {
                let draft = walkVM.endWalk()
                walkDraft = draft
                showSummary = true
            }
            Button("Discard Walk", role: .destructive) {
                _ = walkVM.endWalk()
                dismiss()
            }
            Button("Keep Walking", role: .cancel) {}
        } message: {
            Text("You've walked \(formatDistance(walkVM.distance)) in \(formatDuration(Int(walkVM.duration))).")
        }
        .sheet(isPresented: $showSummary, onDismiss: { dismiss() }) {
            if let draft = walkDraft {
                WalkSummaryView(draft: draft, onDismiss: { dismiss() })
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Live Stat Cell

private struct LiveStatCell: View {
    let value: String
    let label: String

    var body: some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
                .contentTransition(.numericText())
            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.appTextSecondary)
                .tracking(1)
        }
        .frame(maxWidth: .infinity)
    }
}

private struct LiveDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.1))
            .frame(width: 1, height: 36)
    }
}

// MARK: - Live Route Map

struct LiveRouteMapView: UIViewRepresentable {
    let path: [WalkCoordinate]
    let locationService: LocationService

    func makeUIView(context: Context) -> MKMapView {
        let m = MKMapView()
        m.delegate = context.coordinator
        m.showsUserLocation = true
        m.userTrackingMode = .follow
        m.overrideUserInterfaceStyle = .dark
        let cfg = MKStandardMapConfiguration(emphasisStyle: .muted)
        cfg.showsTraffic = false
        m.preferredConfiguration = cfg
        m.pointOfInterestFilter = .excludingAll
        return m
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        guard path.count >= 2 else { return }
        let coords = path.map { $0.coordinate }
        let poly = MKPolyline(coordinates: coords, count: coords.count)
        mapView.addOverlay(poly, level: .aboveRoads)
    }

    func makeCoordinator() -> LiveMapCoordinator { LiveMapCoordinator() }
}

final class LiveMapCoordinator: NSObject, MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let poly = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
        let r = MKPolylineRenderer(polyline: poly)
        r.strokeColor = UIColor.appPrimary
        r.lineWidth = 5
        r.lineCap = .round
        r.lineJoin = .round
        // Glow effect
        r.alpha = 1.0
        return r
    }
}
