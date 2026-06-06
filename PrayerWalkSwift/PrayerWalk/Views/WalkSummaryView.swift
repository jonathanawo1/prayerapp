// WalkSummaryView.swift
// PrayerWalk

import SwiftUI

struct WalkSummaryView: View {
    let draft: WalkDraft
    let onDismiss: () -> Void

    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var profileVM: ProfileViewModel
    @EnvironmentObject var walksVM: WalksViewModel

    @State private var title = ""
    @State private var prayerNotes = ""
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var celebrationScale: CGFloat = 0.3
    @State private var celebrationOpacity: Double = 0

    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Hero celebration section
                    ZStack {
                        // Gradient background
                        LinearGradient(
                            colors: [Color(hex: "1A0A05"), Color.appBackground],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 280)

                        // Concentric glow rings
                        ZStack {
                            Circle()
                                .fill(Color.appPrimary.opacity(0.05))
                                .frame(width: 220, height: 220)
                            Circle()
                                .fill(Color.appPrimary.opacity(0.08))
                                .frame(width: 160, height: 160)
                            Circle()
                                .fill(Color.appPrimary.opacity(0.12))
                                .frame(width: 110, height: 110)

                            // Icon
                            Image(systemName: "figure.walk.circle.fill")
                                .font(.system(size: 64))
                                .foregroundStyle(Color.appPrimary)
                                .scaleEffect(celebrationScale)
                                .opacity(celebrationOpacity)
                        }

                        // Text
                        VStack(spacing: 6) {
                            Spacer()
                            Text("Walk Complete!")
                                .font(.system(size: 28, weight: .black))
                                .foregroundStyle(Color.appTextPrimary)
                                .opacity(celebrationOpacity)
                            Text("Great job. Keep walking in faith.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
                                .opacity(celebrationOpacity)
                        }
                        .padding(.bottom, 24)
                        .frame(height: 280)
                    }

                    VStack(spacing: 20) {
                        // Stats bar
                        HStack(spacing: 1) {
                            SummaryStatCell(
                                value: formatDistance(draft.distance),
                                label: "Distance",
                                icon: "arrow.left.and.right"
                            )
                            Rectangle().fill(Color.appSeparator).frame(width: 1)
                            SummaryStatCell(
                                value: formatDuration(draft.duration),
                                label: "Duration",
                                icon: "clock.fill"
                            )
                            Rectangle().fill(Color.appSeparator).frame(width: 1)
                            SummaryStatCell(
                                value: formatPace(distanceMeters: draft.distance, durationSeconds: draft.duration),
                                label: "Pace",
                                icon: "bolt.fill"
                            )
                        }
                        .background(Color.appSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .padding(.horizontal, 20)

                        // Form fields
                        VStack(spacing: 14) {
                            SummaryField(
                                icon: "tag.fill",
                                placeholder: "Name this walk (optional)",
                                text: $title,
                                isMultiline: false
                            )
                            SummaryField(
                                icon: "hands.sparkles.fill",
                                placeholder: "What did you pray for? (optional)",
                                text: $prayerNotes,
                                isMultiline: true
                            )
                        }
                        .padding(.horizontal, 20)

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13))
                                .foregroundStyle(Color.appError)
                                .padding(.horizontal, 20)
                        }

                        // Save button
                        VStack(spacing: 12) {
                            Button {
                                Task { await saveDraft() }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "FF6B35"), Color.appPrimary],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(height: 56)
                                        .shadow(color: Color.appPrimary.opacity(0.4), radius: 16, x: 0, y: 6)

                                    if isSaving {
                                        ProgressView()
                                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        HStack(spacing: 8) {
                                            Image(systemName: "square.and.arrow.down.fill")
                                                .font(.system(size: 15, weight: .bold))
                                            Text("Save Walk")
                                                .font(.system(size: 17, weight: .black))
                                        }
                                        .foregroundStyle(.white)
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
                                    .foregroundStyle(Color.appTextSecondary)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 48)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6).delay(0.1)) {
                celebrationScale = 1.0
                celebrationOpacity = 1.0
            }
        }
    }

    private func saveDraft() async {
        isSaving = true
        errorMessage = nil
        var d = draft
        d.title = title
        d.prayerNotes = prayerNotes
        do {
            _ = try await walksVM.saveWalk(draft: d, userId: authVM.userId, groupId: profileVM.profile?.groupId)
            dismiss()
            onDismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
        isSaving = false
    }
}

// MARK: - Summary Stat Cell

private struct SummaryStatCell: View {
    let value: String
    let label: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.appPrimary)
            Text(value)
                .font(.system(size: 17, weight: .black, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(Color.appTextSecondary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
    }
}

// MARK: - Summary Field

private struct SummaryField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isMultiline: Bool

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.appPrimary)
                .frame(width: 20)
                .padding(.top, isMultiline ? 1 : 0)

            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.5))
                }
                if isMultiline {
                    TextField("", text: $text, axis: .vertical)
                        .lineLimit(3...8)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appTextPrimary)
                        .tint(.appPrimary)
                } else {
                    TextField("", text: $text)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appTextPrimary)
                        .tint(.appPrimary)
                }
            }
        }
        .padding(16)
        .background(Color.appSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
        )
    }
}
