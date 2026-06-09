// AuthViewModel.swift
// PrayerWalk

import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userId: String = ""
    @Published var email: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let supabase = SupabaseService.shared
    private var sessionObserver: NSObjectProtocol?

    init() {
        sessionObserver = NotificationCenter.default.addObserver(
            forName: NSNotification.Name("pw_session_expired"),
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.isAuthenticated = false
            self?.userId = ""
            self?.email = ""
        }
    }

    deinit {
        if let obs = sessionObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    func checkSession() {
        isAuthenticated = supabase.restoreSession()
        userId = supabase.userId ?? ""
        email = supabase.userEmail ?? ""
    }

    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await supabase.signIn(email: email, password: password)
            userId = supabase.userId ?? ""
            self.email = email
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await supabase.signUp(email: email, password: password)
            userId = supabase.userId ?? ""
            self.email = email
            isAuthenticated = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func signOut() async {
        isLoading = true
        defer { isLoading = false }
        try? await supabase.signOut()
        isAuthenticated = false
        userId = ""
    }
}
