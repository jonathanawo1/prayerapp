// WalkSummaryView.swift
// PrayerWalk

import SwiftUI

struct WalkSummaryView: View {
    let draft: WalkDraft
    let onDismiss: () -> Void

    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var walksVM: WalksViewModel

    @State private var title: String = ""
    @State private var prayerNotes: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String?
    @State private var saved: Bool = false

    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Header badge
                        ZStack {
                            Circle()
                                .fill(Color.appPrimary.opacity(0.15))
                                .frame(width: 80, height: 80)
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundColor(.appPrimary)
                        }
                        .padding(.top, 24)

                        Text("Walk Complete!")
                            .font(.title.bold())
                            .foregroundColor(.appTextPrimary)

                        // Stats row
                        HStack(spacing: 1) {
                            SummaryStatBox(label: "Distance", value: formatDistance(draft.distance), icon: "arrow.triangle.swap")
                            Divider().background(Color.appSeparator)
                            SummaryStatBox(label: "Duration", value: formatDuration(draft.duration), icon: "clock.fill")
                            Divider().background(Color.appSeparator)
                            SummaryStatBox(label: "Pace", value: formatPace(distanceMeters: draft.distance, durationSeconds: draft.duration), icon: "speedometer")
                        }
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal, 20)

                        // Title field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Title (Optional)")
                                .font(.caption.bold())
                                .foregroundColor(.appTextSecondary)

                            TextField("", text: $title)
                                .placeholder(when: title.isEmpty) {
                                    Text("e.g. Morning neighborhood walk").foregroundColor(.appTextSecondary)
                                }
                                .padding(14)
                                .background(Color.appSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.appTextPrimary)
                        }
                        .padding(.horizontal, 20)

                        // Prayer notes field
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Prayer Notes (Optional)", systemImage: "hands.sparkles")
                                .font(.caption.bold())
                                .foregroundColor(.appTextSecondary)

                            TextField("", text: $prayerNotes, axis: .vertical)
                                .placeholder(when: prayerNotes.isEmpty) {
                                    Text("What did you pray for?").foregroundColor(.appTextSecondary)
                                }
                                .lineLimit(4...10)
                                .padding(14)
                                .background(Color.appSurface)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .foregroundColor(.appTextPrimary)
                        }
                        .padding(.horizontal, 20)

                        if let error = errorMessage {
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.appError)
                                .padding(.horizontal, 20)
                        }

                        // Buttons
                        VStack(spacing: 12) {
                            Button {
                                Task { await saveDraft() }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(Color.appPrimary)
                                        .frame(height: 52)
                                    if isSaving {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Label("Save Walk", systemImage: "square.and.arrow.down")
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .disabled(isSaving)

                            Button {
                                dismiss()
                                onDismiss()
                            } label: {
                                Text("Discard")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.appTextSecondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 32)
                    }
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark)
    }

    private func saveDraft() async {
        isSaving = true
        errorMessage = nil
        var updatedDraft = draft
        updatedDraft.title = title
        updatedDraft.prayerNotes = prayerNotes

        do {
            _ = try await walksVM.saveWalk(
                draft: updatedDraft,
                userId: authVM.userId,
                groupId: profileVM.profile?.groupId
            )
            dismiss()
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

private struct SummaryStatBox: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.appPrimary)
            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.appTextPrimary)
            Text(label)
                .font(.caption2)
                .foregroundColor(.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
    }
}

private extension View {
    func placeholder<Content: View>(when shouldShow: Bool, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow { placeholder().padding(.horizontal, 14) }
            self
        }
    }
}
