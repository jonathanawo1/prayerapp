// GroupView.swift
// PrayerWalk

import SwiftUI

struct GroupView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var walksVM: WalksViewModel

    @State private var showCreateSheet = false
    @State private var showJoinSheet = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if groupVM.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                        .scaleEffect(1.2)
                } else if let group = groupVM.group {
                    GroupDetailView(group: group)
                } else {
                    NoGroupView(showCreate: $showCreateSheet, showJoin: $showJoinSheet)
                }
            }
            .navigationTitle("Prayer Club")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCreateSheet) { CreateGroupSheet() }
            .sheet(isPresented: $showJoinSheet) { JoinGroupSheet() }
        }
    }
}

// MARK: - No Group

private struct NoGroupView: View {
    @Binding var showCreate: Bool
    @Binding var showJoin: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Illustration
            ZStack {
                Circle()
                    .fill(Color.appSurface)
                    .frame(width: 120, height: 120)
                Image(systemName: "person.3.sequence.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.4))
            }
            .padding(.bottom, 24)

            Text("No Club Yet")
                .font(.system(size: 24, weight: .black))
                .foregroundStyle(Color.appTextPrimary)
                .padding(.bottom, 8)

            Text("Create a club or join one\nwith an invite code to pray together.")
                .font(.system(size: 15))
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.bottom, 40)

            VStack(spacing: 12) {
                Button { showCreate = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 17))
                        Text("Create a Club")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "FF6B35"), Color.appPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: Color.appPrimary.opacity(0.4), radius: 12, x: 0, y: 5)
                }

                Button { showJoin = true } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 17))
                        Text("Join with Invite Code")
                            .font(.system(size: 17, weight: .bold))
                    }
                    .foregroundStyle(Color.appTextPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
                }
            }
            .padding(.horizontal, 28)

            Spacer()
        }
    }
}

// MARK: - Group Detail

private struct GroupDetailView: View {
    let group: Group
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var walksVM: WalksViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showCopied = false

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Group hero
                ZStack(alignment: .bottom) {
                    LinearGradient(
                        colors: [Color(hex: "0F1F3D"), Color.appBackground],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(height: 160)

                    VStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.appPrimary.opacity(0.15))
                                .frame(width: 72, height: 72)
                            Image(systemName: "person.3.fill")
                                .font(.system(size: 28))
                                .foregroundStyle(Color.appPrimary)
                        }

                        VStack(spacing: 4) {
                            Text(group.name)
                                .font(.system(size: 22, weight: .black))
                                .foregroundStyle(Color.appTextPrimary)
                            if !group.description.isEmpty {
                                Text(group.description)
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.appTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }

                VStack(spacing: 20) {
                    // Stats
                    HStack(spacing: 1) {
                        GroupStat(value: "\(groupVM.members.count)", label: "MEMBERS", icon: "person.fill")
                        Rectangle().fill(Color.appSeparator).frame(width: 1)
                        GroupStat(
                            value: "\(walksVM.walks.filter { m in groupVM.members.contains(where: { $0.id == m.userId }) }.count)",
                            label: "WALKS",
                            icon: "figure.walk"
                        )
                        Rectangle().fill(Color.appSeparator).frame(width: 1)
                        GroupStat(
                            value: formatDistance(walksVM.walks.filter { m in groupVM.members.contains(where: { $0.id == m.userId }) }.reduce(0) { $0 + $1.distance }),
                            label: "DISTANCE",
                            icon: "arrow.left.and.right"
                        )
                    }
                    .background(Color.appSurface)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .padding(.horizontal, 20)

                    // Invite code card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Invite Code")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(Color.appTextSecondary)
                            .textCase(.uppercase)
                            .tracking(0.8)

                        Button {
                            UIPasteboard.general.string = group.inviteCode
                            withAnimation { showCopied = true }
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                withAnimation { showCopied = false }
                            }
                        } label: {
                            HStack {
                                Text(group.inviteCode)
                                    .font(.system(size: 28, weight: .black, design: .monospaced))
                                    .foregroundStyle(Color.appPrimary)
                                    .tracking(4)
                                Spacer()
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(showCopied ? Color.appSuccess.opacity(0.15) : Color.appBackground)
                                        .frame(width: 80, height: 36)
                                    HStack(spacing: 5) {
                                        Image(systemName: showCopied ? "checkmark" : "doc.on.doc")
                                            .font(.system(size: 12, weight: .bold))
                                        Text(showCopied ? "Copied" : "Copy")
                                            .font(.system(size: 12, weight: .bold))
                                    }
                                    .foregroundStyle(showCopied ? Color.appSuccess : Color.appTextSecondary)
                                }
                            }
                            .padding(16)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Members
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Members (\(groupVM.members.count))")
                            .font(.system(size: 11, weight: .black))
                            .foregroundStyle(Color.appTextSecondary)
                            .textCase(.uppercase)
                            .tracking(0.8)
                            .padding(.horizontal, 20)

                        ForEach(groupVM.members) { member in
                            let memberWalks = walksVM.walks.filter { $0.userId == member.id }
                            MemberCard(profile: member, walkCount: memberWalks.count, isYou: member.id == authVM.userId)
                                .padding(.horizontal, 20)
                        }
                    }

