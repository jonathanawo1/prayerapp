// ProfileViewModel.swift
// PrayerWalk

import Foundation

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var profile: Profile?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared

    func fetchProfile(userId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            profile = try await supabase.profileFetch(userId: userId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateDisplayName(_ name: String, userId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let upsert = ProfileUpsert(
                id: userId,
                displayName: name,
                avatarUrl: profile?.avatarUrl,
                groupId: profile?.groupId
            )
            profile = try await supabase.profileUpsert(upsert)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateGroupId(_ groupId: String?, userId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            profile = try await supabase.profileUpdateGroupId(userId: userId, groupId: groupId)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func ensureProfile(userId: String, email: String) async {
        if profile != nil { return }
        do {
            if let existing = try await supabase.profileFetch(userId: userId) {
                profile = existing
            } else {
                let upsert = ProfileUpsert(
                    id: userId,
                    displayName: email.components(separatedBy: "@").first ?? "Walker",
                    avatarUrl: nil,
                    groupId: nil
                )
                profile = try await supabase.profileUpsert(upsert)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
