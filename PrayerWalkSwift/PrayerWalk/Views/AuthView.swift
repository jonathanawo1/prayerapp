// AuthView.swift
// PrayerWalk

import SwiftUI

struct AuthView: View {
    @EnvironmentObject var authVM: AuthViewModel

    @State private var email = ""
    @State private var password = ""
    @State private var isSignUp = false
    @State private var emailFocused = false
    @State private var passwordFocused = false

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(hex: "060D1A"), Color(hex: "0A1628"), Color(hex: "0F1F3D")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            // Subtle grid pattern overlay
            GeometryReader { geo in
                Canvas { ctx, size in
                    let spacing: CGFloat = 40
                    var path = Path()
                    var x: CGFloat = 0
                    while x < size.width {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: size.height))
                        x += spacing
                    }
                    var y: CGFloat = 0
                    while y < size.height {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: size.width, y: y))
                        y += spacing
                    }
                    ctx.stroke(path, with: .color(.white.opacity(0.03)), lineWidth: 1)
                }
            }
            .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Logo area
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.appPrimary.opacity(0.15))
                                .frame(width: 96, height: 96)
                            Circle()
                                .strokeBorder(Color.appPrimary.opacity(0.3), lineWidth: 1.5)
                                .frame(width: 96, height: 96)
                            Image(systemName: "figure.walk")
                                .font(.system(size: 42, weight: .medium))
                                .foregroundStyle(Color.appPrimary)
                        }

                        VStack(spacing: 6) {
                            Text("PrayerWalk")
                                .font(.system(size: 36, weight: .black, design: .rounded))
                                .foregroundStyle(Color.appTextPrimary)

                            Text("Walk. Pray. Together.")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.appTextSecondary)
                                .tracking(0.5)
                        }
                    }
                    .padding(.top, 72)
                    .padding(.bottom, 52)

                    // Card
                    VStack(spacing: 20) {
                        // Mode toggle
                        HStack(spacing: 0) {
                            AuthModeTab(title: "Sign In", isSelected: !isSignUp) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isSignUp = false }
                            }
                            AuthModeTab(title: "Sign Up", isSelected: isSignUp) {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { isSignUp = true }
                            }
                        }
                        .background(Color.appBackground.opacity(0.6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.bottom, 4)

                        // Fields
                        VStack(spacing: 14) {
                            PremiumTextField(
                                icon: "envelope",
                                placeholder: "Email address",
                                text: $email,
                                isSecure: false,
                                keyboardType: .emailAddress
                            )
                            PremiumTextField(
                                icon: "lock",
                                placeholder: "Password",
                                text: $password,
                                isSecure: true,
                                keyboardType: .default
                            )
                        }

                        // Error
                        if let error = authVM.errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.circle.fill")
                                    .font(.system(size: 13))
                                Text(error)
                                    .font(.system(size: 13))
                                Spacer()
                            }
                            .foregroundStyle(Color.appError)
                            .padding(.horizontal, 4)
                        }

                        // CTA
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
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FF6B35"), Color.appPrimary],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(height: 54)
                                    .shadow(color: Color.appPrimary.opacity(0.4), radius: 16, x: 0, y: 6)

                                if authVM.isLoading {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(0.9)
                                } else {
                                    Text(isSignUp ? "Create Account" : "Sign In")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundStyle(.white)
                                        .tracking(0.3)
                                }
                            }
                        }
                        .disabled(authVM.isLoading || email.isEmpty || password.isEmpty)
                        .opacity((email.isEmpty || password.isEmpty) ? 0.55 : 1)
                        .animation(.easeInOut(duration: 0.15), value: email.isEmpty || password.isEmpty)
                    }
                    .padding(24)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color(hex: "1A2740").opacity(0.9))
                            .strokeBorder(Color.white.opacity(0.07), lineWidth: 1)
                    )
                    .padding(.horizontal, 20)

                    Spacer(minLength: 40)

                    // Footer
                    VStack(spacing: 20) {
                        HStack {
                            Rectangle().fill(Color.appSeparator).frame(height: 1)
                            Text("or")
                                .font(.caption)
                                .foregroundStyle(Color.appTextSecondary)
                                .padding(.horizontal, 12)
                            Rectangle().fill(Color.appSeparator).frame(height: 1)
                        }
                        .padding(.horizontal, 20)

                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                isSignUp.toggle()
                                authVM.errorMessage = nil
                            }
                        } label: {
                            SwiftUI.Group {
                                if isSignUp {
                                    Text("Already have an account? ") + Text("Sign In").bold().foregroundColor(.appPrimary)
                                } else {
                                    Text("New here? ") + Text("Create an account").bold().foregroundColor(.appPrimary)
                                }
                            }
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appTextSecondary)
                        }

                        Text("Community Prayer • Faith in Motion")
                            .font(.system(size: 11))
                            .foregroundStyle(Color.appTextSecondary.opacity(0.4))
                            .tracking(0.5)
                    }
                    .padding(.top, 28)
                    .padding(.bottom, 48)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Auth Mode Tab

private struct AuthModeTab: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 14, weight: isSelected ? .bold : .medium))
                .foregroundStyle(isSelected ? Color.appTextPrimary : Color.appTextSecondary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isSelected ? Color.appSurface : Color.clear)
                )
                .padding(3)
        }
    }
}

// MARK: - Premium Text Field

private struct PremiumTextField: View {
    let icon: String
    let placeholder: String
    @Binding var text: String
    let isSecure: Bool
    let keyboardType: UIKeyboardType
    @State private var isFocused = false

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(isFocused ? Color.appPrimary : Color.appTextSecondary)
                .frame(width: 20)
                .animation(.easeInOut(duration: 0.2), value: isFocused)

            ZStack(alignment: .leading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appTextSecondary.opacity(0.6))
                }
                if isSecure {
                    SecureField("", text: $text)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appTextPrimary)
                        .tint(.appPrimary)
                        .onSubmit { isFocused = false }
                } else {
                    TextField("", text: $text)
                        .keyboardType(keyboardType)
                        .autocapitalization(.none)
                        .autocorrectionDisabled()
                        .font(.system(size: 15))
                        .foregroundStyle(Color.appTextPrimary)
                        .tint(.appPrimary)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 15)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.appBackground.opacity(0.7))
                .strokeBorder(
                    isFocused ? Color.appPrimary.opacity(0.5) : Color.white.opacity(0.07),
                    lineWidth: 1
                )
        )
        .animation(.easeInOut(duration: 0.2), value: isFocused)
        .onTapGesture { isFocused = true }
    }
}
