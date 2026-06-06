// WalkFeedCard.swift
// PrayerWalk

import SwiftUI
import MapKit

struct WalkFeedCard: View {
    let walk: Walk
    @State private var showDetail: Bool = false

    var body: some View {
        Button { showDetail = true } label: {
            VStack(alignment: .leading, spacing: 0) {
                // Map thumbnail
                MapSnapshotView(coordinates: walk.polylineData, userId: walk.userId)
                    .frame(height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

                // Stats row
                VStack(alignment: .leading, spacing: 8) {
                    if let title = walk.title, !title.isEmpty {
                        Text(title)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.appTextPrimary)
                            .lineLimit(1)
                    }

                    HStack(spacing: 16) {
                        StatPill(icon: "arrow.triangle.swap", value: formatDistance(walk.distance))
                        StatPill(icon: "clock", value: formatDuration(walk.duration))
                        StatPill(icon: "figure.walk", value: formatPace(distanceMeters: walk.distance, durationSeconds: walk.duration))
                        Spacer()
                        Text(relativeTime(walk.startTime))
                            .font(.caption)
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
            }
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
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
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Stat Pill

private struct StatPill: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.appPrimary)
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.appTextSecondary)
        }
    }
}

// MARK: - MKMapSnapshotter View

struct MapSnapshotView: View {
    let coordinates: [WalkCoordinate]
    let userId: String

    @State private var snapshotImage: UIImage?
    @State private var isLoading: Bool = true

    var body: some View {
        ZStack {
            Color.appSurface

            if let image = snapshotImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else if isLoading {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
            } else {
                // No route
                Image(systemName: "map")
                    .font(.largeTitle)
                    .foregroundColor(.appTextSecondary)
            }
        }
        .task(id: userId) {
            await generateSnapshot()
        }
    }

    private func generateSnapshot() async {
        guard coordinates.count >= 2 else {
            isLoading = false
            return
        }

        let coords = coordinates.map { $0.coordinate }

        // Compute region
        let minLat = coords.map(\.latitude).min()!
        let maxLat = coords.map(\.latitude).max()!
        let minLon = coords.map(\.longitude).min()!
        let maxLon = coords.map(\.longitude).max()!
        let center = CLLocationCoordinate2D(
            latitude: (minLat + maxLat) / 2,
            longitude: (minLon + maxLon) / 2
        )
        let span = MKCoordinateSpan(
            latitudeDelta: max((maxLat - minLat) * 1.4, 0.002),
            longitudeDelta: max((maxLon - minLon) * 1.4, 0.002)
        )
        let region = MKCoordinateRegion(center: center, span: span)

        let options = MKMapSnapshotter.Options()
        options.region = region
        options.size = CGSize(width: 400, height: 200)
        options.preferredConfiguration = MKStandardMapConfiguration(emphasisStyle: .muted)
        options.traitCollection = UITraitCollection(userInterfaceStyle: .dark)

        let snapshotter = MKMapSnapshotter(options: options)

        do {
            let snapshot = try await snapshotter.start()
            let renderer = UIGraphicsImageRenderer(size: options.size)
            let color = UIColor.routeColor(for: userId)
            let image = renderer.image { ctx in
                snapshot.image.draw(at: .zero)
                let path = UIBezierPath()
                let points = coords.map { snapshot.point(for: $0) }
                guard let first = points.first else { return }
                path.move(to: first)
                for pt in points.dropFirst() { path.addLine(to: pt) }
                ctx.cgContext.setStrokeColor(color.cgColor)
                ctx.cgContext.setLineWidth(3)
                ctx.cgContext.setLineCap(.round)
                ctx.cgContext.setLineJoin(.round)
                path.stroke()

                // Draw start dot
                let startRect = CGRect(x: first.x - 5, y: first.y - 5, width: 10, height: 10)
                ctx.cgContext.setFillColor(UIColor.white.cgColor)
                ctx.cgContext.fillEllipse(in: startRect)
                ctx.cgContext.setFillColor(color.cgColor)
                let innerRect = CGRect(x: first.x - 3, y: first.y - 3, width: 6, height: 6)
                ctx.cgContext.fillEllipse(in: innerRect)
            }
            await MainActor.run {
                snapshotImage = image
                isLoading = false
            }
        } catch {
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Walk Detail Sheet

struct WalkDetailSheet: View {
    let walk: Walk
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Full map
                    RouteMapView(coordinates: walk.polylineData, userId: walk.userId)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 0))

                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            if let title = walk.title, !title.isEmpty {
                                Text(title)
                                    .font(.title2.bold())
                                    .foregroundColor(.appTextPrimary)
                            }

                            HStack(spacing: 24) {
                                WalkStat(label: "Distance", value: formatDistance(walk.distance))
                                WalkStat(label: "Duration", value: formatDuration(walk.duration))
                                WalkStat(label: "Pace", value: formatPace(distanceMeters: walk.distance, durationSeconds: walk.duration))
                            }

                            if let notes = walk.prayerNotes, !notes.isEmpty {
                                VStack(alignment: .leading, spacing: 6) {
                                    Label("Prayer Notes", systemImage: "hands.sparkles")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.appPrimary)
                                    Text(notes)
                                        .font(.body)
                                        .foregroundColor(.appTextPrimary)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .padding(16)
                                .background(Color.appSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(.appPrimary)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

struct WalkStat: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.appTextPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(.appTextSecondary)
        }
    }
}
