// Profile.swift
// PrayerWalk

import Foundation

struct Profile: Codable, Identifiable {
    let id: String
    var displayName: String
    var avatarUrl: String?
    var groupId: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case groupId = "group_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ProfileUpsert: Encodable {
    let id: String
    let displayName: String
    let avatarUrl: String?
    let groupId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
        case groupId = "group_id"
    }
}
