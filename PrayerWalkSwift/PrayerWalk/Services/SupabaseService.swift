// SupabaseService.swift
// PrayerWalk

import Foundation

// MARK: - Auth Response Models

private struct AuthResponse: Decodable {
    let accessToken: String
    let refreshToken: String
    let user: AuthUser

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case user
    }
}

private struct AuthUser: Decodable {
    let id: String
    let email: String?
}

private struct SupabaseError: Decodable {
    let message: String?
    let error: String?
    let error_description: String?
    let msg: String?

    var localizedMessage: String {
        message ?? error_description ?? error ?? msg ?? "Unknown error"
    }
}

// MARK: - SupabaseService

final class SupabaseService: ObservableObject {
    static let shared = SupabaseService()

    private let supabaseURL = "https://zzhvuoylsanybhcvxtsq.supabase.co"
    private let anonKey = "sb_publishable_Kdm8x4LsFvNPiz8hRM5_gA_Ur4hOB9P"

    private let defaults = UserDefaults.standard
    private let keyAccessToken = "pw_access_token"
    private let keyRefreshToken = "pw_refresh_token"
    private let keyUserId = "pw_user_id"
    private let keyUserEmail = "pw_user_email"

    private(set) var accessToken: String? {
        get { defaults.string(forKey: keyAccessToken) }
        set { defaults.set(newValue, forKey: keyAccessToken) }
    }
    private(set) var refreshToken: String? {
        get { defaults.string(forKey: keyRefreshToken) }
        set { defaults.set(newValue, forKey: keyRefreshToken) }
    }
    private(set) var userId: String? {
        get { defaults.string(forKey: keyUserId) }
        set { defaults.set(newValue, forKey: keyUserId) }
    }
    private(set) var userEmail: String? {
        get { defaults.string(forKey: keyUserEmail) }
        set { defaults.set(newValue, forKey: keyUserEmail) }
    }

    var isAuthenticated: Bool { accessToken != nil && userId != nil }

