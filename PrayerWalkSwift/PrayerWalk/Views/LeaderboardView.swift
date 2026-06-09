// LeaderboardView.swift
// PrayerWalk

import SwiftUI

private enum LeaderboardSort: String, CaseIterable {
    case distance = "Distance"
    case walks = "Walks"
}

private struct MemberStats: Identifiable {
    let profile: Profile
    let totalDistance: Double
    let walkCount: Int
    var id: String { profile.id }
}

struct LeaderboardView: View {
    @EnvironmentObject var walksVM: WalksViewModel
    @EnvironmentObject var groupVM: GroupViewModel

    @State private var sort: LeaderboardSort = .distance

    private var ranked: [MemberStats] {
        groupVM.members.map { member in
            let memberWalks = walksVM.walks.filter { $0.userId == member.id }
            return MemberStats(
                profile: member,
                totalDistance: memberWalks.reduce(0) { $0 + $1.distance },
                walkCount: memberWalks.count
            )
        }
        .sorted {
            switch sort {
            case .distance: return $0.totalDistance > $1.totalDistance
            case .walks: return $0.walkCount > $1.walkCount
            }
        }
    }

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            if groupVM.group == nil {
                VStack(spacing: 16) {
                    Image(systemName: "trophy.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.3))
                    Text("Join a branch to see the leaderboard")
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appTextSecondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                VStack(spacing: 0) {
                    HStack(spacing: 0) {
                        ForEach(LeaderboardSort.allCases, id: \.rawValue) { s in
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { sort = s }
                            } label: {
                                Text(s.rawValue)
                                    .font(.system(size: 13, weight: sort == s ? .bold : .medium))
                                    .foregroundStyle(sort == s ? Color.appTextPrimary : Color.appTextSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 9)
                                    .background(
                                        RoundedRectangle(cornerRadius: 9)
                                            .fill(sort == s ? Color.appSurface : Color.clear)
                                    )
                                    .padding(3)
                            }
                        }
                    }
                    .background(Color.appBackground.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 14)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(Array(ranked.enumerated()), id: \.element.id) { index, stats in
                                LeaderRow(rank: index + 1, stats: stats, sort: sort)
                                    .padding(.horizontal, 20)
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
        }
        .navigationTitle("Leaderboard")
        .navigationBarTitleDisplayMode(.large)
        .preferredColorScheme(.dark)
    }
}

private struct LeaderRow: View {
    let rank: Int
    let stats: MemberStats
    let sort: LeaderboardSort

    var rankColor: Color {
        switch rank {
        case 1: return Color(hex: "FFD700")
        case 2: return Color(hex: "C0C0C0")
        case 3: return Color(hex: "CD7F32")
        default: return Color.appTextSecondary
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                if rank <= 3 {
                    Circle()
                        .fill(rankColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Text(rank == 1 ? "🥇" : rank == 2 ? "🥈" : "🥉")
                        .font(.system(size: 18))
                } else {
                    Circle()
                        .fill(Color.appSurface)
                        .frame(width: 36, height: 36)
                    Text("\(rank)")
                        .font(.system(size: 14, weight: .black))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }

            ZStack {
                Circle()
                    .fill(Color.routeColor(for: stats.profile.id))
                    .frame(width: 42, height: 42)
                Text(String(stats.profile.displayName.prefix(2)).uppercased())
                    .font(.system(size: 15, weight: .black))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(stats.profile.displayName)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                Text("\(stats.walkCount) walk\(stats.walkCount == 1 ? "" : "s")")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(sort == .distance ? formatDistance(stats.totalDistance) : "\(stats.walkCount)")
                    .font(.system(size: 18, weight: .black, design: .rounded))
                    .foregroundStyle(rank <= 3 ? rankColor : Color.appTextPrimary)
                Text(sort == .distance ? "km" : "walks")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(Color.appTextSecondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}
