// Walk.swift
// PrayerWalk

import Foundation

struct Walk: Codable, Identifiable {
    let id: String
    let userId: String
    let groupId: String?
    let startTime: String
    let endTime: String?
    let polylineData: [WalkCoordinate]
    let distance: Double
    let duration: Int
    let title: String?
    let prayerNotes: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case groupId = "group_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case polylineData = "polyline_data"
        case distance
        case duration
        case title
        case prayerNotes = "prayer_notes"
        case createdAt = "created_at"
    }
}

// MARK: - Insert payload

struct WalkInsert: Encodable {
    let userId: String
    let groupId: String?
    let startTime: String
    let endTime: String
    let polylineData: [WalkCoordinate]
    let distance: Double
    let duration: Int
    let title: String?
    let prayerNotes: String?

    enum CodingKeys: String, CodingKey {
        case userId = "user_id"
        case groupId = "group_id"
        case startTime = "start_time"
        case endTime = "end_time"
        case polylineData = "polyline_data"
        case distance
        case duration
        case title
        case prayerNotes = "prayer_notes"
    }
}

// MARK: - Draft (before saving)

struct WalkDraft {
    var startTime: Date
    var endTime: Date
    var path: [WalkCoordinate]
    var distance: Double
    var duration: Int
    var title: String
    var prayerNotes: String

    static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    func toInsert(userId: String, groupId: String?) -> WalkInsert {
        WalkInsert(
            userId: userId,
            groupId: groupId,
            startTime: Self.isoFormatter.string(from: startTime),
            endTime: Self.isoFormatter.string(from: endTime),
            polylineData: path,
            distance: distance,
            duration: duration,
            title: title.isEmpty ? nil : title,
            prayerNotes: prayerNotes.isEmpty ? nil : prayerNotes
        )
    }
}
