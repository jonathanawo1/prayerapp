// GroupView.swift
// PrayerWalk

import SwiftUI

struct GroupView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var walksVM: WalksViewModel

    @State private var showCreateSheet: Bool = false
    @State private var showJoinSheet: Bool = false

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if groupVM.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                } else if let group = groupVM.group {
                    GroupDetailView(group: group)
                } else {
                    NoGroupView(
                        showCreate: $showCreateSheet,
                        showJoin: $showJoinSheet
                    )
                }
            }
            .navigationTitle("My Group")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showCreateSheet) {
                CreateGroupSheet()
            }
            .sheet(isPresented: $showJoinSheet) {
                JoinGroupSheet()
            }
        }
    }
}

// MARK: - No Group

private struct NoGroupView: View {
    @Binding var showCreate: Bool
    @Binding var showJoin: Bool

    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "person.3.sequence")
                .font(.system(size: 64))
                .foregroundColor(.appTextSecondary)

            VStack(spacing: 8) {
                Text("No Group Yet")
                    .font(.title2.bold())
                    .foregroundColor(.appTextPrimary)
                Text("Create a group to pray together\nor join one with an invite code.")
                    .font(.subheadline)
                    .foregroundColor(.appTextSecondary)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: 12) {
                Button {
                    showCreate = true
                } label: {
                    Label("Create a Group", systemImage: "plus.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appPrimary)
                        .foregroundColor(.white)
                        .font(.system(size: 16, weight: .semibold))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }

                Button {
                    showJoin = true
                } label: {
                    Label("Join with Invite Code", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appSurface)
                        .foregroundColor(.appTextPrimary)
                        .font(.system(size: 16, weight: .semibold))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            }
            .padding(.horizontal, 32)
        }
        .padding()
    }
}

// MARK: - Group Detail

private struct GroupDetailView: View {
    let group: Group
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var walksVM: WalksViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel
    @State private var showCopied: Bool = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Group header
                VStack(alignment: .leading, spacing: 6) {
                    Text(group.name)
                        .font(.title.bold())
                        .foregroundColor(.appTextPrimary)
                    if !group.description.isEmpty {
                        Text(group.description)
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                // Invite code
                VStack(alignment: .leading, spacing: 8) {
                    Text("Invite Code")
                        .font(.caption.bold())
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 20)

                    Button {
                        UIPasteboard.general.string = group.inviteCode
                        showCopied = true
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { showCopied = false }
                    } label: {
                        HStack {
                            Text(group.inviteCode)
                                .font(.system(size: 22, weight: .bold, design: .monospaced))
                                .foregroundColor(.appPrimary)
                            Spacer()
                            Image(systemName: showCopied ? "checkmark.circle.fill" : "doc.on.doc")
                                .foregroundColor(showCopied ? .appSuccess : .appTextSecondary)
                            Text(showCopied ? "Copied!" : "Copy")
                                .font(.subheadline)
                                .foregroundColor(showCopied ? .appSuccess : .appTextSecondary)
                        }
                        .padding(16)
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                    }
                }

                // Members
                VStack(alignment: .leading, spacing: 10) {
                    Text("Members (\(groupVM.members.count))")
                        .font(.caption.bold())
                        .foregroundColor(.appTextSecondary)
                        .textCase(.uppercase)
                        .padding(.horizontal, 20)

                    ForEach(groupVM.members) { member in
                        let memberWalks = walksVM.walks.filter { $0.userId == member.id }
                        MemberRow(profile: member, walkCount: memberWalks.count)
                            .padding(.horizontal, 20)
                    }
                }

                // Leave group
                Button(role: .destructive) {
                    Task {
                        await groupVM.leaveGroup(profileVM: profileVM, userId: authVM.userId)
                    }
                } label: {
                    Label("Leave Group", systemImage: "rectangle.portrait.and.arrow.right")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appError.opacity(0.15))
                        .foregroundColor(.appError)
                        .font(.system(size: 15, weight: .semibold))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal, 20)
                }
                .padding(.top, 12)
                .padding(.bottom, 32)
            }
        }
        .background(Color.appBackground)
        .onAppear {
            Task { await groupVM.fetchMembers() }
        }
    }
}

private struct MemberRow: View {
    let profile: Profile
    let walkCount: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.routeColor(for: profile.id))
                    .frame(width: 40, height: 40)
                Text(String(profile.displayName.prefix(1)).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(profile.displayName)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(.appTextPrimary)
                Text("\(walkCount) walk\(walkCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }
            Spacer()
            Image(systemName: "figure.walk")
                .foregroundColor(.appTextSecondary)
        }
        .padding(12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Create Group Sheet

private struct CreateGroupSheet: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var groupVM: GroupViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var authVM: AuthViewModel

    @State private var name: String = ""
    @State private var description: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Group Name")
                            .font(.caption.bold())
                            .foregroundColor(.appTextSecondary)
                        TextField("", text: $name)
                            .placeholder(when: name.isEmpty) { Text("e.g. Downtown Prayer Warriors").foregroundColor(.appTextSecondary) }
                            .padding(14)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.appTextPrimary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.caption.bold())
                            .foregroundColor(.appTextSecondary)
                        TextField("", text: $description, axis: .vertical)
                            .placeholder(when: description.isEmpty) { Text("What is this group about?").foregroundColor(.appTextSecondary) }
                            .lineLimit(3...6)
                            .padding(14)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.appTextPrimary)
                    }

                    if let error = groupVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.appError)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.appTextSecondary)
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
                            Text("Create").bold().foregroundColor(.appPrimary)
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

    @State private var inviteCode: String = ""

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Invite Code")
                            .font(.caption.bold())
                            .foregroundColor(.appTextSecondary)
                        TextField("", text: $inviteCode)
                            .placeholder(when: inviteCode.isEmpty) { Text("8-character code").foregroundColor(.appTextSecondary) }
                            .textCase(.uppercase)
                            .autocorrectionDisabled()
                            .autocapitalization(.allCharacters)
                            .font(.system(size: 22, weight: .bold, design: .monospaced))
                            .padding(14)
                            .background(Color.appSurface)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            .foregroundColor(.appPrimary)
                    }

                    if let error = groupVM.errorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.appError)
                    }

                    Spacer()
                }
                .padding(20)
            }
            .navigationTitle("Join Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.foregroundColor(.appTextSecondary)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task {
                            await groupVM.joinGroup(inviteCode: inviteCode, profileVM: profileVM, userId: authVM.userId)
                            if groupVM.group != nil { dismiss() }
                        }
                    } label: {
                        if groupVM.isLoading {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                        } else {
                            Text("Join").bold().foregroundColor(.appPrimary)
                        }
                    }
                    .disabled(inviteCode.count < 4 || groupVM.isLoading)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

private extension View {
    func placeholder<Content: View>(when shouldShow: Bool, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow { placeholder() }
            self
        }
    }
}
