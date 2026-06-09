// AdminView.swift
// PrayerWalk

import SwiftUI

struct AdminView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var allProfiles: [Profile] = []
    @State private var allGroups: [PrayerGroup] = []
    @State private var allWalks: [Walk] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var selectedTab = 0

    private let supabase = SupabaseService.shared

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    Picker("", selection: $selectedTab) {
                        Text("Members").tag(0)
                        Text("Branches").tag(1)
                        Text("Walks").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                            .scaleEffect(1.2)
                        Spacer()
                    } else {
                        TabView(selection: $selectedTab) {
                            MembersAdminTab(profiles: allProfiles, groups: allGroups, onRefresh: load)
                                .tag(0)
                            BranchesAdminTab(groups: allGroups, profiles: allProfiles)
                                .tag(1)
                            WalksAdminTab(walks: allWalks, profiles: allProfiles, onRefresh: load)
                                .tag(2)
                        }
                        .tabViewStyle(.page(indexDisplayMode: .never))
                    }
                }

                if let err = errorMessage {
                    VStack {
                        Spacer()
                        Text(err)
                            .font(.caption)
                            .foregroundStyle(.white)
                            .padding()
                            .background(Color.appError)
                            .clipShape(Capsule())
                            .padding(.bottom, 80)
                    }
                }
            }
            .navigationTitle("Admin")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await load() }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundStyle(Color.appPrimary)
                    }
                }
            }
            .onAppear { Task { await load() } }
        }
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let p = supabase.fetchAllProfiles()
            async let g = supabase.groupFetchAll()
            async let w = supabase.walksFetch()
            allProfiles = try await p
            allGroups = try await g
            allWalks = try await w
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Members Tab

private struct MembersAdminTab: View {
    let profiles: [Profile]
    let groups: [PrayerGroup]
    let onRefresh: () async -> Void

    private func groupName(for groupId: String?) -> String {
        guard let id = groupId else { return "No Branch" }
        return groups.first { $0.id == id }?.name ?? "Unknown"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                HStack {
                    Text("\(profiles.count) MEMBERS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Color.appTextSecondary)
                        .tracking(0.8)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                ForEach(profiles) { profile in
                    AdminMemberRow(
                        profile: profile,
                        groups: groups,
                        groupName: groupName(for: profile.groupId),
                        onRefresh: onRefresh
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
            .padding(.bottom, 100)
        }
    }
}

private struct AdminMemberRow: View {
    let profile: Profile
    let groups: [PrayerGroup]
    let groupName: String
    let onRefresh: () async -> Void

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.routeColor(for: profile.id))
                    .frame(width: 42, height: 42)
                Text(String(profile.displayName.prefix(2)).uppercased())
                    .font(.system(size: 14, weight: .black))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(profile.displayName)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.appTextPrimary)
                    if profile.admin {
                        Text("ADMIN")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Color.appPrimary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.appPrimary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text(groupName)
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            Menu {
                Menu("Move to Branch") {
                    Button("Remove from Branch", role: .destructive) {
                        Task {
                            _ = try? await SupabaseService.shared.profileUpdateGroupId(userId: profile.id, groupId: nil)
                            await onRefresh()
                        }
                    }
                    ForEach(groups) { group in
                        Button(group.name) {
                            Task {
                                _ = try? await SupabaseService.shared.profileUpdateGroupId(userId: profile.id, groupId: group.id)
                                await onRefresh()
                            }
                        }
                    }
                }
                Divider()
                Button(profile.admin ? "Remove Admin Role" : "Make Admin") {
                    Task {
                        _ = try? await SupabaseService.shared.setProfileAdmin(userId: profile.id, isAdmin: !profile.admin)
                        await onRefresh()
                    }
                }
            } label: {
                Image(systemName: "ellipsis.circle.fill")
                    .font(.system(size: 22))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.5))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Branches Tab

private struct BranchesAdminTab: View {
    let groups: [PrayerGroup]
    let profiles: [Profile]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                HStack {
                    Text("\(groups.count) BRANCHES")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Color.appTextSecondary)
                        .tracking(0.8)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                ForEach(groups) { group in
                    let members = profiles.filter { $0.groupId == group.id }
                    AdminBranchCard(group: group, members: members)
                        .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
            .padding(.bottom, 100)
        }
    }
}

private struct AdminBranchCard: View {
    let group: PrayerGroup
    let members: [Profile]
    @State private var expanded = false

    var body: some View {
        VStack(spacing: 0) {
            Button { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { expanded.toggle() } } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.15))
                            .frame(width: 46, height: 46)
                        Image(systemName: "person.3.fill")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.appPrimary)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(group.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(Color.appTextPrimary)
                        Text("\(members.count) members • \(group.inviteCode)")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    Spacer()
                    Image(systemName: expanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.5))
                }
                .padding(14)
            }
            .buttonStyle(.plain)

            if expanded {
                Divider()
                    .background(Color.appSeparator)
                    .padding(.horizontal, 14)

                VStack(spacing: 8) {
                    ForEach(members) { member in
                        HStack(spacing: 10) {
                            ZStack {
                                Circle()
                                    .fill(Color.routeColor(for: member.id))
                                    .frame(width: 30, height: 30)
                                Text(String(member.displayName.prefix(1)).uppercased())
                                    .font(.system(size: 11, weight: .black))
                                    .foregroundStyle(.white)
                            }
                            Text(member.displayName)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.appTextPrimary)
                            Spacer()
                            if member.admin {
                                Text("ADMIN")
                                    .font(.system(size: 9, weight: .black))
                                    .foregroundStyle(Color.appPrimary)
                                    .padding(.horizontal, 5).padding(.vertical, 2)
                                    .background(Color.appPrimary.opacity(0.15))
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    if members.isEmpty {
                        Text("No members")
                            .font(.system(size: 13))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
            }
        }
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Walks Tab

private struct WalksAdminTab: View {
    let walks: [Walk]
    let profiles: [Profile]
    let onRefresh: () async -> Void

    private func walkerName(for userId: String) -> String {
        profiles.first { $0.id == userId }?.displayName ?? "Unknown"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 10) {
                HStack {
                    Text("\(walks.count) WALKS")
                        .font(.system(size: 11, weight: .black))
                        .foregroundStyle(Color.appTextSecondary)
                        .tracking(0.8)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 4)

                ForEach(walks) { walk in
                    AdminWalkRow(
                        walk: walk,
                        walkerName: walkerName(for: walk.userId),
                        onRefresh: onRefresh
                    )
                    .padding(.horizontal, 16)
                }
            }
            .padding(.vertical, 12)
            .padding(.bottom, 100)
        }
    }
}

private struct AdminWalkRow: View {
    let walk: Walk
    let walkerName: String
    let onRefresh: () async -> Void
    @State private var confirmDelete = false

    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.routeColor(for: walk.userId))
                .frame(width: 4, height: 44)

            VStack(alignment: .leading, spacing: 2) {
                Text(walk.title ?? "Prayer Walk")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                    .lineLimit(1)
                Text("\(walkerName) • \(formatDistance(walk.distance))")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            Button(role: .destructive) {
                confirmDelete = true
            } label: {
                Image(systemName: "trash.fill")
                    .font(.system(size: 16))
                    .foregroundStyle(Color.appError.opacity(0.7))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .confirmationDialog("Delete this walk?", isPresented: $confirmDelete, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                Task {
                    try? await SupabaseService.shared.deleteWalk(id: walk.id)
                    await onRefresh()
                }
            }
            Button("Cancel", role: .cancel) {}
        }
    }
}
