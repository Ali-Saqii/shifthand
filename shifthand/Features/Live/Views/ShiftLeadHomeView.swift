//
//  ShiftLeadHomeView.swift
//  shifthand
//
//  Dedicated home screen for Shift Leads.
//  NEVER displays a TabBar and NEVER provides access to Events or Volunteers tabs.
//  Conforms strictly to AGENTS.md Section 2.
//

import SwiftUI

public struct ShiftLeadHomeView: View {
    @Environment(AppSession.self) private var session

    @State private var showingMenuSheet: Bool = false
    @State private var showingOrgPicker: Bool = false
    @State private var showingDeleteAlert: Bool = false
    @State private var isDeletingAccount: Bool = false
    @State private var errorMessage: String? = nil

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    // Header Status Card
                    if let activeOrg = session.activeMembership {
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activeOrg.organisationName)
                                    .font(.headline)
                                    .foregroundStyle(Color.shTextPrimary)

                                StatusChip(
                                    title: "Shift Lead",
                                    systemImage: "person.fill",
                                    style: .amber
                                )
                            }

                            Spacer()

                            if session.memberships.count > 1 {
                                Button(action: { showingOrgPicker = true }) {
                                    HStack(spacing: 4) {
                                        Text("Switch Org")
                                            .font(.caption.weight(.semibold))
                                        Image(systemName: "chevron.up.chevron.down")
                                            .font(.caption2)
                                    }
                                    .foregroundStyle(Color.shPrimaryTeal)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(Color.shPrimaryTeal.opacity(0.1))
                                    .clipShape(Capsule())
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
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                    }

                    // Content Area: Empty State or Today's Assigned Shifts
                    EmptyState(
                        systemImage: "clock.badge.checkmark",
                        title: "No shifts assigned to you today",
                        message: "Shifts will appear here when an event coordinator assigns you as the lead for a shift today."
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Today's Shifts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingMenuSheet = true }) {
                        avatarButton
                    }
                    .accessibilityLabel("Shift Lead Menu")
                }
            }
            .confirmationDialog(
                "Shift Lead Account",
                isPresented: $showingMenuSheet,
                titleVisibility: .visible
            ) {
                if session.memberships.count > 1 {
                    Button("Switch Organisation") {
                        showingOrgPicker = true
                    }
                }

                Button("Sign Out", role: .destructive) {
                    session.logout()
                }

                Button("Delete Account", role: .destructive) {
                    showingDeleteAlert = true
                }

                Button("Cancel", role: .cancel) {}
            } message: {
                Text("\(session.currentUser?.name ?? "Shift Lead")\n\(session.currentUser?.email ?? "")")
            }
            .alert("Delete Staff Account", isPresented: $showingDeleteAlert) {
                Button("Delete Account", role: .destructive) {
                    Task {
                        await deleteAccount()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Are you sure you want to delete your staff account? This cannot be undone.")
            }
            .sheet(isPresented: $showingOrgPicker) {
                OrgPickerView(isDismissable: true)
            }
        }
    }

    private var avatarButton: some View {
        Circle()
            .fill(Color.shAccentAmber.opacity(0.15))
            .frame(width: 34, height: 34)
            .overlay(
                Text(initials)
                    .font(.caption.bold())
                    .foregroundStyle(Color.shAccentAmber)
            )
            .overlay(
                Circle()
                    .stroke(Color.shAccentAmber.opacity(0.3), lineWidth: 1)
            )
    }

    private var initials: String {
        let name = session.currentUser?.name ?? "S"
        let parts = name.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func deleteAccount() async {
        isDeletingAccount = true
        do {
            try await session.deleteAccount()
        } catch {
            errorMessage = error.localizedDescription
            isDeletingAccount = false
        }
    }
}

// MARK: - Preview
#Preview("ShiftLeadHomeView") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "1", organisationName: "Green Crescent Food Bank", role: .shiftLead)
    ]))
    session.currentUser = User(id: "1", name: "Tariq Vance", email: "tariq@example.com")
    session.activeMembership = session.memberships.first
    return ShiftLeadHomeView()
        .environment(session)
}
