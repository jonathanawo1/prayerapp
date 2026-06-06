// FeedView.swift
// PrayerWalk

import SwiftUI

struct FeedView: View {
    @EnvironmentObject var walksVM: WalksViewModel
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(WalkPeriodFilter.allCases) { filter in
                                FilterChip(
                                    title: filter.rawValue,
                                    isSelected: walksVM.selectedFilter == filter
                                ) {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        walksVM.selectedFilter = filter
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                    }

                    if walksVM.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                            .scaleEffect(1.2)
                        Spacer()
                    } else if walksVM.filteredWalks.isEmpty {
                        EmptyFeedView()
                    } else {
                        ScrollView(showsIndicators: false) {
                            LazyVStack(spacing: 2) {
                                ForEach(walksVM.filteredWalks) { walk in
                                    WalkFeedCard(walk: walk)
                                }
                            }
                            .padding(.bottom, 100)
                        }
                        .refreshable { await walksVM.fetchWalks() }
                    }
                }
            }
            .navigationTitle("Prayer Walks")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Filter Chip

private struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 13, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? .white : Color.appTextSecondary)
                .padding(.horizontal, 16)
                .padding(.vertical, 7)
                .background(
                    Capsule()
                        .fill(isSelected ? Color.appPrimary : Color.appSurface)
                )
        }
    }
}

// MARK: - Empty State

private struct EmptyFeedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.appSurface)
                    .frame(width: 100, height: 100)
                Image(systemName: "figure.walk.circle")
                    .font(.system(size: 50))
                    .foregroundStyle(Color.appTextSecondary.opacity(0.4))
            }
            VStack(spacing: 8) {
                Text("No walks yet")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(Color.appTextPrimary)
                Text("Tap the orange button below\nto start your first prayer walk.")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.appTextSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
            }
            Spacer()
        }
    }
}
