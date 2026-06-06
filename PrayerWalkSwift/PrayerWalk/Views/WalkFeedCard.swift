// WalkFeedCard.swift
// PrayerWalk

import SwiftUI
import MapKit

struct WalkFeedCard: View {
    let walk: Walk
    @State private var showDetail = false

    private var routeColor: Color { Color.routeColor(for: walk.userId) }

    var body: some View {
        Button { showDetail = true } label: {
            VStack(spacing: 0) {
                // Map hero with gradient overlay
                ZStack(alignment: .bottom) {
                    MapSnapshotView(coordinates: walk.polylineData, userId: walk.userId)
                        .frame(height: 200)

                    // Gradient fade
                    LinearGradient(
                        colors: [.clear, Color.appBackground.opacity(0.95)],
                        startPoint: UnitPoint(x: 0.5, y: 0.4),
                        endPoint: .bottom
                    )

                    // Stats row over gradient
                    HStack(alignment: .bottom) {
                        VStack(alignment: .leading, spacing: 4) {
                            if let title = walk.title, !title.isEmpty {
                                Text(title)
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundStyle(Color.appTextPrimary)
                                    .lineLimit(1)
                            }
                            HStack(spacing: 0) {
                                Text(relativeTime(walk.startTime))
                                    .font(.system(size: 12))
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                        }

                        Spacer()

                        // Distance badge
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(formatDistance(walk.distance))
                                .font(.system(size: 22, weight: .black, design: .rounded))
                                .foregroundStyle(Color.appTextPrimary)
                            Text("distance")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
                                .textCase(.uppercase)
                                .tracking(0.5)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 14)
                }

                // Stats strip
                HStack(spacing: 0) {
                    StatCell(
                        label: "TIME",
                        value: formatDuration(walk.duration),
                        icon: "clock.fill"
                    )
                    Divider()
                        .background(Color.appSeparator)
                        .frame(height: 28)
                    StatCell(
                        label: "PACE",
                        value: formatPace(distanceMeters: walk.distance, durationSeconds: walk.duration),
                        icon: "bolt.fill"
                    )
                    Divider()
                        .background(Color.appSeparator)
                        .frame(height: 28)
                    StatCell(
                        label: "POINTS",
                        value: "\(walk.polylineData.count)",
                        icon: "mappin.circle.fill"
                    )
                }
                .padding(.vertical, 12)
                .background(Color.appSurface)
            }
        }
        .buttonStyle(.plain)
        .background(Color.appSurface)
        .sheet(isPresented: $showDetail) {
            WalkDetailSheet(walk: walk)
        }
    }

    private func relativeTime(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = f.date(from: iso)
        if date == nil {
            f.formatOptions = [.withInternetDateTime]
            date = f.date(from: iso)
        }
        guard let date else { return "" }
        let rel = RelativeDateTimeFormatter()
        rel.unitsStyle = .short
        return rel.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Stat Cell

private struct StatCell: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .tracking(0.5)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Map Snapshot View

struct MapSnapshotView: View {
    let coordinates: [WalkCoordinate]
    let userId: String

    @State private var snapshotImage: UIImage?
    @State private var isLoading = true

    var body: some View {
        ZStack {
            Color(hex: "0A1628")

            if let image = snapshotImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity.animation(.easeIn(duration: 0.3)))
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                    .scaleEffect(0.8)
            } else {
                Image(systemName: "map.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.3))
            }
        }
        .clipped()
        .task(id: userId) { await generateSnapshot() }
    }

    private func generateSnapshot() async {
        guard coordinates.count >= 2 else { isLoading = false; return }
        let coords = coordinates.map { $0.coordinate }
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * 1.5, 0.004),
            longitudeDelta: max((lons.max()! - lons.min()!) * 1.5, 0.004)
        )

        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: center, span: span)
        options.size = CGSize(width: UIScreen.main.bounds.width, height: 220)
        options.traitCollection = UITraitCollection(userInterfaceStyle: .dark)

        if #available(iOS 17.0, *) {
            let config = MKStandardMapConfiguration(emphasisStyle: .muted)
            config.showsTraffic = false
            options.preferredConfiguration = config
        }

        do {
            let snapshot = try await MKMapSnapshotter(options: options).start()
            let color = UIColor.routeColor(for: userId)
            let size = options.size
            let renderer = UIGraphicsImageRenderer(size: size)
            let img = renderer.image { ctx in
                snapshot.image.draw(at: .zero)
                let points = coords.map { snapshot.point(for: $0) }
                guard let first = points.first, let last = points.last else { return }

                // Shadow glow
                ctx.cgContext.setShadow(
                    offset: .zero,
                    blur: 8,
                    color: color.withAlphaComponent(0.7).cgColor
                )

                // Route line
                let path = UIBezierPath()
                path.move(to: first)
                points.dropFirst().forEach { path.addLine(to: $0) }
                ctx.cgContext.setStrokeColor(color.cgColor)
                ctx.cgContext.setLineWidth(3.5)
                ctx.cgContext.setLineCap(.round)
                ctx.cgContext.setLineJoin(.round)
                path.stroke()

                ctx.cgContext.setShadow(offset: .zero, blur: 0)

                // Start dot
                drawDot(ctx.cgContext, at: first, outer: 8, inner: 4.5, color: color)
                // End dot
                drawDot(ctx.cgContext, at: last, outer: 7, inner: 3.5, color: color)
            }
            await MainActor.run {
                snapshotImage = img
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }

    private func drawDot(_ ctx: CGContext, at point: CGPoint, outer: CGFloat, inner: CGFloat, color: UIColor) {
        // White ring
        ctx.setFillColor(UIColor.white.cgColor)
        ctx.fillEllipse(in: CGRect(x: point.x - outer/2, y: point.y - outer/2, width: outer, height: outer))
        // Color fill
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: CGRect(x: point.x - inner/2, y: point.y - inner/2, width: inner, height: inner))
    }
}

