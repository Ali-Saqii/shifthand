//
//  EventsTabView.swift
//  shifthand
//
//  Events tab (Tab 1 of 3 for Owner and Coordinator).
//  Displays Upcoming, Drafts, and Past events with full ViewState handling.
//  Includes avatar button leading to Settings and "+ New Event" action.
//  Conforms strictly to Docs/PLAN_IOS.md Day 5 and Docs/SCREENS.md.
//

import SwiftUI

public struct EventsTabView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel: EventsViewModel?
    @State private var showingSettings: Bool = false
    @State private var showingCreateEvent: Bool = false

    public init() {}

    public var body: some View {
        NavigationStack {
            ZStack {
                Color.shBackgroundPrimary
                    .ignoresSafeArea()

                if let vm = viewModel {
                    content(for: vm)
                } else {
                    LoadingView(message: "Initializing events...")
                }
            }
            .navigationTitle("Events")
            .navigationBarTitleDisplayMode(.large)
            .navigationDestination(isPresented: $showingSettings, destination: {
                SettingsView()
            })
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        // "+ New Event" Button
                        Button(action: { showingCreateEvent = true }) {
                            Image(systemName: "plus")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.shPrimaryTeal)
                                .frame(width: 32, height: 32)
                                .background(Color.shPrimaryTeal.opacity(0.12))
                                .clipShape(Circle())
                        }
                        .accessibilityLabel("Create New Event")

                        // Profile Avatar Button leading to Settings
                        Button(action: { showingSettings = true }) {
                            avatarButton
                        }
                        .accessibilityLabel("Profile and Settings")
                    }
                }
                if #available(iOS 26.0, *) {
                    ToolbarItem(placement: .topBarLeading) {
                        Image("applogo")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }.sharedBackgroundVisibility(.hidden)
                } else {
                    ToolbarItem(placement: .topBarLeading) {
                        Image("applogo")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
            }
            .task {
                if viewModel == nil {
                    let vm = EventsViewModel(appSession: session)
                    self.viewModel = vm
                    await vm.loadEvents()
                }
            }
            .sheet(isPresented: $showingCreateEvent) {
                CreateEventView(
                    viewModel: CreateEventViewModel(appSession: session),
                    onCreated: { _ in
                        Task {
                            await viewModel?.loadEvents(isRefresh: true)
                        }
                    }
                )
            }
        }
    }

    // MARK: - Content Rendering per ViewState

    @ViewBuilder
    private func content(for vm: EventsViewModel) -> some View {
        VStack(spacing: 0) {
            // Segmented Filter Picker
            Picker("Filter Events", selection: Bindable(vm).selectedFilter) {
                ForEach(EventsViewModel.EventFilter.allCases) { filter in
                    Text(filter.rawValue).tag(filter)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // State-driven Container
            switch vm.state {
            case .idle, .loading:
                LoadingView(message: "Loading \(vm.selectedFilter.rawValue.lowercased()) events...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

            case .loaded(let events):
                if events.isEmpty {
                    emptyStateView(for: vm)
                } else {
                    eventsListView(events: events, vm: vm)
                }

            case .failed(let error):
                VStack(spacing: 16) {
                    ErrorBanner(
                        message: error.errorDescription ?? "Failed to load events",
                        retryAction: {
                            Task {
                                await vm.loadEvents()
                            }
                        }
                    )
                    Spacer()
                }
                .padding(16)
            }
        }
    }

    // MARK: - Events List View

    private func eventsListView(events: [Event], vm: EventsViewModel) -> some View {
        ScrollView {
            LazyVStack(spacing: 14) {
                ForEach(events) { event in
                    NavigationLink(destination: EventDetailView(viewModel: EventDetailViewModel(eventId: event.id, appSession: session))) {
                        EventCardView(event: event)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 24)
        }
        .refreshable {
            await vm.loadEvents(isRefresh: true)
        }
    }

    // MARK: - Contextual Empty States

    private func emptyStateView(for vm: EventsViewModel) -> some View {
        Group {
            switch vm.selectedFilter {
            case .upcoming:
                EmptyState(
                    systemImage: "calendar.badge.plus",
                    title: "No upcoming events",
                    message: "Create and publish an event to recruit volunteers and schedule shifts.",
                    actionTitle: "New Event",
                    action: { showingCreateEvent = true }
                )
            case .drafts:
                EmptyState(
                    systemImage: "doc.text",
                    title: "No draft events",
                    message: "Draft events stay private while you configure shifts, capacity, and details.",
                    actionTitle: "New Event",
                    action: { showingCreateEvent = true }
                )
            case .past:
                EmptyState(
                    systemImage: "clock.arrow.circlepath",
                    title: "No past events",
                    message: "Completed and cancelled events will be archived here for reference."
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Avatar Button

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

// MARK: - Previews (Light and Dark)
#Preview("EventsTabView - Loaded") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "1", organisationName: "Green Crescent Food Bank", role: .owner)
    ]))
    session.currentUser = User(id: "1", name: "Sarah Ahmed", email: "sarah@example.com")
    session.activeMembership = session.memberships.first
    return EventsTabView()
        .environment(session)
}
