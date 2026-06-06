// AuthView.swift
// PrayerWalk

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isSignUp: Bool = false

    var body: some View {
        ZStack {
            Color.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "figure.walk.circle.fill")
                        .resizable()
                        .frame(width: 72, height: 72)
                        .foregroundColor(.appPrimary)
                        .padding(.bottom, 4)

                    Text("PrayerWalk")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.appTextPrimary)

                    Text("Walk. Pray. Together.")
                        .font(.subheadline)
                        .foregroundColor(.appTextSecondary)
                }
                .padding(.top, 60)
                .padding(.bottom, 48)

                // Form
                VStack(spacing: 16) {
                    CustomTextField(placeholder: "Email", text: $email, keyboardType: .emailAddress, isSecure: false)
                    CustomTextField(placeholder: "Password", text: $password, keyboardType: .default, isSecure: true)

                    if let error = authVM.errorMessage {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.appError)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.appError)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }

                    Button {
                        Task {
                            if isSignUp {
                                await authVM.signUp(email: email, password: password)
                            } else {
                                await authVM.signIn(email: email, password: password)
                            }
                        }
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(Color.appPrimary)
                                .frame(height: 52)
                            if authVM.isLoading {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Text(isSignUp ? "Create Account" : "Sign In")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
                    .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
                    .opacity((email.isEmpty || password.isEmpty) ? 0.6 : 1)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            isSignUp.toggle()
                            authVM.errorMessage = nil
                        }
                    } label: {
                        Text(isSignUp ? "Already have an account? Sign In" : "Don't have an account? Sign Up")
                            .font(.subheadline)
                            .foregroundColor(.appTextSecondary)
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 24)

                Spacer()

                Text("Community Prayer • Faith in Motion")
                    .font(.caption2)
                    .foregroundColor(.appTextSecondary.opacity(0.5))
                    .padding(.bottom, 32)
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Custom TextField

private struct CustomTextField: View {
    let placeholder: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let isSecure: Bool

    var body: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appSurface)
                .frame(height: 52)

            if isSecure {
                SecureField("", text: $text)
                    .padding(.horizontal, 16)
                    .foregroundColor(.appTextPrimary)
                    .tint(.appPrimary)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder).foregroundColor(.appTextSecondary)
                    }
            } else {
                TextField("", text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                    .padding(.horizontal, 16)
                    .foregroundColor(.appTextPrimary)
                    .tint(.appPrimary)
                    .placeholder(when: text.isEmpty) {
                        Text(placeholder).foregroundColor(.appTextSecondary)
                    }
            }
        }
    }
}

private extension View {
    func placeholder<Content: View>(when shouldShow: Bool, @ViewBuilder placeholder: () -> Content) -> some View {
        ZStack(alignment: .leading) {
            if shouldShow { placeholder().padding(.horizontal, 16) }
            self
        }
    }
}
