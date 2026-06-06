// PrayerWalkTests.swift
// PrayerWalkTests

import XCTest
@testable import PrayerWalk

final class PrayerWalkTests: XCTestCase {

    // MARK: - Haversine Distance Tests

    func testHaversineZeroDistance() {
        let coord = WalkCoordinate(lat: 51.5074, lng: -0.1278)
        let distance = haversineDistance(from: coord, to: coord)
        XCTAssertEqual(distance, 0, accuracy: 0.001)
    }

    func testHaversineKnownDistance() {
        // London to Paris is approximately 340 km
        let london = WalkCoordinate(lat: 51.5074, lng: -0.1278)
        let paris = WalkCoordinate(lat: 48.8566, lng: 2.3522)
        let distance = haversineDistance(from: london, to: paris)
        // Should be approximately 340,000 meters
        XCTAssertEqual(distance, 340_000, accuracy: 5000)
    }

    func testHaversineShortDistance() {
        // Two points ~111 meters apart (roughly 0.001 degree latitude)
        let p1 = WalkCoordinate(lat: 37.7749, lng: -122.4194)
        let p2 = WalkCoordinate(lat: 37.7758, lng: -122.4194)
        let distance = haversineDistance(from: p1, to: p2)
        XCTAssertEqual(distance, 100, accuracy: 20)
    }

    func testHaversineIsSymmetric() {
        let a = WalkCoordinate(lat: 34.0522, lng: -118.2437)
        let b = WalkCoordinate(lat: 40.7128, lng: -74.0060)
        let d1 = haversineDistance(from: a, to: b)
        let d2 = haversineDistance(from: b, to: a)
        XCTAssertEqual(d1, d2, accuracy: 0.001)
    }

    // MARK: - Total Path Distance Tests

    func testTotalPathDistanceEmpty() {
        let distance = totalPathDistance([])
        XCTAssertEqual(distance, 0)
    }

    func testTotalPathDistanceSinglePoint() {
        let distance = totalPathDistance([WalkCoordinate(lat: 51.5, lng: -0.1)])
        XCTAssertEqual(distance, 0)
    }

    func testTotalPathDistanceMultiplePoints() {
        let p1 = WalkCoordinate(lat: 51.500, lng: -0.100)
        let p2 = WalkCoordinate(lat: 51.501, lng: -0.100)
        let p3 = WalkCoordinate(lat: 51.502, lng: -0.100)
        let total = totalPathDistance([p1, p2, p3])
        let expected = haversineDistance(from: p1, to: p2) + haversineDistance(from: p2, to: p3)
        XCTAssertEqual(total, expected, accuracy: 0.001)
    }

    func testTotalPathDistanceTwoPoints() {
        let a = WalkCoordinate(lat: 48.8566, lng: 2.3522)
        let b = WalkCoordinate(lat: 48.8600, lng: 2.3600)
        let total = totalPathDistance([a, b])
        let direct = haversineDistance(from: a, to: b)
        XCTAssertEqual(total, direct, accuracy: 0.001)
    }

    // MARK: - formatDistance Tests

    func testFormatDistanceMeters() {
        let result = formatDistance(450)
        XCTAssertEqual(result, "450 m")
    }

    func testFormatDistanceKilometers() {
        let result = formatDistance(2500)
        XCTAssertEqual(result, "2.50 km")
    }

    func testFormatDistanceExactlyOneKm() {
        let result = formatDistance(1000)
        XCTAssertEqual(result, "1.00 km")
    }

    func testFormatDistanceZero() {
        let result = formatDistance(0)
        XCTAssertEqual(result, "0 m")
    }

    func testFormatDistanceLargeKm() {
        let result = formatDistance(42195) // marathon
        XCTAssertEqual(result, "42.20 km")
    }

    func testFormatDistanceJustUnderKm() {
        let result = formatDistance(999)
        XCTAssertEqual(result, "999 m")
    }

    // MARK: - formatDuration Tests

    func testFormatDurationSeconds() {
        let result = formatDuration(45)
        XCTAssertEqual(result, "00:45")
    }

    func testFormatDurationMinutes() {
        let result = formatDuration(90) // 1:30
        XCTAssertEqual(result, "01:30")
    }

    func testFormatDurationOneHour() {
        let result = formatDuration(3600)
        XCTAssertEqual(result, "1:00:00")
    }

    func testFormatDurationHoursMinutesSeconds() {
        let result = formatDuration(3723) // 1h 2m 3s
        XCTAssertEqual(result, "1:02:03")
    }

    func testFormatDurationZero() {
        let result = formatDuration(0)
        XCTAssertEqual(result, "00:00")
    }

    func testFormatDurationTenMinutes() {
        let result = formatDuration(600)
        XCTAssertEqual(result, "10:00")
    }

    func testFormatDurationLarge() {
        let result = formatDuration(7384) // 2h 3m 4s
        XCTAssertEqual(result, "2:03:04")
    }

    // MARK: - formatPace Tests

    func testFormatPaceNegligibleDistance() {
        let result = formatPace(distanceMeters: 5, durationSeconds: 60)
        XCTAssertEqual(result, "—")
    }

    func testFormatPaceZeroDistance() {
        let result = formatPace(distanceMeters: 0, durationSeconds: 300)
        XCTAssertEqual(result, "—")
    }

    func testFormatPaceSixMinPerKm() {
        // 1000m in 360 seconds = 6:00 /km
        let result = formatPace(distanceMeters: 1000, durationSeconds: 360)
        XCTAssertEqual(result, "6:00 /km")
    }

    func testFormatPaceFiveMinPerKm() {
        // 2000m in 600 seconds = 5:00 /km
        let result = formatPace(distanceMeters: 2000, durationSeconds: 600)
        XCTAssertEqual(result, "5:00 /km")
    }

    func testFormatPaceWalkingSpeed() {
        // Walking: ~15 min/km = 1000m in 900s
        let result = formatPace(distanceMeters: 1000, durationSeconds: 900)
        XCTAssertEqual(result, "15:00 /km")
    }

    func testFormatPaceWithFractionalMinutes() {
        // 1000m in 390 seconds = 6:30 /km
        let result = formatPace(distanceMeters: 1000, durationSeconds: 390)
        XCTAssertEqual(result, "6:30 /km")
    }

    func testFormatPaceHalfMarathon() {
        // 21097m in 6300 seconds ≈ 5:00 /km
        let result = formatPace(distanceMeters: 21097, durationSeconds: 6300)
        // Should produce something reasonable
        XCTAssertTrue(result.hasSuffix("/km"))
        XCTAssertFalse(result == "—")
    }
}
