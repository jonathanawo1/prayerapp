// Group.swift
// PrayerWalk

import Foundation

struct Group: Codable, Identifiable {
    let id: String
    let name: String
    let description: String
    let inviteCode: String
    let createdBy: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case description
        case inviteCode = "invite_code"
        case createdBy = "created_by"
        case createdAt = "created_at"
    }
}

struct GroupInsert: Encodable {
    let name: String
    let description: String
    let inviteCode: String
    let createdBy: String

    enum CodingKeys: String, CodingKey {
        case name
        case description
        case inviteCode = "invite_code"
        case createdBy = "created_by"
    }
}
