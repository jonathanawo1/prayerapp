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
    @State private var fabPressed = false

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                FeedView()
                    .tabItem {
                        Label("Feed", systemImage: selectedTab == 0 ? "list.bullet.rectangle.fill" : "list.bullet.rectangle")
                    }
                    .tag(0)

                CommunityMapView(walks: walksVM.walks)
                    .tabItem {
                        Label("Map", systemImage: selectedTab == 1 ? "map.fill" : "map")
                    }
                    .tag(1)

                GroupView()
                    .tabItem {
                        Label("Club", systemImage: selectedTab == 2 ? "person.3.fill" : "person.3")
                    }
                    .tag(2)

                ProfileView()
                    .tabItem {
                        Label("You", systemImage: selectedTab == 3 ? "person.crop.circle.fill" : "person.crop.circle")
                    }
                    .tag(3)
            }
            .tint(.appPrimary)
            .preferredColorScheme(.dark)

            // Record FAB — sits above the tab bar
            Button {
                withAnimation(.spring(response: 0.25, dampingFraction: 0.6)) {
                    fabPressed = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    fabPressed = false
                    showActiveWalk = true
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "FF6B35"), Color.appPrimary],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 62, height: 62)
                        .shadow(color: Color.appPrimary.opacity(0.55), radius: 18, x: 0, y: 6)

                    Image(systemName: "figure.walk")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .scaleEffect(fabPressed ? 0.92 : 1.0)
            }
            .offset(y: -30)
            .fullScreenCover(isPresented: $showActiveWalk) {
                ActiveWalkView(locationService: locationService)
            }
        }
        .onAppear {
            configureAppearances()
            Task {
                await walksVM.fetchWalks()
                await profileVM.ensureProfile(userId: authVM.userId, email: authVM.email)
                if let groupId = profileVM.profile?.groupId {
                    await groupVM.fetchGroup(id: groupId)
                    await groupVM.fetchMembers()
                }
            }
        }
    }

    private func configureAppearances() {
        // Tab bar
        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundColor = UIColor(Color(hex: "0F1B2E"))
        tabAppearance.shadowImage = UIImage()
        tabAppearance.shadowColor = nil

        let normalAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.appTextSecondary.opacity(0.6))
        ]
        let selectedAttr: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.appPrimary)
        ]
        tabAppearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttr
        tabAppearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttr
        tabAppearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.appTextSecondary.opacity(0.6))
        tabAppearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.appPrimary)

        UITabBar.appearance().standardAppearance = tabAppearance
        UITabBar.appearance().scrollEdgeAppearance = tabAppearance

        // Navigation bar
        let navAppearance = UINavigationBarAppearance()
        navAppearance.configureWithOpaqueBackground()
        navAppearance.backgroundColor = UIColor(Color(hex: "0A1628"))
        navAppearance.shadowColor = nil
        navAppearance.largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.appTextPrimary),
            .font: UIFont.systemFont(ofSize: 32, weight: .black)
        ]
        navAppearance.titleTextAttributes = [
            .foregroundColor: UIColor(Color.appTextPrimary),
            .font: UIFont.systemFont(ofSize: 17, weight: .semibold)
        ]
        UINavigationBar.appearance().standardAppearance = navAppearance
        UINavigationBar.appearance().scrollEdgeAppearance = navAppearance
        UINavigationBar.appearance().compactAppearance = navAppearance
    }
}
