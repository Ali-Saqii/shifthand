//
//  OrgPickerView.swift
//  shifthand
//
//  Organisation Switcher / Picker view presented when a staff member belongs to 2+ organisations.
//  Presented at launch if no active organisation is chosen, and from Settings or Shift Lead menu.
//

import SwiftUI

public struct OrgPickerView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    public var isDismissable: Bool
    @State private var showingJoinSheet: Bool = false
    @State private var showingCreateSheet: Bool = false

    public init(isDismissable: Bool = true) {
        self.isDismissable = isDismissable
    }

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Your Organisations")
                                .font(.title2.bold())
                                .foregroundStyle(Color.shTextPrimary)

                            Text("Select an organisation to manage events, shifts, and attendance.")
                                .font(.subheadline)
                                .foregroundStyle(Color.shTextSecondary)
                        }
                        .padding(.top, 12)

                        // Organisation List
                        VStack(spacing: 12) {
                            ForEach(session.memberships) { membership in
                                OrgSelectionCard(
                                    membership: membership,
                                    isSelected: session.activeMembership?.organisationId == membership.organisationId,
                                    onSelect: {
                                        session.setActiveOrganisation(membership)
                                        if isDismissable {
                                            dismiss()
                                        }
                                    }
                                )
                            }
                        }

                        // Divider & Additional Actions
                        VStack(spacing: 12) {
                            Button(action: { showingJoinSheet = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "person.badge.key")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.shPrimaryTeal)
                                        .frame(width: 24)

                                    Text("Join another organisation with code")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.shPrimaryTeal)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.shTextSecondary.opacity(0.5))
                                }
                                .padding(16)
                                .frame(minHeight: SHMetrics.minTouchTarget)
                                .background(Color.shBackgroundCard)
                                .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                                        .stroke(Color.shBorderDefault, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)

                            Button(action: { showingCreateSheet = true }) {
                                HStack(spacing: 12) {
                                    Image(systemName: "plus.circle")
                                        .font(.system(size: 18))
                                        .foregroundStyle(Color.shDarkTeal)
                                        .frame(width: 24)

                                    Text("Create a new organisation")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(Color.shDarkTeal)

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .font(.caption.weight(.semibold))
                                        .foregroundStyle(Color.shTextSecondary.opacity(0.5))
                                }
                                .padding(16)
                                .frame(minHeight: SHMetrics.minTouchTarget)
                                .background(Color.shBackgroundCard)
                                .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
                                .overlay(
                                    RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                                        .stroke(Color.shBorderDefault, lineWidth: 1)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.top, 8)

                        // Sign Out Option if not dismissable
                        if !isDismissable {
                            VStack {
                                Button(role: .destructive, action: { session.logout() }) {
                                    Text("Sign Out")
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(Color.shStatusRed)
                                        .frame(maxWidth: .infinity)
                                        .frame(minHeight: SHMetrics.minTouchTarget)
                                }
                            }
                            .padding(.top, 16)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Select Organisation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if isDismissable {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Done") {
                            dismiss()
                        }
                        .foregroundStyle(Color.shPrimaryTeal)
                    }
                }
            }
            .sheet(isPresented: $showingJoinSheet) {
                JoinOrgView(viewModel: OnboardingViewModel(appSession: session))
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateOrgView(viewModel: OnboardingViewModel(appSession: session))
            }
        }
    }
}

// MARK: - Org Selection Card

private struct OrgSelectionCard: View {
    let membership: Membership
    let isSelected: Bool
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 14) {
                // Role icon badge
                ZStack {
                    Circle()
                        .fill(roleBackgroundColor)
                        .frame(width: 44, height: 44)

                    Image(systemName: roleIconName)
                        .font(.system(size: 20))
                        .foregroundStyle(roleForegroundColor)
                }

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(membership.organisationName)
                        .font(.headline)
                        .foregroundStyle(Color.shTextPrimary)
                        .lineLimit(1)

                    StatusChip(
                        title: membership.role.displayName,
                        systemImage: roleIconName,
                        style: chipStyle
                    )
                }

                Spacer()

                // Selection Indicator
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.shPrimaryTeal)
                } else {
                    Image(systemName: "circle")
                        .font(.system(size: 22))
                        .foregroundStyle(Color.shBorderDefault)
                }
            }
            .padding(16)
            .frame(minHeight: SHMetrics.minTouchTarget)
            .background(Color.shBackgroundCard)
            .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
            .overlay(
                RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                    .stroke(isSelected ? Color.shPrimaryTeal : Color.shBorderDefault, lineWidth: isSelected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(membership.organisationName), Role: \(membership.role.displayName), \(isSelected ? "Currently selected" : "Tap to switch")")
    }

    private var roleIconName: String {
        switch membership.role {
        case .owner: return "crown.fill"
        case .coordinator: return "person.badge.key.fill"
        case .shiftLead: return "person.fill"
        }
    }

    private var roleBackgroundColor: Color {
        switch membership.role {
        case .owner: return Color.shPrimaryTeal.opacity(0.12)
        case .coordinator: return Color.shStatusGreen.opacity(0.12)
        case .shiftLead: return Color.shAccentAmber.opacity(0.12)
        }
    }

    private var roleForegroundColor: Color {
        switch membership.role {
        case .owner: return Color.shPrimaryTeal
        case .coordinator: return Color.shStatusGreen
        case .shiftLead: return Color.shAccentAmber
        }
    }

    private var chipStyle: StatusChipStyle {
        switch membership.role {
        case .owner: return .teal
        case .coordinator: return .green
        case .shiftLead: return .amber
        }
    }
}

// MARK: - Previews
#Preview("OrgPickerView - 2 Orgs") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "1", organisationName: "Green Crescent Food Bank", role: .owner),
        Membership(organisationId: "2", organisationName: "Youth Shelter Outreach", role: .shiftLead)
    ]))
    session.currentUser = User(id: "1", name: "Sarah Ahmed", email: "sarah@example.com")
    session.activeMembership = session.memberships.first
    return OrgPickerView(isDismissable: true)
        .environment(session)
}
