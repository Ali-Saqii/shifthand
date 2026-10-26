//
//  EventDetailView.swift
//  shifthand
//
//  Event Detail Screen (Screen #3).
//  Displays event overview, public URL share sheet, shift cards list, and publish/cancel controls.
//  Conforms strictly to Docs/SCREENS.md and SHIFTHAND_MVP_SPEC_v2.md Section 5.3.
//

import SwiftUI

public struct EventDetailView: View {
    @Environment(AppSession.self) private var session
    @State private var viewModel: EventDetailViewModel

    @State private var selectedShiftForEdit: Shift? = nil
    @State private var showingAddShiftSheet: Bool = false
    @State private var showingCancelDialog: Bool = false
    @State private var copiedLinkToast: Bool = false

    public init(viewModel: EventDetailViewModel) {
        self._viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ZStack {
            Color.shBackgroundPrimary
                .ignoresSafeArea()

            switch viewModel.state {
            case .idle, .loading:
                LoadingView(message: "Loading event details...")

            case .loaded(let detail):
                loadedContent(detail: detail)

            case .failed(let error):
                VStack(spacing: 16) {
                    ErrorBanner(
                        message: error.errorDescription ?? "Failed to load event details",
                        retryAction: {
                            Task {
                                await viewModel.loadDetail()
                            }
                        }
                    )
                    Spacer()
                }
                .padding(20)
            }
        }
        .navigationTitle("Event Detail")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if case .loaded(let detail) = viewModel.state {
                ToolbarItem(placement: .topBarTrailing) {
                    menuButton(detail: detail)
                }
            }
        }
        .task {
            await viewModel.loadDetail()
        }
        .sheet(isPresented: $showingAddShiftSheet) {
            if case .loaded(let detail) = viewModel.state {
                ShiftEditorView(
                    viewModel: ShiftEditorViewModel(
                        eventId: detail.id,
                        eventStartDate: detail.startsAt,
                        appSession: session
                    ),
                    onSaved: { _ in
                        Task { await viewModel.loadDetail(isRefresh: true) }
                    }
                )
            }
        }
        .sheet(item: $selectedShiftForEdit) { shift in
            if case .loaded(let detail) = viewModel.state {
                ShiftEditorView(
                    viewModel: ShiftEditorViewModel(
                        eventId: detail.id,
                        existingShift: shift,
                        eventStartDate: detail.startsAt,
                        appSession: session
                    ),
                    onSaved: { _ in
                        Task { await viewModel.loadDetail(isRefresh: true) }
                    },
                    onDeleted: {
                        Task { await viewModel.loadDetail(isRefresh: true) }
                    }
                )
            }
        }
        .confirmationDialog(
            "Cancel Event",
            isPresented: $showingCancelDialog,
            titleVisibility: .visible
        ) {
            Button("Cancel Event and Notify Volunteers", role: .destructive) {
                Task {
                    await viewModel.cancelEvent()
                }
            }
            Button("Keep Event", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this event? All active volunteer sign-ups will be cancelled and cancellation emails will be queued.")
        }
    }

    // MARK: - Loaded Content View

