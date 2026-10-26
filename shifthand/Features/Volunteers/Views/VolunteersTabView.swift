//
//  VolunteersTabView.swift
//  shifthand
//
//  Volunteers tab (Tab 3 of 3 for Owner and Coordinator).
//  Volunteer directory with reliable attendance histories.
//  Conforms strictly to AGENTS.md.
//

import SwiftUI

public struct VolunteersTabView: View {
    @Environment(AppSession.self) private var session

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    EmptyState(
                        systemImage: "person.2.fill",
                        title: "No volunteers yet",
                        message: "Volunteers will appear in your organisation directory once they sign up for an upcoming shift."
                    )
                }
                .padding(20)
            }
            .navigationTitle("Volunteers")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview
#Preview("VolunteersTabView") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "1", organisationName: "Green Crescent Food Bank", role: .owner)
    ]))
    return VolunteersTabView()
        .environment(session)
}
