//
//  SignInView.swift
//  shifthand
//
//  Staff Sign In Screen (#1) adhering strictly to Docs/UI_STANDARDS.md.
//  Volunteers do NOT have accounts. Staff users only.
//

import SwiftUI

public struct SignInView: View {
    @Bindable var viewModel: AuthViewModel
    @State private var showingRegister = false

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Brand Header
                        VStack(spacing: 8) {
                            Image(systemName: "hand.raised.fill")
                                .font(.system(size: 44, weight: .bold))
                                .foregroundStyle(Color.shPrimaryTeal)

                            Text("ShiftHand Staff")
                                .font(.title2.bold())
                                .foregroundStyle(Color.shTextPrimary)

                            Text("Sign in to manage events, rosters, and shifts")
                                .font(.subheadline)
                                .foregroundStyle(Color.shTextSecondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 24)

                        // Error Banner if present
                        if let error = viewModel.errorMessage {
                            ErrorBanner(message: error, retryAction: nil) {
                                viewModel.errorMessage = nil
                            }
                        }

                        // Form Card
                        VStack(spacing: 16) {
                            // Email Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Email Address")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.shTextSecondary)

                                HStack {
                                    Image(systemName: "envelope")
                                        .foregroundStyle(Color.shTextSecondary)
                                        .frame(width: 20)

                                    TextField("staff@charity.org", text: $viewModel.email)
                                        .textContentType(.emailAddress)
                                        .keyboardType(.emailAddress)
                                        .autocapitalization(.none)
                                        .disableAutocorrection(true)
                                }
                                .padding(.horizontal, 12)
                                .frame(height: 48)
                                .background(Color.shBackgroundPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: SHMetrics.chipCornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: SHMetrics.chipCornerRadius)
                                        .stroke(Color.shBorderDefault, lineWidth: 1)
                                )
                            }

                            // Password Field
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Password")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.shTextSecondary)

                                HStack {
                                    Image(systemName: "lock")
                                        .foregroundStyle(Color.shTextSecondary)
                                        .frame(width: 20)

                                    if viewModel.isSecure {
                                        SecureField("••••••••", text: $viewModel.password)
                                    } else {
                                        TextField("Password", text: $viewModel.password)
                                            .autocapitalization(.none)
                                            .disableAutocorrection(true)
                                    }

                                    Button(action: { viewModel.isSecure.toggle() }) {
                                        Image(systemName: viewModel.isSecure ? "eye.slash" : "eye")
                                            .foregroundStyle(Color.shTextSecondary)
                                            .frame(width: SHMetrics.minTouchTarget, height: SHMetrics.minTouchTarget)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .padding(.leading, 12)
                                .padding(.trailing, 4)
                                .frame(height: 48)
                                .background(Color.shBackgroundPrimary)
                                .clipShape(RoundedRectangle(cornerRadius: SHMetrics.chipCornerRadius))
                                .overlay(
                                    RoundedRectangle(cornerRadius: SHMetrics.chipCornerRadius)
                                        .stroke(Color.shBorderDefault, lineWidth: 1)
                                )
                            }

                            // Sign In Action Button
                            PrimaryButton(
                                title: "Sign In",
                                isLoading: viewModel.state.isLoading,
                                isEnabled: viewModel.isSignInValid
                            ) {
                                Task { await viewModel.signIn() }
                            }
                            .padding(.top, 8)
                        }
                        .padding(20)
                        .background(
                            RoundedRectangle(cornerRadius: SHMetrics.cardCornerRadius)
                                .fill(Color.shBackgroundCard)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: SHMetrics.cardCornerRadius)
                                .stroke(Color.shBorderDefault, lineWidth: 1)
                        )

                        // Registration Link
                        Button(action: { showingRegister = true }) {
                            HStack(spacing: 4) {
                                Text("New staff member?")
                                    .foregroundStyle(Color.shTextSecondary)
                                Text("Create account")
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color.shPrimaryTeal)
                            }
                            .font(.subheadline)
                            .frame(minHeight: SHMetrics.minTouchTarget)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(20)
                }
            }
            .navigationDestination(isPresented: $showingRegister) {
                RegisterView(viewModel: viewModel)
            }
        }
    }
}

// MARK: - Previews (Light and Dark)
#Preview("SignInView - Light") {
    SignInView(viewModel: AuthViewModel(appSession: AppSession()))
        .preferredColorScheme(.light)
}

#Preview("SignInView - Dark") {
    SignInView(viewModel: AuthViewModel(appSession: AppSession()))
        .preferredColorScheme(.dark)
}