                    // Leave group
                    Button(role: .destructive) {
                        Task { await groupVM.leaveGroup(profileVM: profileVM, userId: authVM.userId) }
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Leave Club")
                        }
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundStyle(Color.appError)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 15)
                        .background(Color.appError.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .strokeBorder(Color.appError.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 100)
                }
                .padding(.top, 20)
            }
        }
        .background(Color.appBackground)
        .onAppear { Task { await groupVM.fetchMembers() } }
    }
}

private struct GroupStat: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
            Text(value)
                .font(.system(size: 18, weight: .black, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.appTextSecondary)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private struct MemberCard: View {
    let profile: Profile
    let walkCount: Int
    let isYou: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.routeColor(for: profile.id))
                    .frame(width: 46, height: 46)
                Text(String(profile.displayName.prefix(2)).uppercased())
                    .font(.system(size: 16, weight: .black))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(profile.displayName)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Color.appTextPrimary)
                    if isYou {
                        Text("YOU")
                            .font(.system(size: 9, weight: .black))
                            .foregroundStyle(Color.appPrimary)
                            .tracking(0.5)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.appPrimary.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
                Text("\(walkCount) walk\(walkCount == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            Image(systemName: "figure.walk")
                .font(.system(size: 18))
                .foregroundStyle(Color.routeColor(for: profile.id).opacity(0.7))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

// MARK: - Create Group Sheet

private struct CreateGroupSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @State private var name = ""
    @State private var description = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    GroupFormField(icon: "tag.fill", placeholder: "Club name", text: $name, isMultiline: false)
                    GroupFormField(icon: "text.alignleft", placeholder: "What is this club about?", text: $description, isMultiline: true)

                    if let error = groupVM.errorMessage {
                        Text(error).font(.caption).foregroundStyle(Color.appError)
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Create Club")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.appTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await groupVM.createGroup(name: name, description: description, profileVM: profileVM, userId: authVM.userId)
                            if groupVM.group != nil { dismiss() }
                        }
                    } label: {
                        if groupVM.isLoading {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                        } else {
                            Text("Create").bold().foregroundStyle(Color.appPrimary)
                        }
                    }
                    .disabled(name.isEmpty || groupVM.isLoading)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Join Group Sheet

private struct JoinGroupSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @State private var code = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 48))
                            .foregroundStyle(Color.appPrimary)

                        Text("Enter the invite code\nshared by your group.")
                            .font(.system(size: 15))
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }
                    .padding(.top, 20)

                    TextField("", text: $code)
                        .placeholder(when: code.isEmpty) {
                            Text("XXXXXXXX")
                                .font(.system(size: 34, weight: .black, design: .monospaced))
                                .foregroundStyle(Color.appTextSecondary.opacity(0.3))
                                .tracking(6)
                        }
                        .font(.system(size: 34, weight: .black, design: .monospaced))
                        .foregroundStyle(Color.appPrimary)
                        .tracking(6)
                        .multilineTextAlignment(.center)
                        .autocorrectionDisabled()
                        .textCase(.uppercase)
                        .padding(20)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)

                    if let error = groupVM.errorMessage {
                        Text(error).font(.caption).foregroundStyle(Color.appError)
                    }
                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Join Club")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundStyle(Color.appTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await groupVM.joinGroup(inviteCode: code.uppercased(), profileVM: profileVM, userId: authVM.userId)
                            if groupVM.group != nil { dismiss() }
                        }
                    } label: {
                        if groupVM.isLoading {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                        } else {
                            Text("Join").bold().foregroundStyle(Color.appPrimary)
                        }
                    }
                    .disabled(code.count < 4 || groupVM.isLoading)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Helpers

private struct GroupFormField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isMultiline: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(Color.appPrimary)
                .frame(width: 20)
                .padding(.top, 2)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.5))
                }
                if isMultiline {
                    TextField("", text: $text, axis: .vertical)
                        .lineLimit(3...6)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appTextPrimary)
                        .tint(.appPrimary)
                } else {
                    TextField("", text: $text)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appTextPrimary)
                        .tint(.appPrimary)
                }
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }
}

private extension View {
    func placeholder<C: View>(when show: Bool, @ViewBuilder placeholder: () -> C) -> some View {
        ZStack(alignment: .center) {
            if show { placeholder() }
            self
        }
    }
}
