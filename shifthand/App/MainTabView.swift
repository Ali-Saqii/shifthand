//
//  MainTabView.swift
//  shifthand
//
//  Fixed 3-tab TabView for Owner and Coordinator roles.
//  Strict order: 1. Events, 2. Live, 3. Volunteers.
//  Conforms strictly to AGENTS.md Section 2.
//

import SwiftUI

public struct MainTabView: View {
    @Environment(AppSession.self) private var session
    @State private var selectedTab: Tab = .events

    public enum Tab: Hashable {
        case events
        case live
        case volunteers
    }

    public init() {}

    public var body: some View {
        TabView(selection: $selectedTab) {
            // 1. Events
            EventsTabView()
                .tabItem {
                    Label("Events", systemImage: "calendar")
                }
                .tag(Tab.events)

            // 2. Live
            LiveTabView()
                .tabItem {
                    Label("Live", systemImage: "bolt.fill")
                }
                .tag(Tab.live)

            // 3. Volunteers
            VolunteersTabView()
                .tabItem {
                    Label("Volunteers", systemImage: "person.2.fill")
                }
                .tag(Tab.volunteers)
        }
        .tint(Color.shPrimaryTeal)
    }
}

// MARK: - Preview
#Preview("MainTabView - Owner") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "1", organisationName: "Green Crescent Food Bank", role: .owner)
    ]))
    session.currentUser = User(id: "1", name: "Sarah Ahmed", email: "sarah@example.com")
    session.activeMembership = session.memberships.first
    return MainTabView()
        .environment(session)
}