// MARK: - Route Map View (for detail sheet)

struct RouteMapView: UIViewRepresentable {
    let coordinates: [WalkCoordinate]
    let userId: String

    func makeUIView(context: Context) -> MKMapView {
        let m = MKMapView()
        m.delegate = context.coordinator
        m.overrideUserInterfaceStyle = .dark
        if #available(iOS 17.0, *) {
            let cfg = MKStandardMapConfiguration(emphasisStyle: .muted)
            cfg.showsTraffic = false
            m.preferredConfiguration = cfg
        }
        m.isZoomEnabled = true
        m.isScrollEnabled = true
        return m
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeOverlays(mapView.overlays)
        guard coordinates.count >= 2 else { return }
        let coords = coordinates.map { $0.coordinate }
        mapView.addOverlay(MKPolyline(coordinates: coords, count: coords.count))
        let lats = coords.map(\.latitude)
        let lons = coords.map(\.longitude)
        let center = CLLocationCoordinate2D(
            latitude: (lats.min()! + lats.max()!) / 2,
            longitude: (lons.min()! + lons.max()!) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((lats.max()! - lats.min()!) * 1.5, 0.004),
            longitudeDelta: max((lons.max()! - lons.min()!) * 1.5, 0.004)
        )
        mapView.setRegion(MKCoordinateRegion(center: center, span: span), animated: false)
    }

    func makeCoordinator() -> RouteMapCoordinator { RouteMapCoordinator(userId: userId) }
}

final class RouteMapCoordinator: NSObject, MKMapViewDelegate {
    let userId: String
    init(userId: String) { self.userId = userId }

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let poly = overlay as? MKPolyline else { return MKOverlayRenderer(overlay: overlay) }
        let r = MKPolylineRenderer(polyline: poly)
        r.strokeColor = UIColor.routeColor(for: userId)
        r.lineWidth = 5
        r.lineCap = .round
        r.lineJoin = .round
        return r
    }
}

// MARK: - Walk Detail Sheet

struct WalkDetailSheet: View {
    let walk: Walk
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Full map hero
                ZStack(alignment: .top) {
                    RouteMapView(coordinates: walk.polylineData, userId: walk.userId)
                        .frame(height: 340)
                        .ignoresSafeArea(edges: .top)

                    // Top bar
                    HStack {
                        Spacer()
                        Button {
                            dismiss()
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .frame(width: 34, height: 34)
                                Image(systemName: "xmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 56)
                }

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Title + time
                        VStack(alignment: .leading, spacing: 6) {
                            Text(walk.title ?? "Prayer Walk")
                                .font(.system(size: 26, weight: .black))
                                .foregroundStyle(Color.appTextPrimary)
                            Text(formattedDate(walk.startTime))
                                .font(.system(size: 13))
                                .foregroundStyle(Color.appTextSecondary)
                        }

                        // Stats grid
                        HStack(spacing: 1) {
                            DetailStat(label: "Distance", value: formatDistance(walk.distance), icon: "arrow.left.and.right")
                            DetailStat(label: "Duration", value: formatDuration(walk.duration), icon: "clock.fill")
                            DetailStat(label: "Pace", value: formatPace(distanceMeters: walk.distance, durationSeconds: walk.duration), icon: "bolt.fill")
                        }
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))

                        // Prayer notes
                        if let notes = walk.prayerNotes, !notes.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Prayer Notes", systemImage: "hands.sparkles.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundStyle(Color.appPrimary)
                                    .textCase(.uppercase)
                                    .tracking(0.5)

                                Text(notes)
                                    .font(.system(size: 15))
                                    .foregroundStyle(Color.appTextPrimary)
                                    .lineSpacing(4)
                            }
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .padding(20)
                    .padding(.bottom, 32)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func formattedDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = f.date(from: iso)
        if date == nil {
            f.formatOptions = [.withInternetDateTime]
            date = f.date(from: iso)
        }
        guard let date else { return "" }
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .short
        return df.string(from: date)
    }
}

private struct DetailStat: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.appTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}
