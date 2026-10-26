//
//  CreateOrgView.swift
//  shifthand
//
//  Modal form to create a new organisation workspace (Owner role).
//  Timezone is a REQUIRED field conforming strictly to Plan v3 Day 3.
//

import SwiftUI

public struct CreateOrgView: View {
    @Bindable var viewModel: OnboardingViewModel
    @Environment(\.dismiss) private var dismiss

    public static let commonTimezones: [String] = [
        "Asia/Karachi",
        "Europe/London",
        "America/New_York",
        "America/Chicago",
        "America/Los_Angeles",
        "Europe/Paris",
        "Asia/Dubai",
        "Asia/Singapore",
        "Australia/Sydney",
        "UTC"
    ]

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
                        if let error = viewModel.createErrorMessage {
                            ErrorBanner(message: error, retryAction: nil) {
                                viewModel.createErrorMessage = nil
                            }
                        }

                        // Form Card
                        VStack(spacing: 16) {
                            // Organisation Name
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Organisation Name")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.shTextSecondary)

                                HStack {
                                    Image(systemName: "building.2")
                                        .foregroundStyle(Color.shTextSecondary)
                                        .frame(width: 20)

                                    TextField("e.g. Green Crescent Relief", text: $viewModel.orgName)
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

                            // Timezone Picker
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Operating Timezone")
                                    .font(.caption.bold())
                                    .foregroundStyle(Color.shTextSecondary)

                                Menu {
                                    ForEach(Self.commonTimezones, id: \.self) { tz in
                                        Button(action: { viewModel.selectedTimezone = tz }) {
                                            HStack {
                                                Text(tz)
                                                if viewModel.selectedTimezone == tz {
                                                    Image(systemName: "checkmark")
                                                }
                                            }
                                        }
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "clock")
                                            .foregroundStyle(Color.shTextSecondary)
                                            .frame(width: 20)

                                        Text(viewModel.selectedTimezone)
                                            .foregroundStyle(Color.shTextPrimary)

                                        Spacer()

                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption)
                                            .foregroundStyle(Color.shTextSecondary)
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
                                .buttonStyle(.plain)

                                Text("All event dates and 'today's shifts' are calculated using this timezone.")
                                    .font(.caption2)
                                    .foregroundStyle(Color.shTextSecondary)
                            }

                            // Create Button
                            PrimaryButton(
                                title: "Create Organisation",
                                isLoading: viewModel.isCreating,
                                isEnabled: viewModel.isCreateValid
                            ) {
                                Task {
                                    let success = await viewModel.createOrganisation()
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
            .navigationTitle("New Organisation")
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
#Preview("CreateOrgView - Light") {
    CreateOrgView(viewModel: OnboardingViewModel(appSession: AppSession()))
        .preferredColorScheme(.light)
}

#Preview("CreateOrgView - Dark") {
    CreateOrgView(viewModel: OnboardingViewModel(appSession: AppSession()))
        .preferredColorScheme(.dark)
}
