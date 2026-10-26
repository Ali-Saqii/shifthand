//
//  LiveTabView.swift
//  shifthand
//
//  Live tab (Tab 2 of 3 for Owner and Coordinator).
//  Displays today's active shifts, live roster, and check-in entry points.
//  Conforms strictly to AGENTS.md.
//

import SwiftUI

public struct LiveTabView: View {
    @Environment(AppSession.self) private var session

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 20) {
                    EmptyState(
                        systemImage: "bolt.clock.fill",
                        title: "No shifts today",
                        message: "Today's shifts and live volunteer check-ins will appear here on event days."
                    )
                }
                .padding(20)
            }
            .navigationTitle("Live")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview
#Preview("LiveTabView") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "1", organisationName: "Green Crescent Food Bank", role: .coordinator)
    ]))
    return LiveTabView()
        .environment(session)
}
