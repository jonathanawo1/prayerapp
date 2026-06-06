// ProfileView.swift
// PrayerWalk

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var walksVM: WalksViewModel
    @EnvironmentObject var groupVM: GroupViewModel

    @State private var isEditingName = false
    @State private var editedName = ""

    private var userWalks: [Walk] { walksVM.walks.filter { $0.userId == authVM.userId } }
    private var totalDistance: Double { userWalks.reduce(0) { $0 + $1.distance } }
    private var totalDuration: Int { userWalks.reduce(0) { $0 + $1.duration } }
    private var displayName: String { profileVM.profile?.displayName ?? "Walker" }
    private var initials: String { String(displayName.prefix(2)).uppercased() }

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        // Hero header
                        ZStack(alignment: .bottom) {
                            // Background gradient
                            LinearGradient(
                                colors: [Color(hex: "0F1F3D"), Color.appBackground],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                            .frame(height: 220)

                            VStack(spacing: 14) {
                                // Avatar
                                ZStack {
                                    Circle()
                                        .fill(Color.routeColor(for: authVM.userId))
                                        .frame(width: 88, height: 88)
                                    Text(initials)
                                        .font(.system(size: 32, weight: .black))
                                        .foregroundStyle(.white)
                                }
                                .overlay(
                                    Circle()
                                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 2)
                                )
                                .shadow(color: Color.appPrimary.opacity(0.3), radius: 20, x: 0, y: 8)

                                // Name
                                if isEditingName {
                                    HStack(spacing: 10) {
                                        TextField("Display Name", text: $editedName)
                                            .font(.system(size: 22, weight: .black))
                                            .foregroundStyle(Color.appTextPrimary)
                                            .multilineTextAlignment(.center)
                                            .autocorrectionDisabled()
                                            .frame(maxWidth: 200)

                                        Button {
                                            Task {
                                                await profileVM.updateDisplayName(editedName, userId: authVM.userId)
                                                isEditingName = false
                                            }
                                        } label: {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(Color.appSuccess)
                                        }

                                        Button {
                                            isEditingName = false
                                        } label: {
                                            Image(systemName: "xmark.circle.fill")
                                                .font(.title2)
                                                .foregroundStyle(Color.appTextSecondary)
                                        }
                                    }
                                } else {
                                    Button {
                                        editedName = displayName
                                        isEditingName = true
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(displayName)
                                                .font(.system(size: 22, weight: .black))
                                                .foregroundStyle(Color.appTextPrimary)
                                            Image(systemName: "pencil")
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundStyle(Color.appTextSecondary.opacity(0.6))
                                        }
                                    }
                                }

                                if let group = groupVM.group {
                                    HStack(spacing: 5) {
                                        Image(systemName: "person.3.fill")
                                            .font(.system(size: 11))
                                        Text(group.name)
                                            .font(.system(size: 13, weight: .semibold))
                                    }
                                    .foregroundStyle(Color.appPrimary)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 5)
                                    .background(Color.appPrimary.opacity(0.12))
                                    .clipShape(Capsule())
                                }
                            }
                            .padding(.bottom, 24)
                        }

                        // Stats grid
                        HStack(spacing: 1) {
                            BigStat(value: "\(userWalks.count)", label: "WALKS", icon: "figure.walk")
                            Rectangle().fill(Color.appSeparator).frame(width: 1)
                            BigStat(value: formatDistance(totalDistance), label: "TOTAL", icon: "arrow.left.and.right")
                            Rectangle().fill(Color.appSeparator).frame(width: 1)
                            BigStat(value: formatDuration(totalDuration), label: "TIME", icon: "clock.fill")
                        }
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 20)
                        .padding(.top, -1)
                        .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 4)

                        // Walk history
                        if !userWalks.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text("Walk History")
                                        .font(.system(size: 13, weight: .black))
                                        .foregroundStyle(Color.appTextSecondary)
                                        .textCase(.uppercase)
                                        .tracking(0.8)
                                    Spacer()
                                    Text("\(userWalks.count) walks")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundStyle(Color.appTextSecondary.opacity(0.6))
                                }
                                .padding(.horizontal, 20)
                                .padding(.top, 28)

                                ForEach(userWalks) { walk in
                                    WalkHistoryCard(walk: walk)
                                        .padding(.horizontal, 20)
                                }
                            }
                        }

                        // Sign out
                        Button(role: .destructive) {
                            Task { await authVM.signOut() }
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
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
                        .padding(.top, 28)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            Task { await profileVM.fetchProfile(userId: authVM.userId) }
        }
    }
}

// MARK: - Big Stat

private struct BigStat: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
            Text(value)
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundStyle(Color.appTextSecondary)
                .tracking(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }
}

// MARK: - Walk History Card

private struct WalkHistoryCard: View {
    let walk: Walk
    @State private var show = false

    var body: some View {
        Button { show = true } label: {
            HStack(spacing: 14) {
                // Color accent bar
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.routeColor(for: walk.userId))
                    .frame(width: 4, height: 48)

                VStack(alignment: .leading, spacing: 3) {
                    Text(walk.title ?? "Prayer Walk")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(Color.appTextPrimary)
                        .lineLimit(1)
                    Text("\(formatDistance(walk.distance))  •  \(formatDuration(walk.duration))")
                        .font(.system(size: 12))
                        .foregroundStyle(Color.appTextSecondary)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 3) {
                    Text(shortDate(walk.startTime))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.appTextSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.4))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $show) {
            WalkDetailSheet(walk: walk)
        }
    }

    private func shortDate(_ iso: String) -> String {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        var date = f.date(from: iso)
        if date == nil { f.formatOptions = [.withInternetDateTime]; date = f.date(from: iso) }
        guard let date else { return "" }
        let df = DateFormatter()
        df.dateFormat = "MMM d"
        return df.string(from: date)
    }
}
