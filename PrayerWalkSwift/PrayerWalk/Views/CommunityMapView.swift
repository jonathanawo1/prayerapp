// CommunityMapView.swift
// PrayerWalk

import SwiftUI
import MapKit

// MARK: - RouteMapView (reusable UIViewRepresentable)

struct RouteMapView: UIViewRepresentable {
    let coordinates: [WalkCoordinate]
    let userId: String

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = false
        mapView.overrideUserInterfaceStyle = .dark
        mapView.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        guard coordinates.count >= 2 else { return }
        let coords = coordinates.map { $0.coordinate }
        let polyline = MKPolyline(coordinates: coords, count: coords.count)
        polyline.title = userId
        mapView.addOverlay(polyline, level: .aboveRoads)

        // Fit region
        let minLat = coords.map(\.latitude).min()!
        let maxLat = coords.map(\.latitude).max()!
        let minLon = coords.map(\.longitude).min()!
        let maxLon = coords.map(\.longitude).max()!
        let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.5, 0.003),
            longitudeDelta: max((maxLon - minLon) * 1.5, 0.003)
        )
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
    }

    func makeCoordinator() -> MapCoordinator { MapCoordinator() }
}

// MARK: - Community Map (all walks)

struct CommunityMapView: View {
    let walks: [Walk]
    @State private var selectedWalkId: String?

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()
                AllWalksMapView(walks: walks, selectedWalkId: $selectedWalkId)
                    .ignoresSafeArea(edges: .bottom)
            }
            .navigationTitle("Community Map")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - AllWalksMapView

struct AllWalksMapView: UIViewRepresentable {
    let walks: [Walk]
    @Binding var selectedWalkId: String?

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true
        mapView.overrideUserInterfaceStyle = .dark
        mapView.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(MapCoordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)
        context.coordinator.mapView = mapView
        context.coordinator.walks = walks
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        context.coordinator.walks = walks
        context.coordinator.selectedWalkId = selectedWalkId
        mapView.removeOverlays(mapView.overlays)

        for walk in walks {
            guard walk.polylineData.count >= 2 else { continue }
            let coords = walk.polylineData.map { $0.coordinate }
            let polyline = MKPolyline(coordinates: coords, count: coords.count)
            polyline.title = walk.userId
            polyline.subtitle = walk.id
            mapView.addOverlay(polyline, level: .aboveRoads)
        }

        // Fit all walks
        if !walks.isEmpty {
            let allCoords = walks.flatMap { $0.polylineData.map { $0.coordinate } }
            if allCoords.count >= 2 {
                let minLat = allCoords.map(\.latitude).min()!
                let maxLat = allCoords.map(\.latitude).max()!
                let minLon = allCoords.map(\.longitude).min()!
                let maxLon = allCoords.map(\.longitude).max()!
                let center = CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLon + maxLon) / 2)
                let span = MKCoordinateSpan(
                    latitudeDelta: max((maxLat - minLat) * 1.3, 0.01),
                    longitudeDelta: max((maxLon - minLon) * 1.3, 0.01)
                )
                mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: true)
            }
        }
    }

    func makeCoordinator() -> MapCoordinator { MapCoordinator() }
}

// MARK: - MapCoordinator

final class MapCoordinator: NSObject, MKMapViewDelegate {
    weak var mapView: MKMapView?
    var walks: [Walk] = []
    var selectedWalkId: String?

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: polyline)
        let userId = polyline.title ?? ""
        let isSelected = polyline.subtitle == selectedWalkId
        renderer.strokeColor = UIColor.routeColor(for: userId).withAlphaComponent(isSelected ? 1.0 : 0.75)
        renderer.lineWidth = isSelected ? 5 : 3
        renderer.lineCap = .round
        renderer.lineJoin = .round
        return renderer
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let mapView = mapView else { return }
        let point = gesture.location(in: mapView)
        let coord = mapView.convert(point, toCoordinateFrom: mapView)
        let mapPoint = MKMapPoint(coord)

        for overlay in mapView.overlays {
            guard let polyline = overlay as? MKPolyline else { continue }
            let renderer = mapView.renderer(for: polyline) as? MKPolylineRenderer
            let polylinePoint = renderer?.point(for: mapPoint) ?? CGPoint.zero
            if renderer?.path?.contains(polylinePoint) == true {
                selectedWalkId = polyline.subtitle
                mapView.removeOverlays(mapView.overlays)
                // Re-add all overlays to trigger re-render
                for walk in walks {
                    guard walk.polylineData.count >= 2 else { continue }
                    let coords = walk.polylineData.map { $0.coordinate }
                    let pl = MKPolyline(coordinates: coords, count: coords.count)
                    pl.title = walk.userId
                    pl.subtitle = walk.id
                    mapView.addOverlay(pl, level: .aboveRoads)
                }
                return
            }
        }
    }
}
