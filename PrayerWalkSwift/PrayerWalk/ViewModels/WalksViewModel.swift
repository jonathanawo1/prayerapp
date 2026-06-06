// WalksViewModel.swift
// PrayerWalk

import Foundation
import Combine

enum WalkPeriodFilter: String, CaseIterable, Identifiable {
    case today = "Today"
    case thisWeek = "This Week"
    case allTime = "All Time"
    var id: String { rawValue }
}

@MainActor
final class WalksViewModel: ObservableObject {
    @Published var walks: [Walk] = []
    @Published var filteredWalks: [Walk] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var selectedFilter: WalkPeriodFilter = .allTime {
        didSet { applyFilter() }
    }

    private let supabase = SupabaseService.shared
    private var cancellables = Set<AnyCancellable>()

    func fetchWalks() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            walks = try await supabase.walksFetch()
            applyFilter()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveWalk(draft: WalkDraft, userId: String, groupId: String?) async throws -> Walk {
        let insert = draft.toInsert(userId: userId, groupId: groupId)
        let saved = try await supabase.walkInsert(insert)
        walks.insert(saved, at: 0)
        applyFilter()
        return saved
    }

    private func applyFilter() {
        let now = Date()
        let calendar = Calendar.current
        switch selectedFilter {
        case .today:
            let startOfDay = calendar.startOfDay(for: now)
            filteredWalks = walks.filter { walk in
                guard let date = isoDate(walk.startTime) else { return false }
                return date >= startOfDay
            }
        case .thisWeek:
            guard let startOfWeek = calendar.dateInterval(of: .weekOfYear, for: now)?.start else {
                filteredWalks = walks; return
            }
            filteredWalks = walks.filter { walk in
                guard let date = isoDate(walk.startTime) else { return false }
                return date >= startOfWeek
            }
        case .allTime:
            filteredWalks = walks
        }
    }

    private func isoDate(_ string: String) -> Date? {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = f.date(from: string) { return d }
        f.formatOptions = [.withInternetDateTime]
        return f.date(from: string)
    }
}
