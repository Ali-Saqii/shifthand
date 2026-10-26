//
//  SettingsView.swift
//  shifthand
//
//  Staff settings sheet opened from the profile avatar button on the Events screen (top-right).
//  NOT a tab in the TabView. Conforms strictly to AGENTS.md.
//

import SwiftUI

public struct SettingsView: View {
    @Environment(AppSession.self) private var session
    @Environment(\.dismiss) private var dismiss

    @State private var showingOrgPicker: Bool = false
    @State private var showingJoinSheet: Bool = false
    @State private var showingCreateSheet: Bool = false
    @State private var showingDeleteConfirmation: Bool = false
    @State private var isDeletingAccount: Bool = false
    @State private var deleteError: String? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        // Profile Header Card
                        profileCard

                        // Organisation Section
                        organisationCard

                        // App Information
                        appInfoSection

                        // Account Actions (Sign Out & Delete)
                        accountActionsSection
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(Color.shPrimaryTeal)
                }
            }
            .sheet(isPresented: $showingOrgPicker) {
                OrgPickerView(isDismissable: true)
            }
            .sheet(isPresented: $showingJoinSheet) {
                JoinOrgView(viewModel: OnboardingViewModel(appSession: session))
            }
            .sheet(isPresented: $showingCreateSheet) {
                CreateOrgView(viewModel: OnboardingViewModel(appSession: session))
            }
            .alert("Delete Staff Account", isPresented: $showingDeleteConfirmation) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to permanently delete your staff account? This will remove your memberships and cannot be undone.")
            }
        }
    }

    // MARK: - Profile Card

    private var profileCard: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.shPrimaryTeal.opacity(0.15))
                .frame(width: 56, height: 56)
                .overlay(
                    Text(initials)
                        .font(.title3.bold())
                        .foregroundStyle(Color.shPrimaryTeal)
                )

            VStack(alignment: .leading, spacing: 4) {
                Text(session.currentUser?.name ?? "Staff Member")
                    .font(.headline)
                    .foregroundStyle(Color.shTextPrimary)

                Text(session.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundStyle(Color.shTextSecondary)
            }

            Spacer()
        }
        .padding(16)
        .background(Color.shBackgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                .stroke(Color.shBorderDefault, lineWidth: 1)
        )
    }

    // MARK: - Organisation Section

    private var organisationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Active Organisation")
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color.shTextSecondary)
                .textCase(.uppercase)

            if let activeOrg = session.activeMembership {
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(activeOrg.organisationName)
                            .font(.headline)
                            .foregroundStyle(Color.shTextPrimary)

                        StatusChip(
                            title: activeOrg.role.displayName,
                            systemImage: roleIcon(for: activeOrg.role),
                            style: chipStyle(for: activeOrg.role)
                        )
                    }

                    Spacer()

                    if session.memberships.count > 1 {
                        Button(action: { showingOrgPicker = true }) {
                            Text("Switch")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(Color.shPrimaryTeal)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(Color.shPrimaryTeal.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }

            Divider()
                .background(Color.shBorderDefault)

            // Multi-org actions
            VStack(spacing: 8) {
                Button(action: { showingJoinSheet = true }) {
                    HStack {
                        Label("Join with invite code", systemImage: "person.badge.key")
                            .font(.subheadline)
                            .foregroundStyle(Color.shTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.shTextSecondary.opacity(0.5))
                    }
                    .frame(minHeight: SHMetrics.minTouchTarget)
                }

                Button(action: { showingCreateSheet = true }) {
                    HStack {
                        Label("Create new organisation", systemImage: "plus.circle")
                            .font(.subheadline)
                            .foregroundStyle(Color.shTextPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(Color.shTextSecondary.opacity(0.5))
                    }
                    .frame(minHeight: SHMetrics.minTouchTarget)
                }
            }
        }
        .padding(16)
        .background(Color.shBackgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
        .overlay(
            RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                .stroke(Color.shBorderDefault, lineWidth: 1)
        )
    }

    // MARK: - App Information

    private var appInfoSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Version")
                    .font(.subheadline)
                    .foregroundStyle(Color.shTextSecondary)
                Spacer()
                Text("1.0 (MVP) • Staff Only")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(Color.shTextPrimary)
            }
            .padding(.horizontal, 4)
        }
    }

    // MARK: - Account Actions

    private var accountActionsSection: some View {
        VStack(spacing: 12) {
            Button(role: .destructive, action: { session.logout() }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Sign Out")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(Color.shStatusRed)
                .frame(maxWidth: .infinity)
                .frame(minHeight: SHMetrics.minTouchTarget)
                .background(Color.shBackgroundCard)
                .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
                .overlay(
                    RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                        .stroke(Color.shBorderDefault, lineWidth: 1)
                )
            }

            Button(role: .destructive, action: { showingDeleteConfirmation = true }) {
                HStack {
                    Image(systemName: "trash")
                    Text("Delete Account")
                        .fontWeight(.regular)
                }
                .font(.footnote)
                .foregroundStyle(Color.shTextSecondary)
                .frame(minHeight: SHMetrics.minTouchTarget)
            }

            if let error = deleteError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(Color.shStatusRed)
            }
        }
    }

    // MARK: - Helpers

    private var initials: String {
        let name = session.currentUser?.name ?? "S"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func roleIcon(for role: StaffRole) -> String {
        switch role {
        case .owner: return "crown.fill"
        case .coordinator: return "person.badge.key.fill"
        case .shiftLead: return "person.fill"
        }
    }

    private func chipStyle(for role: StaffRole) -> StatusChipStyle {
        switch role {
        case .owner: return .teal
        case .coordinator: return .green
        case .shiftLead: return .amber
        }
    }

    private func deleteAccount() async {
        isDeletingAccount = true
        deleteError = nil
        do {
            try await session.deleteAccount()
            dismiss()
        } catch {
            deleteError = "Failed to delete account: \(error.localizedDescription)"
            isDeletingAccount = false
        }
    }
}

// MARK: - Preview
#Preview("SettingsView") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "1", organisationName: "Green Crescent Food Bank", role: .owner)
    ]))
    session.currentUser = User(id: "1", name: "Sarah Ahmed", email: "sarah@example.com")
    session.activeMembership = session.memberships.first
    return SettingsView()
        .environment(session)
}