    private func loadedContent(detail: EventDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Card
                headerCard(detail: detail)

                // Public URL & WhatsApp Sharing Banner
                if detail.status == .published || detail.status == .live {
                    publicShareBanner(detail: detail)
                }

                // Shifts Section Header
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Shifts")
                            .font(.title3.bold())
                            .foregroundStyle(Color.shTextPrimary)

                        Text("\(detail.shifts.count) scheduled shift\(detail.shifts.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundStyle(Color.shTextSecondary)
                    }

                    Spacer()

                    if detail.status != .cancelled && detail.status != .completed {
                        Button(action: { showingAddShiftSheet = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "plus")
                                Text("Add Shift")
                            }
                            .font(.subheadline.bold())
                            .foregroundStyle(Color.shPrimaryTeal)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.shPrimaryTeal.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 4)

                // Shifts List or Empty State
                if detail.shifts.isEmpty {
                    EmptyState(
                        systemImage: "clock.badge.plus",
                        title: "No shifts added yet",
                        message: "Add your first shift with defined times and capacity to open sign-ups.",
                        actionTitle: "Add Shift",
                        action: { showingAddShiftSheet = true }
                    )
                    .padding(.top, 12)
                } else {
                    LazyVStack(spacing: 12) {
                        ForEach(detail.shifts) { shift in
                            ShiftCardView(shift: shift) {
                                if detail.status != .cancelled {
                                    selectedShiftForEdit = shift
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
        .refreshable {
            await viewModel.loadDetail(isRefresh: true)
        }
    }

    // MARK: - Header Card

    private func headerCard(detail: EventDetail) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(detail.title)
                        .font(.title2.bold())
                        .foregroundStyle(Color.shTextPrimary)

                    HStack(spacing: 6) {
                        Image(systemName: "mappin.and.ellipse")
                            .foregroundStyle(Color.shPrimaryTeal)
                        Text(detail.venue)
                            .font(.subheadline)
                            .foregroundStyle(Color.shTextSecondary)
                    }
                }

                Spacer()

                StatusChip(
                    title: detail.status.displayName,
                    systemImage: detail.status.iconName,
                    style: detail.status.chipStyle
                )
            }

            // Date & Time
            HStack(spacing: 8) {
                Image(systemName: "calendar")
                    .foregroundStyle(Color.shTextSecondary)
                Text(formattedDateRange(startsAt: detail.startsAt, endsAt: detail.endsAt))
                    .font(.subheadline)
                    .foregroundStyle(Color.shTextSecondary)
            }

            if let desc = detail.description, !desc.isEmpty {
                Text(desc)
                    .font(.body)
                    .foregroundStyle(Color.shTextPrimary)
                    .padding(.top, 2)
            }

            // Total Attendance Capacity
            if detail.totalCapacity > 0 {
                Divider()
                    .background(Color.shBorderDefault)

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Overall Attendance")
                            .font(.caption.weight(.medium))
                            .foregroundStyle(Color.shTextSecondary)

                        Spacer()

                        Text("\(detail.totalConfirmed)/\(detail.totalCapacity) confirmed")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Color.shTextPrimary)
                    }

                    CapacityBar(
                        confirmed: detail.totalConfirmed,
                        capacity: detail.totalCapacity
                    )
                }
            }
        }
        .padding(16)
        .background(Color.shBackgroundCard)
        .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: SHCornerRadius.large)
                .stroke(Color.shBorderDefault, lineWidth: 1)
        )
    }

    // MARK: - Public Share Banner

    private func publicShareBanner(detail: EventDetail) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label("Public Sign-up Link", systemImage: "link")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color.shTextSecondary)
                    .textCase(.uppercase)

                Spacer()

                if copiedLinkToast {
                    Text("Copied!")
                        .font(.caption.bold())
                        .foregroundStyle(Color.shStatusGreen)
                }
            }

            Text(detail.publicURL.absoluteString)
                .font(.footnote.monospaced())
                .foregroundStyle(Color.shPrimaryTeal)
                .lineLimit(1)

            HStack(spacing: 12) {
                // Copy Link Button
                Button(action: {
                    UIPasteboard.general.url = detail.publicURL
                    copiedLinkToast = true
                    Task {
                        try? await Task.sleep(nanoseconds: 2_000_000_000)
                        copiedLinkToast = false
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "doc.on.doc")
                        Text("Copy Link")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.shPrimaryTeal)
                    .frame(maxWidth: .infinity)
                    .frame(height: SHMetrics.minTouchTarget)
                    .background(Color.shBackgroundCard)
                    .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                            .stroke(Color.shBorderDefault, lineWidth: 1)
                    )
                }

                // WhatsApp / Share Sheet
                ShareLink(
                    item: detail.publicURL,
                    message: Text("Volunteer with us at \(detail.title): \(detail.publicURL.absoluteString)")
                ) {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share via WhatsApp")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Color.shDarkTeal)
                    .frame(maxWidth: .infinity)
                    .frame(height: SHMetrics.minTouchTarget)
                    .background(Color.shBackgroundCard)
                    .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.medium))
                    .overlay(
                        RoundedRectangle(cornerRadius: SHCornerRadius.medium)
                            .stroke(Color.shBorderDefault, lineWidth: 1)
                    )
                }
            }
        }
        .padding(14)
        .background(Color.shPrimaryTeal.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: SHCornerRadius.large))
        .overlay(
            RoundedRectangle(cornerRadius: SHCornerRadius.large)
                .stroke(Color.shPrimaryTeal.opacity(0.2), lineWidth: 1)
        )
    }

    // MARK: - Toolbar Menu Button

    private func menuButton(detail: EventDetail) -> some View {
        Menu {
            if detail.status == .draft {
                Button(action: {
                    Task { await viewModel.publishEvent() }
                }) {
                    Label("Publish Event", systemImage: "checkmark.seal.fill")
                }
            }

            if detail.status != .cancelled && detail.status != .completed {
                Button(role: .destructive, action: { showingCancelDialog = true }) {
                    Label("Cancel Event", systemImage: "xmark.circle")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 20))
                .foregroundStyle(Color.shPrimaryTeal)
                .frame(width: SHMetrics.minTouchTarget, height: SHMetrics.minTouchTarget)
        }
    }

    private func formattedDateRange(startsAt: Date, endsAt: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "EEE, d MMM yyyy"
        let tf = DateFormatter()
        tf.dateFormat = "HH:mm"
        return "\(df.string(from: startsAt)) • \(tf.string(from: startsAt)) - \(tf.string(from: endsAt))"
    }
}

// MARK: - Preview
#Preview("EventDetailView - Published") {
    let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [
        Membership(organisationId: "1", organisationName: "Green Crescent Food Bank", role: .owner)
    ]))
    session.currentUser = User(id: "1", name: "Sarah Ahmed", email: "sarah@example.com")
    session.activeMembership = session.memberships.first

    return NavigationStack {
        EventDetailView(
            viewModel: EventDetailViewModel(
                eventId: "evt_1",
                appSession: session
            )
        )
    }
    .environment(session)
}
