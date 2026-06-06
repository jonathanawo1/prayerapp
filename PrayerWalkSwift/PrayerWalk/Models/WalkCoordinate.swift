// WalkCoordinate.swift
// PrayerWalk

import Foundation
import CoreLocation

struct WalkCoordinate: Codable, Identifiable {
    var id: UUID = UUID()
    let lat: Double
    let lng: Double

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: lat, longitude: lng)
    }

    enum CodingKeys: String, CodingKey {
        case lat
        case lng
    }

    init(id: UUID = UUID(), lat: Double, lng: Double) {
        self.id = id
        self.lat = lat
        self.lng = lng
    }

    init(from location: CLLocation) {
        self.id = UUID()
        self.lat = location.coordinate.latitude
        self.lng = location.coordinate.longitude
    }
}
