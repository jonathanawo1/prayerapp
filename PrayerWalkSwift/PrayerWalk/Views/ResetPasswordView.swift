// ResetPasswordView.swift
// PrayerWalk

import SwiftUI

struct ResetPasswordView: View {
    let recoveryToken: String
    @Environment(\.dismiss) var dismiss

    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var didSucceed = false

    private var isValid: Bool {
        password.count >= 6 && password == confirmPassword
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "060D1A"), Color(hex: "0A1628"), Color(hex: "0F1F3D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer()

                VStack(spacing: 28) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.appPrimary.opacity(0.15))
                            .frame(width: 80, height: 80)
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundStyle(Color.appPrimary)
                    }

                    VStack(spacing: 6) {
                        Text("Set New Password")
                            .font(.system(size: 26, weight: .black))
                            .foregroundStyle(Color.appTextPrimary)
                        Text("Choose a new password for your account.")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }

                    if didSucceed {
                        VStack(spacing: 16) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(Color.appSuccess)
                            Text("Password updated!")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundStyle(Color.appTextPrimary)
                            Text("You can now sign in with your new password.")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.appTextSecondary)
                                .multilineTextAlignment(.center)
                            Button {
                                dismiss()
                            } label: {
                                Text("Done")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                                    .background(
                                        RoundedRectangle(cornerRadius: 14)
                                            .fill(LinearGradient(
                                                colors: [Color(hex: "FF6B35"), Color.appPrimary],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ))
                                    )
                            }
                        }
                        .padding(.top, 8)
                    } else {
                        VStack(spacing: 14) {
                            SecureInputField(placeholder: "New password (min 6 chars)", text: $password)
                            SecureInputField(placeholder: "Confirm new password", text: $confirmPassword)

                            if let error = errorMessage {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 13))
                                    Text(error)
                                        .font(.system(size: 13))
                                    Spacer()
                                }
                                .foregroundStyle(Color.appError)
                            }

                            if !confirmPassword.isEmpty && password != confirmPassword {
                                HStack(spacing: 6) {
                                    Image(systemName: "exclamationmark.circle.fill")
                                        .font(.system(size: 13))
                                    Text("Passwords don't match")
                                        .font(.system(size: 13))
                                    Spacer()
                                }
                                .foregroundStyle(Color.appError)
                            }

                            Button {
                                Task { await resetPassword() }
                            } label: {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 14)
                                        .fill(LinearGradient(
                                            colors: [Color(hex: "FF6B35"), Color.appPrimary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ))
                                        .frame(height: 54)
                                        .shadow(color: Color.appPrimary.opacity(0.4), radius: 14, x: 0, y: 6)
                                    if isLoading {
                                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    } else {
                                        Text("Update Password")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundStyle(.white)
                                    }
                                }
                            }
                            .disabled(!isValid || isLoading)
                            .opacity(isValid ? 1 : 0.5)
                        }
                    }
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(hex: "1A2740").opacity(0.95))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 20)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
    }

    private func resetPassword() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            try await SupabaseService.shared.updatePassword(recoveryToken: recoveryToken, newPassword: password)
            didSucceed = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct SecureInputField: View {
    let placeholder: String
    @Binding var text: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(Color.appTextSecondary)
                .frame(width: 20)
            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.6))
                }
                SecureField("", text: $text)
                    .font(.system(size: 15))
                    .foregroundStyle(Color.appTextPrimary)
                    .tint(.appPrimary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appBackground.opacity(0.7))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                )
        )
    }
}
