// Distance.swift
// PrayerWalk

import Foundation
import CoreLocation

// MARK: - Haversine Distance

/// Returns distance in meters between two coordinates using the Haversine formula.
func haversineDistance(from c1: WalkCoordinate, to c2: WalkCoordinate) -> Double {
    let earthRadiusMeters = 6_371_000.0
    let lat1 = c1.lat * .pi / 180
    let lat2 = c2.lat * .pi / 180
    let deltaLat = (c2.lat - c1.lat) * .pi / 180
    let deltaLon = (c2.lng - c1.lng) * .pi / 180

    let a = sin(deltaLat / 2) * sin(deltaLat / 2)
        + cos(lat1) * cos(lat2)
        * sin(deltaLon / 2) * sin(deltaLon / 2)
    let c = 2 * atan2(sqrt(a), sqrt(1 - a))
    return earthRadiusMeters * c
}

/// Returns total path distance in meters for an array of WalkCoordinates.
func totalPathDistance(_ path: [WalkCoordinate]) -> Double {
    guard path.count > 1 else { return 0 }
    var total = 0.0
    for i in 1 ..< path.count {
        total += haversineDistance(from: path[i - 1], to: path[i])
    }
    return total
}

// MARK: - Formatting

/// Formats a distance in meters to a human-readable string.
/// Shows km with 2 decimal places for >= 1 km, otherwise meters.
func formatDistance(_ meters: Double) -> String {
    if meters >= 1000 {
        let km = meters / 1000
        return String(format: "%.2f km", km)
    } else {
        return String(format: "%.0f m", meters)
    }
}

/// Formats a duration in seconds to h:mm:ss or mm:ss.
func formatDuration(_ seconds: Int) -> String {
    let h = seconds / 3600
    let m = (seconds % 3600) / 60
    let s = seconds % 60
    if h > 0 {
        return String(format: "%d:%02d:%02d", h, m, s)
    } else {
        return String(format: "%02d:%02d", m, s)
    }
}

/// Formats pace as min/km given distance in meters and duration in seconds.
/// Returns "—" if distance is negligible.
func formatPace(distanceMeters: Double, durationSeconds: Int) -> String {
    guard distanceMeters > 10 else { return "—" }
    let distanceKm = distanceMeters / 1000
    let paceSecondsPerKm = Double(durationSeconds) / distanceKm
    let paceMin = Int(paceSecondsPerKm) / 60
    let paceSec = Int(paceSecondsPerKm) % 60
    return String(format: "%d:%02d /km", paceMin, paceSec)
}
