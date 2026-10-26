//
//  JoinOrgView.swift
//  shifthand
//
//  Modal form to join an organisation using an 8-character staff invite code.
//  Strictly compliant with Plan v3 Day 3.
//

import SwiftUI

public struct JoinOrgView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {
                        // Error Banner
                        if let error = viewModel.joinErrorMessage {
                            ErrorBanner(message: error, retryAction: nil) {
                                viewModel.joinErrorMessage = nil
                            }
                        }

                        // Form Card
                        VStack(spacing: 16) {
                            VStack(spacing: 8) {
                                Image(systemName: "ticket")
                                    .font(.system(size: 36))
                                    .foregroundStyle(Color.shPrimaryTeal)

                                Text("Enter Staff Invite Code")
                                    .font(.headline)
                                    .foregroundStyle(Color.shTextPrimary)

                                Text("Ask your organisation owner for an 8-character invite code. Codes expire after 48 hours.")
                                    .font(.subheadline)
                                    .foregroundStyle(Color.shTextSecondary)
                                    .multilineTextAlignment(.center)
                            }
                            .padding(.vertical, 8)

                            // 8-character code textfield
                            HStack {
                                TextField("8-CHAR CODE", text: $viewModel.inviteCode)
                                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                                    .multilineTextAlignment(.center)
                                    .autocapitalization(.allCharacters)
                                    .disableAutocorrection(true)
                                    .onChange(of: viewModel.inviteCode) { _, newValue in
                                        let filtered = newValue.uppercased().filter { $0.isLetter || $0.isNumber }
                                        if filtered.count > 8 {
                                            viewModel.inviteCode = String(filtered.prefix(8))
                                        } else {
                                            viewModel.inviteCode = filtered
                                        }
                                    }
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 56)
                            .background(Color.shBackgroundPrimary)
                            .clipShape(RoundedRectangle(cornerRadius: SHMetrics.chipCornerRadius))
                            .overlay(
                                RoundedRectangle(cornerRadius: SHMetrics.chipCornerRadius)
                                    .stroke(viewModel.isJoinValid ? Color.shPrimaryTeal : Color.shBorderDefault, lineWidth: 1.5)
                            )

                            // Join Button
                            PrimaryButton(
                                title: "Join Organisation",
                                isLoading: viewModel.isJoining,
                                isEnabled: viewModel.isJoinValid
                            ) {
                                Task {
                                    let success = await viewModel.joinOrganisation()
                                    if success {
                                        dismiss()
                                    }
                                }
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
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Join Organisation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.shPrimaryTeal)
                }
            }
        }
    }
}

// MARK: - Previews (Light and Dark)
#Preview("JoinOrgView - Light") {
    JoinOrgView(viewModel: OnboardingViewModel(appSession: AppSession()))
        .preferredColorScheme(.light)
}

#Preview("JoinOrgView - Dark") {
    JoinOrgView(viewModel: OnboardingViewModel(appSession: AppSession()))
        .preferredColorScheme(.dark)
}
