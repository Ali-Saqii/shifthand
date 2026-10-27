//
//  RegisterView.swift
//  shifthand
//
//  Staff Registration View conforming to Docs/UI_STANDARDS.md.
//

import SwiftUI

public struct RegisterView: View {
    @Bindable var viewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: AuthViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        ZStack {
            Color.shBackgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 6) {
                        Image("applogo")
                            .resizable()
                            .frame(width: 60, height: 60)
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        Text("Create Staff Account")
                            .font(.title2.bold())
                            .foregroundStyle(Color.shTextPrimary)

                        Text("Register as an organisation owner or staff coordinator")
                            .font(.subheadline)
                            .foregroundStyle(Color.shTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 12)

                    // Error Banner
                    if let error = viewModel.errorMessage {
                        ErrorBanner(message: error, retryAction: nil) {
                            viewModel.errorMessage = nil
                        }
                    }

                    // Form Card
                    VStack(spacing: 16) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Full Name")
                                .font(.caption.bold())
                                .foregroundStyle(Color.shTextSecondary)

                            HStack {
                                Image(systemName: "person")
                                    .foregroundStyle(Color.shTextSecondary)
                                    .frame(width: 20)

                                TextField("Sarah Ahmed", text: $viewModel.name)
                                    .textContentType(.name)
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

                        // Email Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.caption.bold())
                                .foregroundStyle(Color.shTextSecondary)

                            HStack {
                                Image(systemName: "envelope")
                                    .foregroundStyle(Color.shTextSecondary)
                                    .frame(width: 20)

                                TextField("sarah@charity.org", text: $viewModel.email)
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
                            Text("Password (minimum 8 characters)")
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

                        // Register Primary Button
                        PrimaryButton(
                            title: "Create Account",
                            isLoading: viewModel.state.isLoading,
                            isEnabled: viewModel.isRegisterValid
                        ) {
                            Task { await viewModel.register() }
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

                    // Sign In Return Link
                    Button(action: { dismiss() }) {
                        HStack(spacing: 4) {
                            Text("Already registered?")
                                .foregroundStyle(Color.shTextSecondary)
                            Text("Sign in")
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
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews (Light and Dark)
#Preview("RegisterView - Light") {
        RegisterView(viewModel: AuthViewModel(appSession: AppSession()))
            .preferredColorScheme(.light)
}

#Preview("RegisterView - Dark") {
    NavigationStack {
        RegisterView(viewModel: AuthViewModel(appSession: AppSession()))
    }
    .preferredColorScheme(.dark)
}
