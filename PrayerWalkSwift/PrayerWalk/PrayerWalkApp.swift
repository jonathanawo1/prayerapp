// PrayerWalkApp.swift
// PrayerWalk

import SwiftUI

@main
struct PrayerWalkApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var walksVM = WalksViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var groupVM = GroupViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .environmentObject(walksVM)
                .environmentObject(profileVM)
                .environmentObject(groupVM)
                .preferredColorScheme(.dark)
        }
    }
}
