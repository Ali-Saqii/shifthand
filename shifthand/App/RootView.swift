//
//  RootView.swift
//  shifthand
//
//  Role-driven root navigation container.
//  Routes dynamically between Authentication, Onboarding (0 orgs), and active Organisation workspace.
//

import SwiftUI

public struct RootView: View {
    @Environment(AppSession.self) private var session

    public init() {}

    public var body: some View {
        Group {
            if !session.isAuthenticated {
                SignInView(viewModel: AuthViewModel(appSession: session))
            } else if session.membershipCount == 0 {
                OnboardingView(viewModel: OnboardingViewModel(appSession: session))
            } else if let activeOrg = session.activeMembership {
                // Workspace placeholder for Day 3 (expanded in Day 4 to role-driven TabView vs ShiftLeadHome)
                ActiveOrgPlaceholderView(activeOrg: activeOrg)
            } else {
                OnboardingView(viewModel: OnboardingViewModel(appSession: session))
            }
        }
        .task {
            if session.isAuthenticated {
                await session.refreshMe()
            }
        }
    }
}

// Temporary workspace landing view for Day 3 verification
private struct ActiveOrgPlaceholderView: View {
    @Environment(AppSession.self) private var session
    let activeOrg: Membership

    var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 24) {
                    VStack(spacing: 12) {
                        Image(systemName: "building.2.crop.circle.fill")
                            .font(.system(size: 64))
                            .foregroundStyle(Color.shPrimaryTeal)

                        Text(activeOrg.organisationName)
                            .font(.title2.bold())
                            .foregroundStyle(Color.shTextPrimary)

                        StatusChip(
                            title: activeOrg.role.displayName,
                            systemImage: activeOrg.role == .owner ? "crown.fill" : (activeOrg.role == .coordinator ? "person.badge.key.fill" : "person.fill"),
                            style: activeOrg.role == .owner ? .teal : (activeOrg.role == .coordinator ? .green : .amber)
                        )
                    }
                    .padding(.top, 40)

                    VStack(spacing: 12) {
                        Text("Organisation Workspace Active")
                            .font(.headline)
                            .foregroundStyle(Color.shTextPrimary)

                        Text("Day 3 implementation verified. Role-driven TabView and Shift Lead Home will be wired in Day 4.")
                            .font(.subheadline)
                            .foregroundStyle(Color.shTextSecondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 24)
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        if session.memberships.count > 1 {
                            Text("\(session.memberships.count) organisations available")
                                .font(.caption)
                                .foregroundStyle(Color.shTextSecondary)
                        }

                        Button(role: .destructive, action: { session.logout() }) {
                            Text("Sign Out")
                                .font(.subheadline.bold())
                                .foregroundStyle(Color.shStatusRed)
                                .frame(height: SHMetrics.minTouchTarget)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .padding(20)
            }
            .navigationTitle("ShiftHand")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

// MARK: - Previews (Light and Dark)
#Preview("RootView - Not Authenticated") {
    RootView()
        .environment(AppSession(authRepository: MockAuthRepository()))
}

#Preview("RootView - 0 Memberships") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: []))
    session.currentUser = User(id: "1", name: "Sarah Ahmed", email: "sarah@example.com")
    return RootView()
        .environment(session)
}

#Preview("RootView - 1 Membership (Owner)") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "org1", organisationName: "Green Crescent", role: .owner)
    ]))
    session.currentUser = User(id: "1", name: "Sarah Ahmed", email: "sarah@example.com")
    session.activeMembership = session.memberships.first
    return RootView()
        .environment(session)
}
