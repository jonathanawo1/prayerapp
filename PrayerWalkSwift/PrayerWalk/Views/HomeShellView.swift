// HomeShellView.swift
// PrayerWalk

import SwiftUI

struct HomeShellView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var walksVM: WalksViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var groupVM: GroupViewModel

    @StateObject private var locationService = LocationService()
    @State private var selectedTab: Int = 0
    @State private var showActiveWalk: Bool = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                FeedView()
                    .tabItem {
                        Label("Feed", systemImage: "list.bullet")
                    }
                    .tag(0)

                CommunityMapView(walks: walksVM.walks)
                    .tabItem {
                        Label("Map", systemImage: "map")
                    }
                    .tag(1)

                GroupView()
                    .tabItem {
                        Label("Groups", systemImage: "person.3")
                    }
                    .tag(2)

                ProfileView()
                    .tabItem {
                        Label("Profile", systemImage: "person")
                    }
                    .tag(3)
            }
            .tint(.appPrimary)
            .preferredColorScheme(.dark)

            // FAB
            Button {
                showActiveWalk = true
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.appPrimary)
                        .frame(width: 58, height: 58)
                        .shadow(color: Color.appPrimary.opacity(0.5), radius: 12, x: 0, y: 4)
                    Image(systemName: "figure.walk")
                        .font(.system(size: 24, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .padding(.bottom, 70)
            .fullScreenCover(isPresented: $showActiveWalk) {
                ActiveWalkView(locationService: locationService)
            }
        }
        .onAppear {
            configureTabBarAppearance()
            Task {
                await walksVM.fetchWalks()
                await profileVM.fetchProfile(userId: authVM.userId)
                if let groupId = profileVM.profile?.groupId {
                    await groupVM.fetchGroup(id: groupId)
                }
            }
        }
    }

    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.appSurface)
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
