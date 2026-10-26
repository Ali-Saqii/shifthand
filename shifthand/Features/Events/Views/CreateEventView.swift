//
//  CreateEventView.swift
//  shifthand
//
//  Modal form sheet to create a new event in draft status.
//  Conforms strictly to Docs/UI_STANDARDS.md and SHIFTHAND_MVP_SPEC_v2.md Section 5.3.
//

import SwiftUI

public struct CreateEventView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: CreateEventViewModel
    public var onCreated: ((Event) -> Void)?

    public init(viewModel: CreateEventViewModel, onCreated: ((Event) -> Void)? = nil) {
        self._viewModel = State(initialValue: viewModel)
        self.onCreated = onCreated
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Title Input
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Event Title *")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.shTextSecondary)

                            TextField("e.g. Community Food Drive", text: $viewModel.title)
                                .font(.body)
                                .padding(12)
                                .frame(height: SHMetrics.minTouchTarget)
                                .background(Color.shBackgroundCard)
                                .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                                        .stroke(Color.shBorderDefault, lineWidth: 1)
                                )
                        }

                        // Venue Input
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Venue / Location *")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.shTextSecondary)

                            TextField("e.g. Civic Centre, Hall B", text: $viewModel.venue)
                                .font(.body)
                                .padding(12)
                                .frame(height: SHMetrics.minTouchTarget)
                                .background(Color.shBackgroundCard)
                                .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                                        .stroke(Color.shBorderDefault, lineWidth: 1)
                                )
                        }

                        // Date Pickers Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Date & Time")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.shTextSecondary)
                                .textCase(.uppercase)

                            VStack(spacing: 12) {
                                DatePicker(
                                    "Starts At",
                                    selection: $viewModel.startsAt,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .font(.subheadline)
                                .foregroundStyle(Color.shTextPrimary)
                                .frame(minHeight: SHMetrics.minTouchTarget)

                                Divider()
                                    .background(Color.shBorderDefault)

                                DatePicker(
                                    "Ends At",
                                    selection: $viewModel.endsAt,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .font(.subheadline)
                                .foregroundStyle(Color.shTextPrimary)
                                .frame(minHeight: SHMetrics.minTouchTarget)
                            }
                            .padding(14)
                            .background(Color.shBackgroundCard)
                            .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                                    .stroke(Color.shBorderDefault, lineWidth: 1)
                            )

                            if !viewModel.isDatesValid {
                                Text("End time must be after the start time.")
                                    .font(.caption)
                                    .foregroundStyle(Color.shStatusRed)
                            }
                        }

                        // Description Input (Optional)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text("Description")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(Color.shTextSecondary)

                                Spacer()

                                Text("Optional")
                                    .font(.caption)
                                    .foregroundStyle(Color.shTextSecondary)
                            }

                            TextField(
                                "Brief briefing or directions for volunteers...",
                                text: $viewModel.descriptionText,
                                axis: .vertical
                            )
                            .lineLimit(3...5)
                            .font(.body)
                            .padding(12)
                            .background(Color.shBackgroundCard)
                            .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                                    .stroke(Color.shBorderDefault, lineWidth: 1)
                            )
                        }

                        // Error Banner if submission failed
                        if let error = viewModel.errorMessage {
                            ErrorBanner(message: error)
                        }

                        // Submit Button
                        PrimaryButton(
                            title: "Create Event (Draft)",
                            isLoading: viewModel.state.isLoading,
                            isEnabled: viewModel.isFormValid,
                            action: {
                                Task {
                                    if let created = await viewModel.createEvent() {
                                        onCreated?(created)
                                        dismiss()
                                    }
                                }
                            }
                        )
                        .padding(.top, 8)
                    }
                    .padding(20)
                }
            }
            .navigationTitle("New Event")
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

// MARK: - Preview
#Preview("CreateEventView") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "1", organisationName: "Green Crescent Food Bank", role: .owner)
    ]))
    session.currentUser = User(id: "1", name: "Sarah Ahmed", email: "sarah@example.com")
    session.activeMembership = session.memberships.first
    return CreateEventView(viewModel: CreateEventViewModel(appSession: session))
}
