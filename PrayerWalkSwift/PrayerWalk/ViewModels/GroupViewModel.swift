// GroupViewModel.swift
// PrayerWalk

import Foundation

@MainActor
final class GroupViewModel: ObservableObject {
    @Published var group: PrayerGroup?
    @Published var members: [Profile] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared

    func fetchGroup(id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            group = try await supabase.groupFetch(id: id)
            if let g = group {
                members = try await supabase.profilesFetch(groupId: g.id)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func createGroup(name: String, description: String, profileVM: ProfileViewModel, userId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let newGroup = try await supabase.groupCreate(name: name, description: description)
            group = newGroup
            await profileVM.updateGroupId(newGroup.id, userId: userId)
            members = try await supabase.profilesFetch(groupId: newGroup.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func joinGroup(inviteCode: String, profileVM: ProfileViewModel, userId: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            guard let found = try await supabase.groupJoin(inviteCode: inviteCode) else {
                errorMessage = "No group found with that invite code."
                return
            }
            group = found
            await profileVM.updateGroupId(found.id, userId: userId)
            members = try await supabase.profilesFetch(groupId: found.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func fetchMembers() async {
        guard let g = group else { return }
        do {
            members = try await supabase.profilesFetch(groupId: g.id)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func leaveGroup(profileVM: ProfileViewModel, userId: String) async {
        await profileVM.updateGroupId(nil, userId: userId)
        group = nil
        members = []
    }
}
