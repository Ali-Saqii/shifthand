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
                // 1. Unauthenticated -> Sign In / Register
                SignInView(viewModel: AuthViewModel(appSession: session))
            } else if session.membershipCount == 0 {
                // 2. 0 Memberships -> Onboarding (Create Org or Join Org)
                OnboardingView(viewModel: OnboardingViewModel(appSession: session))
            } else if session.membershipCount > 1 && session.activeMembership == nil {
                // 3. 2+ Memberships with no selection -> OrgPickerView
                OrgPickerView(isDismissable: false)
            } else if let activeOrg = session.activeMembership {
                // 4. Active Organisation Selected -> Route strictly by role
                switch activeOrg.role {
                case .shiftLead:
                    // Shift Lead: NEVER sees a TabBar and never sees Events or Volunteers tabs
                    ShiftLeadHomeView()
                case .owner, .coordinator:
                    // Owner & Coordinator: Fixed 3-tab TabView (Events, Live, Volunteers)
                    MainTabView()
                }
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
        Membership(organisationId: "org1", organisationName: "Green Crescent Food Bank", role: .owner)
    ]))
    session.currentUser = User(id: "1", name: "Sarah Ahmed", email: "sarah@example.com")
    session.activeMembership = session.memberships.first
    return RootView()
        .environment(session)
}

#Preview("RootView - 1 Membership (Shift Lead)") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "org2", organisationName: "Downtown Youth Shelter", role: .shiftLead)
    ]))
    session.currentUser = User(id: "2", name: "Tariq Vance", email: "tariq@example.com")
    session.activeMembership = session.memberships.first
    return RootView()
        .environment(session)
}

#Preview("RootView - 2+ Memberships (Picker at Launch)") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "org1", organisationName: "Green Crescent Food Bank", role: .owner),
        Membership(organisationId: "org2", organisationName: "Downtown Youth Shelter", role: .shiftLead)
    ]))
    session.currentUser = User(id: "1", name: "Sarah Ahmed", email: "sarah@example.com")
    session.activeMembership = nil
    return RootView()
        .environment(session)
}
