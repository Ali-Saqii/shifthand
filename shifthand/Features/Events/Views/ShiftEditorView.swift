//
//  ShiftEditorView.swift
//  shifthand
//
//  Shift Editor modal sheet (Screen #4).
//  Create or modify shifts with capacity restrictions and change warnings.
//  Conforms strictly to Docs/SCREENS.md and SHIFTHAND_MVP_SPEC_v2.md Section 5.4.
//

import SwiftUI

public struct ShiftEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel: ShiftEditorViewModel
    @State private var showingDeleteAlert: Bool = false

    public var onSaved: ((Shift) -> Void)?
    public var onDeleted: (() -> Void)?

    public init(
        viewModel: ShiftEditorViewModel,
        onSaved: ((Shift) -> Void)? = nil,
        onDeleted: (() -> Void)? = nil
    ) {
        self._viewModel = State(initialValue: viewModel)
        self.onSaved = onSaved
        self.onDeleted = onDeleted
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Change Warning Banner if editing shift with volunteers
                        if viewModel.requiresChangeWarning {
                            changeWarningBanner
                        }

                        // Role Label
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Role Label *")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.shTextSecondary)

                            TextField("e.g. Registration Desk, Food Packing", text: $viewModel.roleLabel)
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

                        // Time Range Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Shift Timing (UTC)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.shTextSecondary)
                                .textCase(.uppercase)

                            VStack(spacing: 12) {
                                DatePicker(
                                    "Starts At",
                                    selection: $viewModel.startsAtUtc,
                                    displayedComponents: [.hourAndMinute]
                                )
                                .font(.subheadline)
                                .foregroundStyle(Color.shTextPrimary)
                                .frame(minHeight: SHMetrics.minTouchTarget)

                                Divider()
                                    .background(Color.shBorderDefault)

                                DatePicker(
                                    "Ends At",
                                    selection: $viewModel.endsAtUtc,
                                    displayedComponents: [.hourAndMinute]
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

                        // Capacity & Cutoff Section
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Capacity & Policies")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.shTextSecondary)
                                .textCase(.uppercase)

                            VStack(spacing: 14) {
                                // Capacity Stepper
                                HStack {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Volunteer Capacity")
                                            .font(.subheadline)
                                            .foregroundStyle(Color.shTextPrimary)

                                        if let existing = viewModel.existingShift, existing.confirmedCount > 0 {
                                            Text("Min \(existing.confirmedCount) (confirmed signups)")
                                                .font(.caption2)
                                                .foregroundStyle(Color.shAccentAmber)
                                        }
                                    }

                                    Spacer()

                                    Stepper("\(viewModel.capacity) seats", value: $viewModel.capacity, in: max(1, viewModel.existingShift?.confirmedCount ?? 1)...100)
                                        .font(.subheadline.bold())
                                        .frame(width: 170)
                                }
                                .frame(minHeight: SHMetrics.minTouchTarget)

                                Divider()
                                    .background(Color.shBorderDefault)

                                // Cancel Cutoff Hours
                                HStack {
                                    Text("Cancellation Cut-off")
                                        .font(.subheadline)
                                        .foregroundStyle(Color.shTextPrimary)

                                    Spacer()

                                    Stepper("\(viewModel.cancelCutoffHours) hours", value: $viewModel.cancelCutoffHours, in: 0...72, step: 6)
                                        .font(.subheadline.bold())
                                        .frame(width: 170)
                                }
                                .frame(minHeight: SHMetrics.minTouchTarget)
                            }
                            .padding(14)
                            .background(Color.shBackgroundCard)
                            .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                                    .stroke(Color.shBorderDefault, lineWidth: 1)
                            )
                        }

                        // Shift Lead Assignment Section
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Shift Lead (On-site Lead)")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.shTextSecondary)

                            Picker("Assign Shift Lead", selection: $viewModel.selectedLeadId) {
                                Text("Unassigned").tag(String?.none)
                                ForEach(viewModel.availableStaff) { staff in
                                    Text("\(staff.name) (\(staff.role.displayName))").tag(String?.some(staff.id))
                                }
                            }
                            .pickerStyle(.menu)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(12)
                            .frame(minHeight: SHMetrics.minTouchTarget)
                            .background(Color.shBackgroundCard)
                            .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
                            .overlay(
                                RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                                    .stroke(Color.shBorderDefault, lineWidth: 1)
                            )
                        }

                        // Notes Field
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Shift Briefing / Notes")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(Color.shTextSecondary)

                            TextField("Instructions, clothing requirements, or entrance details...", text: $viewModel.notes, axis: .vertical)
                                .lineLimit(2...4)
                                .font(.body)
                                .padding(12)
                                .background(Color.shBackgroundCard)
                                .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                                        .stroke(Color.shBorderDefault, lineWidth: 1)
                                )
                        }

                        // Error Banner if needed
                        if let error = viewModel.errorMessage {
                            ErrorBanner(message: error)
                        }

                        // Save Button
                        PrimaryButton(
                            title: viewModel.isEditing ? "Save Shift Changes" : "Add Shift",
                            isLoading: viewModel.state.isLoading,
                            isEnabled: viewModel.isFormValid && (!viewModel.requiresChangeWarning || viewModel.confirmChange),
                            action: {
                                Task {
                                    if let saved = await viewModel.saveShift() {
                                        onSaved?(saved)
                                        dismiss()
                                    }
                                }
                            }
                        )
                        .padding(.top, 8)

                        // Delete Shift Button (if editing)
                        if viewModel.isEditing {
                            Button(role: .destructive, action: { showingDeleteAlert = true }) {
                                HStack {
                                    Image(systemName: "trash")
                                    Text("Delete Shift")
                                }
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.shStatusRed)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: SHMetrics.minTouchTarget)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle(viewModel.isEditing ? "Edit Shift" : "New Shift")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundStyle(Color.shPrimaryTeal)
                }
            }
            .task {
                await viewModel.loadStaffMembers()
            }
            .alert("Delete Shift", isPresented: $showingDeleteAlert) {
                Button("Delete", role: .destructive) {
                    Task {
                        if await viewModel.deleteShift() {
                            onDeleted?()
                            dismiss()
                        }
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                if let count = viewModel.existingShift?.confirmedCount, count > 0 {
                    Text("This shift has \(count) confirmed volunteers and cannot be deleted.")
                } else {
                    Text("Are you sure you want to delete this shift? This action cannot be undone.")
                }
            }
        }
    }

    // MARK: - Change Warning Banner

    private var changeWarningBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundStyle(Color.shAccentAmber)
                    .font(.subheadline)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Time Change Notification")
                        .font(.subheadline.bold())
                        .foregroundStyle(Color.shTextPrimary)

                    let count = viewModel.existingShift?.confirmedCount ?? 0
                    Text("Changing shift times will dispatch update emails to \(count) confirmed volunteer\(count == 1 ? "" : "s").")
                        .font(.footnote)
                        .foregroundStyle(Color.shTextSecondary)
                }
            }

            Toggle("I confirm volunteer time change notification", isOn: $viewModel.confirmChange)
                .font(.footnote.weight(.medium))
                .tint(Color.shAccentAmber)
                .padding(.top, 4)
        }
        .padding(14)
        .background(Color.shAccentAmber.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                .stroke(Color.shAccentAmber.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Previews
#Preview("ShiftEditorView - New") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "1", organisationName: "Green Crescent Food Bank", role: .owner)
    ]))
    session.currentUser = User(id: "1", name: "Sarah Ahmed", email: "sarah@example.com")
    session.activeMembership = session.memberships.first

    return ShiftEditorView(
        viewModel: ShiftEditorViewModel(
            eventId: "evt_1",
            eventStartDate: Date(),
            appSession: session
        )
    )
}
