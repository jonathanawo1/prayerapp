// PrayerWalkApp.swift
// PrayerWalk

import SwiftUI

@main
struct PrayerWalkApp: App {
    @StateObject private var authVM = AuthViewModel()
    @StateObject private var walksVM = WalksViewModel()
    @StateObject private var profileVM = ProfileViewModel()
    @StateObject private var groupVM = GroupViewModel()

    @State private var recoveryToken: String?

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authVM)
                .environmentObject(walksVM)
                .environmentObject(profileVM)
                .environmentObject(groupVM)
                .preferredColorScheme(.dark)
                .sheet(isPresented: Binding(
                    get: { recoveryToken != nil },
                    set: { if !$0 { recoveryToken = nil } }
                )) {
                    if let token = recoveryToken {
                        ResetPasswordView(recoveryToken: token)
                    }
                }
                .onOpenURL { url in
                    handleDeepLink(url)
                }
        }
    }

    private func handleDeepLink(_ url: URL) {
        // Supabase sends: prayerwalk://reset-password#access_token=xxx&type=recovery
        guard url.scheme == "prayerwalk" else { return }
        // Parse fragment or query for access_token
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        // Fragment comes as query items when using URLComponents on fragments
        let fragmentString = url.fragment ?? ""
        var params: [String: String] = [:]
        for pair in fragmentString.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            if kv.count == 2 {
                params[String(kv[0])] = String(kv[1])
            }
        }
        // Also check query items
        for item in components?.queryItems ?? [] {
            if let value = item.value { params[item.name] = value }
        }
        if let token = params["access_token"], params["type"] == "recovery" {
            recoveryToken = token
        }
    }
}