    private let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        return URLSession(configuration: config)
    }()

    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private let encoder: JSONEncoder = {
        let e = JSONEncoder()
        return e
    }()

    private init() {}

    // MARK: - Session

    func restoreSession() -> Bool {
        return isAuthenticated
    }

    func clearSession() {
        defaults.removeObject(forKey: keyAccessToken)
        defaults.removeObject(forKey: keyRefreshToken)
        defaults.removeObject(forKey: keyUserId)
        defaults.removeObject(forKey: keyUserEmail)
    }

    // MARK: - Auth

    func signIn(email: String, password: String) async throws {
        let url = URL(string: "\(supabaseURL)/auth/v1/token?grant_type=password")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        let body = ["email": email, "password": password]
        req.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: req)
        try validateResponse(response, data: data)
        let auth = try decoder.decode(AuthResponse.self, from: data)
        accessToken = auth.accessToken
        refreshToken = auth.refreshToken
        userId = auth.user.id
        userEmail = auth.user.email
    }

    func signUp(email: String, password: String) async throws {
        let url = URL(string: "\(supabaseURL)/auth/v1/signup")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        let body = ["email": email, "password": password]
        req.httpBody = try encoder.encode(body)

        let (data, response) = try await session.data(for: req)
        try validateResponse(response, data: data)
        let auth = try decoder.decode(AuthResponse.self, from: data)
        accessToken = auth.accessToken
        refreshToken = auth.refreshToken
        userId = auth.user.id
        userEmail = auth.user.email
    }

    func signOut() async throws {
        guard let token = accessToken else { return }
        let url = URL(string: "\(supabaseURL)/auth/v1/logout")!
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        _ = try? await session.data(for: req)
        clearSession()
    }

    // MARK: - REST Helpers

    private func authedRequest(method: String, path: String, queryItems: [URLQueryItem] = [], body: Data? = nil) throws -> URLRequest {
        guard let token = accessToken else {
            throw AppError.notAuthenticated
        }
        var components = URLComponents(string: "\(supabaseURL)/rest/v1/\(path)")!
        if !queryItems.isEmpty {
            components.queryItems = queryItems
        }
        var req = URLRequest(url: components.url!)
        req.httpMethod = method
        req.setValue(anonKey, forHTTPHeaderField: "apikey")
        req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue("return=representation", forHTTPHeaderField: "Prefer")
        req.httpBody = body
        return req
    }

    private func validateResponse(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }
        guard (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<binary>"
            let errMsg = (try? decoder.decode(SupabaseError.self, from: data))?.localizedMessage ?? "HTTP \(http.statusCode)"
            print("[SupabaseService] HTTP \(http.statusCode) — \(body)")
            throw AppError.serverError(errMsg)
        }
    }

    private func fetch<T: Decodable>(_ type: T.Type, path: String, queryItems: [URLQueryItem] = []) async throws -> T {
        let req = try authedRequest(method: "GET", path: path, queryItems: queryItems)
        let (data, response) = try await session.data(for: req)
        try validateResponse(response, data: data)
        return try decoder.decode(T.self, from: data)
    }

    private func insert<Body: Encodable, Response: Decodable>(_ body: Body, path: String) async throws -> Response {
        let bodyData = try encoder.encode(body)
        let req = try authedRequest(method: "POST", path: path, body: bodyData)
        let (data, response) = try await session.data(for: req)
        try validateResponse(response, data: data)
        // Supabase returns array on insert with return=representation
        let arr = try decoder.decode([Response].self, from: data)
        guard let first = arr.first else { throw AppError.serverError("Empty insert response") }
        return first
    }

    private func upsert<Body: Encodable, Response: Decodable>(_ body: Body, path: String) async throws -> Response {
        let bodyData = try encoder.encode(body)
        var req = try authedRequest(method: "POST", path: path, body: bodyData)
        req.setValue("resolution=merge-duplicates,return=representation", forHTTPHeaderField: "Prefer")
        let (data, response) = try await session.data(for: req)
        try validateResponse(response, data: data)
        let arr = try decoder.decode([Response].self, from: data)
        guard let first = arr.first else { throw AppError.serverError("Empty upsert response") }
        return first
    }

    private func patch<Body: Encodable, Response: Decodable>(_ body: Body, path: String, queryItems: [URLQueryItem]) async throws -> Response {
        let bodyData = try encoder.encode(body)
        let req = try authedRequest(method: "PATCH", path: path, queryItems: queryItems, body: bodyData)
        let (data, response) = try await session.data(for: req)
        try validateResponse(response, data: data)
        let arr = try decoder.decode([Response].self, from: data)
        guard let first = arr.first else { throw AppError.serverError("Empty patch response") }
        return first
    }

    // MARK: - Walks

    func walksFetch() async throws -> [Walk] {
        try await fetch([Walk].self, path: "walks", queryItems: [
            URLQueryItem(name: "order", value: "created_at.desc")
        ])
    }

    func walksForUser(userId: String) async throws -> [Walk] {
        try await fetch([Walk].self, path: "walks", queryItems: [
            URLQueryItem(name: "user_id", value: "eq.\(userId)"),
            URLQueryItem(name: "order", value: "created_at.desc")
        ])
    }

    func walkInsert(_ walk: WalkInsert) async throws -> Walk {
        try await insert(walk, path: "walks")
    }

    // MARK: - Profiles

    func profileFetch(userId: String) async throws -> Profile? {
        let profiles = try await fetch([Profile].self, path: "profiles", queryItems: [
            URLQueryItem(name: "id", value: "eq.\(userId)"),
            URLQueryItem(name: "limit", value: "1")
        ])
        return profiles.first
    }

    func profileUpsert(_ profile: ProfileUpsert) async throws -> Profile {
        try await upsert(profile, path: "profiles")
    }

    func profilesFetch(groupId: String) async throws -> [Profile] {
        try await fetch([Profile].self, path: "profiles", queryItems: [
            URLQueryItem(name: "group_id", value: "eq.\(groupId)")
        ])
    }

    func profileUpdateGroupId(userId: String, groupId: String?) async throws -> Profile {
        struct GroupIdUpdate: Encodable {
            let groupId: String?
            enum CodingKeys: String, CodingKey { case groupId = "group_id" }
        }
        return try await patch(GroupIdUpdate(groupId: groupId), path: "profiles", queryItems: [
            URLQueryItem(name: "id", value: "eq.\(userId)")
        ])
    }

    // MARK: - Groups

    func groupFetch(id: String) async throws -> PrayerGroup? {
        let groups = try await fetch([PrayerGroup].self, path: "groups", queryItems: [
            URLQueryItem(name: "id", value: "eq.\(id)"),
            URLQueryItem(name: "limit", value: "1")
        ])
        return groups.first
    }

    func groupFetchAll() async throws -> [PrayerGroup] {
        try await fetch([PrayerGroup].self, path: "groups", queryItems: [
            URLQueryItem(name: "order", value: "created_at.desc")
        ])
    }

    func groupCreate(name: String, description: String) async throws -> PrayerGroup {
        guard let uid = userId else { throw AppError.notAuthenticated }
        let inviteCode = String((0..<8).map { _ in "ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789".randomElement()! })
        let insert = GroupInsert(name: name, description: description, inviteCode: inviteCode, createdBy: uid)
        return try await self.insert(insert, path: "groups")
    }

    func groupJoin(inviteCode: String) async throws -> PrayerGroup? {
        let groups = try await fetch([PrayerGroup].self, path: "groups", queryItems: [
            URLQueryItem(name: "invite_code", value: "eq.\(inviteCode.uppercased())"),
            URLQueryItem(name: "limit", value: "1")
        ])
        return groups.first
    }
}

// MARK: - App Errors

enum AppError: LocalizedError {
    case notAuthenticated
    case serverError(String)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated: return "You are not signed in."
        case .serverError(let msg): return msg
        case .decodingError(let msg): return "Data error: \(msg)"
        }
    }
}
