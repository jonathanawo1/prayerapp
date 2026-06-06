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
                    // Filter Picker
                    Picker("Period", selection: $walksVM.selectedFilter) {
                        ForEach(WalkPeriodFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if walksVM.isLoading {
                        Spacer()
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .appPrimary))
                        Spacer()
                    } else if walksVM.filteredWalks.isEmpty {
                        Spacer()
                        VStack(spacing: 16) {
                            Image(systemName: "figure.walk.circle")
                                .font(.system(size: 60))
                                .foregroundColor(.appTextSecondary)
                            Text("No walks yet")
                                .font(.title3.bold())
                                .foregroundColor(.appTextPrimary)
                            Text("Start your first prayer walk\nusing the button below.")
                                .font(.subheadline)
                                .foregroundColor(.appTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        Spacer()
                    } else {
                        List {
                            ForEach(walksVM.filteredWalks) { walk in
                                WalkFeedCard(walk: walk)
                                    .listRowBackground(Color.appBackground)
                                    .listRowSeparator(.hidden)
                                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.appBackground)
                        .refreshable {
                            await walksVM.fetchWalks()
                        }
                    }
                }
            }
            .navigationTitle("Prayer Walks")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let error = walksVM.errorMessage {
                        Image(systemName: "exclamationmark.circle")
                            .foregroundColor(.appError)
                            .help(error)
                    }
                }
            }
        }
    }
}
