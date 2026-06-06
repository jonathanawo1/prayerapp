// LocationService.swift
// PrayerWalk

import Foundation
import CoreLocation
import Combine

final class LocationService: NSObject, ObservableObject {
    @Published var currentLocation: CLLocation?
    @Published var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published var path: [WalkCoordinate] = []

    private let manager: CLLocationManager
    private var isTracking = false

    override init() {
        manager = CLLocationManager()
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = 5 // meters
        manager.allowsBackgroundLocationUpdates = false
        manager.pausesLocationUpdatesAutomatically = false
        authorizationStatus = manager.authorizationStatus
    }

    func requestPermission() {
        manager.requestWhenInUseAuthorization()
    }

    func startTracking() {
        guard !isTracking else { return }
        isTracking = true
        manager.startUpdatingLocation()
    }

    func stopTracking() {
        guard isTracking else { return }
        isTracking = false
        manager.stopUpdatingLocation()
    }

    func resetPath() {
        path = []
        currentLocation = nil
    }
}

extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        // Filter out inaccurate readings
        guard location.horizontalAccuracy < 50, location.horizontalAccuracy >= 0 else { return }
        currentLocation = location
        if isTracking {
            let coord = WalkCoordinate(from: location)
            path.append(coord)
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if manager.authorizationStatus == .authorizedWhenInUse ||
           manager.authorizationStatus == .authorizedAlways {
            manager.startUpdatingLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Silently handle — location errors are transient
    }
}
