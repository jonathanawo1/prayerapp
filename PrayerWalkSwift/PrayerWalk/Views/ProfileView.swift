// ProfileView.swift
// PrayerWalk

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var walksVM: WalksViewModel
    @EnvironmentObject var groupVM: GroupViewModel

    @State private var isEditingName: Bool = false
    @State private var editedName: String = ""

    private var userWalks: [Walk] {
        walksVM.walks.filter { $0.userId == authVM.userId }
    }

    private var totalDistance: Double { userWalks.reduce(0) { $0 + $1.distance } }
    private var totalDuration: Int { userWalks.reduce(0) { $0 + $1.duration } }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 0) {
                        // Avatar + Name
                        VStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.appPrimary.opacity(0.2))
                                    .frame(width: 88, height: 88)
                                Image(systemName: "figure.walk")
                                    .font(.system(size: 40))
                                    .foregroundColor(.appPrimary)
                            }

                            if isEditingName {
                                HStack(spacing: 8) {
                                    TextField("Display Name", text: $editedName)
                                        .font(.title2.bold())
                                        .multilineTextAlignment(.center)
                                        .foregroundColor(.appTextPrimary)
                                        .textFieldStyle(.roundedBorder)

                                    Button {
                                        Task {
                                            await profileVM.updateDisplayName(editedName, userId: authVM.userId)
                                            isEditingName = false
                                        }
                                    } label: {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.appSuccess)
                                            .font(.title2)
                                    }

                                    Button {
                                        isEditingName = false
                                    } label: {
                                        Image(systemName: "xmark.circle.fill")
                                            .foregroundColor(.appTextSecondary)
                                            .font(.title2)
                                    }
                                }
                                .padding(.horizontal, 32)
                            } else {
                                HStack(spacing: 8) {
                                    Text(profileVM.profile?.displayName ?? "Walker")
                                        .font(.title2.bold())
                                        .foregroundColor(.appTextPrimary)
                                    Button {
                                        editedName = profileVM.profile?.displayName ?? ""
                                        isEditingName = true
                                    } label: {
                                        Image(systemName: "pencil.circle")
                                            .foregroundColor(.appTextSecondary)
                                    }
                                }
                            }

                            if let group = groupVM.group {
                                Label(group.name, systemImage: "person.3.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.appPrimary)
                            }
                        }
                        .padding(.vertical, 28)

                        // Stats
                        HStack(spacing: 1) {
                            ProfileStatBox(label: "Walks", value: "\(userWalks.count)")
                            Divider().background(Color.appSeparator)
                            ProfileStatBox(label: "Distance", value: formatDistance(totalDistance))
                            Divider().background(Color.appSeparator)
                            ProfileStatBox(label: "Time", value: formatDuration(totalDuration))
                        }
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)
                        .padding(.bottom, 28)

                        // Walk history
                        if !userWalks.isEmpty {
                            VStack(alignment: .leading, spacing: 10) {
                                Text("Walk History")
                                    .font(.caption.bold())
                                    .foregroundColor(.appTextSecondary)
                                    .textCase(.uppercase)
                                    .padding(.horizontal, 20)

                                ForEach(userWalks) { walk in
                                    WalkHistoryRow(walk: walk)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Sign Out
                        Button(role: .destructive) {
                            Task { await authVM.signOut() }
                        } label: {
                            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                                .background(Color.appError.opacity(0.12))
                                .foregroundColor(.appError)
                                .font(.system(size: 15, weight: .semibold))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .padding(.horizontal, 20)
                        }
                        .padding(.top, 32)
                        .padding(.bottom, 40)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .onAppear {
            Task { await profileVM.fetchProfile(userId: authVM.userId) }
        }
    }
}

private struct ProfileStatBox: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.appTextPrimary)
            Text(label)
                .font(.caption)
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private struct WalkHistoryRow: View {
    let walk: Walk

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.appPrimary.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "figure.walk")
                    .foregroundColor(.appPrimary)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(walk.title ?? "Prayer Walk")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.appTextPrimary)
                    .lineLimit(1)
                Text("\(formatDistance(walk.distance)) • \(formatDuration(walk.duration))")
                    .font(.caption)
                    .foregroundColor(.appTextSecondary)
            }

            Spacer()

            Text(shortDate(walk.startTime))
                .font(.caption2)
                .foregroundColor(.appTextSecondary)
        }
        .padding(12)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func shortDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = f.date(from: iso)
        if date == nil {
            f.formatOptions = [.withInternetDateTime]
            date = f.date(from: iso)
        }
        guard let date else { return "" }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: date)
    }
}
