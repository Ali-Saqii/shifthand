//
//  EventsTabView.swift
//  shifthand
//
//  Events tab (Tab 1 of 3 for Owner and Coordinator).
//  Includes profile avatar button (top-right) which opens SettingsView.
//  Conforms strictly to AGENTS.md and UI_STANDARDS.md.
//

import SwiftUI

public struct EventsTabView: View {
    @Environment(AppSession.self) private var session
    @State private var showingSettings: Bool = false
    @State private var selectedFilter: EventFilter = .upcoming

    public enum EventFilter: String, CaseIterable, Identifiable {
        case upcoming = "Upcoming"
        case drafts = "Drafts"
        case past = "Past"
        public var id: String { rawValue }
    }

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Filter picker
                    Picker("Filter Events", selection: $selectedFilter) {
                        ForEach(EventFilter.allCases) { filter in
                            Text(filter.rawValue).tag(filter)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    // Events content (Day 5 expands list cards; Day 4 displays clean empty state)
                    EmptyState(
                        systemImage: "calendar.badge.plus",
                        title: "No \(selectedFilter.rawValue.lowercased()) events",
                        message: "Create and publish events to recruit and schedule volunteers with defined shift capacities.",
                        actionTitle: "New Event",
                        action: {
                            // Handled in Day 5
                        }
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        avatarButton
                    }
                    .accessibilityLabel("Profile and Settings")
                }
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
    }

    private var avatarButton: some View {
        Circle()
            .fill(Color.shPrimaryTeal.opacity(0.15))
            .frame(width: 34, height: 34)
            .overlay(
                Text(initials)
                    .font(.caption.bold())
                    .foregroundStyle(Color.shPrimaryTeal)
            )
            .overlay(
                Circle()
                    .stroke(Color.shPrimaryTeal.opacity(0.3), lineWidth: 1)
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
}

// MARK: - Preview
#Preview("EventsTabView") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "1", organisationName: "Green Crescent Food Bank", role: .owner)
    ]))
    session.currentUser = User(id: "1", name: "Sarah Ahmed", email: "sarah@example.com")
    session.activeMembership = session.memberships.first
    return EventsTabView()
        .environment(session)
}
