// ContentView.swift
// PrayerWalk

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {
        SwiftUI.Group {
            if authVM.isAuthenticated {
                HomeShellView()
            } else {
                AuthView()
            }
        }
        .onAppear {
            authVM.checkSession()
        }
        .preferredColorScheme(.dark)
    }
}
