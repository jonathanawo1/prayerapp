// CommunityMapView.swift
// PrayerWalk

import SwiftUI
import MapKit

struct CommunityMapView: View {
    let walks: [Walk]
    @State private var selectedUserId: String?
    @State private var selectedWalk: Walk?
    @State private var showDetail = false

    var body: some View {
        ZStack(alignment: .bottom) {
            MapOverlayView(
                walks: walks,
                selectedUserId: $selectedUserId,
                selectedWalk: $selectedWalk
            )
            .ignoresSafeArea()

            if let walk = selectedWalk {
                SelectedWalkPanel(walk: walk) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedWalk = nil
                        selectedUserId = nil
                    }
                } onDetail: {
                    showDetail = true
                }
                .transition(.move(edge: .bottom).combined(with: .opacity))
                .padding(.bottom, 90)
                .padding(.horizontal, 16)
            } else if !walks.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "map.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.appPrimary)
                    Text("\(walks.count) route\(walks.count == 1 ? "" : "s") — tap to explore")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Color.appTextSecondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    Capsule()
                        .fill(Color(hex: "0A1628").opacity(0.9))
                        .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 4)
                )
                .padding(.bottom, 100)
                .transition(.opacity)
            }
        }
        .sheet(isPresented: $showDetail) {
            if let walk = selectedWalk { WalkDetailSheet(walk: walk) }
        }
    }
}

// MARK: - Map UIViewRepresentable

private struct MapOverlayView: UIViewRepresentable {
    let walks: [Walk]
    @Binding var selectedUserId: String?
    @Binding var selectedWalk: Walk?

    func makeUIView(context: Context) -> MKMapView {
        let m = MKMapView()
        m.delegate = context.coordinator
        m.overrideUserInterfaceStyle = .dark
        m.showsUserLocation = true
        let cfg = MKStandardMapConfiguration(emphasisStyle: .muted)
        cfg.showsTraffic = false
        m.preferredConfiguration = cfg
        m.pointOfInterestFilter = .excludingAll

        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(MapCoordinator.handleTap(_:)))
        m.addGestureRecognizer(tap)
        context.coordinator.mapView = m
        return m
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        context.coordinator.walks = walks
        context.coordinator.currentSelectedUserId = selectedUserId

        for walk in walks {
            guard walk.polylineData.count >= 2 else { continue }
            let coords = walk.polylineData.map { $0.coordinate }
            let poly = WalkPolyline(coordinates: coords, count: coords.count)
            poly.walkId = walk.id
            poly.userId = walk.userId
            poly.isHighlighted = selectedUserId == nil || selectedUserId == walk.userId
            mapView.addOverlay(poly, level: .aboveRoads)
        }

        if selectedUserId == nil, !walks.isEmpty {
            let allCoords = walks.flatMap { $0.polylineData.map { $0.coordinate } }
            let lats = allCoords.map(\.latitude)
            let lons = allCoords.map(\.longitude)
            guard let minLat = lats.min(), let maxLat = lats.max(),
                  let minLon = lons.min(), let maxLon = lons.max() else { return }
            let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
            let span = MKCoordinateSpan(
                latitudeDelta: max((maxLat - minLat) * 1.4, 0.01),
                longitudeDelta: max((maxLon - minLon) * 1.4, 0.01)
            )
            mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
        }
    }

    func makeCoordinator() -> MapCoordinator {
        MapCoordinator(selectedUserId: $selectedUserId, selectedWalk: $selectedWalk, walks: walks)
    }
}

// Custom polyline subclass to store metadata
final class WalkPolyline: MKPolyline {
    var walkId: String = ""
    var userId: String = ""
    var isHighlighted: Bool = true
}

// MARK: - Map Coordinator

final class MapCoordinator: NSObject, MKMapViewDelegate {
    @Binding var selectedUserId: String?
    @Binding var selectedWalk: Walk?
    var walks: [Walk]
    var currentSelectedUserId: String?
    weak var mapView: MKMapView?

    init(selectedUserId: Binding<String?>, selectedWalk: Binding<Walk?>, walks: [Walk]) {
        _selectedUserId = selectedUserId
        _selectedWalk = selectedWalk
        self.walks = walks
    }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let poly = overlay as? WalkPolyline else { return MKOverlayRenderer(overlay: overlay) }
        let r = MKPolylineRenderer(polyline: poly)
        let color = UIColor.routeColor(for: poly.userId)
        if poly.isHighlighted {
            r.strokeColor = color
            r.lineWidth = 5
            r.alpha = 1.0
        } else {
            r.strokeColor = color.withAlphaComponent(0.25)
            r.lineWidth = 3
            r.alpha = 0.5
        }
        r.lineCap = .round
        r.lineJoin = .round
        return r
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let mapView = gesture.view as? MKMapView else { return }
        let point = gesture.location(in: mapView)
        let coord = mapView.convert(point, toCoordinateFrom: mapView)
        let tappedMapPoint = MKMapPoint(coord)

        var bestWalkId: String?
        var bestUserId: String?
        var bestDistance = Double.infinity
        let hitRadius: Double = 20_000

        for overlay in mapView.overlays {
            guard let poly = overlay as? WalkPolyline else { continue }
            let points = poly.points()
            for i in 0..<poly.pointCount {
                let pt = points[i]
                let dx = pt.x - tappedMapPoint.x
                let dy = pt.y - tappedMapPoint.y
                let dist = (dx * dx + dy * dy).squareRoot()
                if dist < bestDistance {
                    bestDistance = dist
                    bestWalkId = poly.walkId
                    bestUserId = poly.userId
                }
            }
        }

        DispatchQueue.main.async {
            if let walkId = bestWalkId, bestDistance < hitRadius {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    self.selectedUserId = bestUserId
                    self.selectedWalk = self.walks.first { $0.id == walkId }
                }
            } else {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                    self.selectedUserId = nil
                    self.selectedWalk = nil
                }
            }
        }
    }
}

// MARK: - Selected Walk Panel

private struct SelectedWalkPanel: View {
    let walk: Walk
    let onDismiss: () -> Void
    let onDetail: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.routeColor(for: walk.userId))
                .frame(width: 4, height: 52)

            VStack(alignment: .leading, spacing: 4) {
                Text(walk.title ?? "Prayer Walk")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)

                HStack(spacing: 14) {
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.left.and.right")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appPrimary)
                        Text(formatDistance(walk.distance))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    HStack(spacing: 4) {
                        Image(systemName: "clock.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(Color.appPrimary)
                        Text(formatDuration(walk.duration))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }

            Spacer()

            VStack(spacing: 10) {
                Button(action: onDetail) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.appPrimary)
                }
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.45))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color(hex: "08111F").opacity(0.96))
                .shadow(color: .black.opacity(0.55), radius: 24, x: 0, y: 10)
                .overlay(
                    RoundedRectangle(cornerRadius: 18)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}
