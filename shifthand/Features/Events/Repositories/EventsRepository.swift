//
//  EventsRepository.swift
//  shifthand
//
//  Data layer protocol, Mock, and Live implementations for Organisation Events and Shifts.
//  Conforms strictly to AGENTS.md and SHIFTHAND_MVP_SPEC_v2.md Sections 5.3 & 5.4.
//

import Foundation

// MARK: - Protocol

@MainActor
public protocol EventsRepositoryProtocol: Sendable {
    func getEvents(status: String, cursor: String?, orgId: String) async throws -> (events: [Event], nextCursor: String?)
    func createEvent(title: String, description: String?, venue: String, startsAt: Date, endsAt: Date, orgId: String) async throws -> Event
    func getEventDetail(id: String, orgId: String) async throws -> EventDetail
    func publishEvent(id: String, orgId: String) async throws -> Event
    func cancelEvent(id: String, orgId: String) async throws -> Event
    func createShift(
        eventId: String,
        roleLabel: String,
        startsAtUtc: Date,
        endsAtUtc: Date,
        capacity: Int,
        cancelCutoffHours: Int,
        leadUserId: String?,
        notes: String?,
        orgId: String
    ) async throws -> Shift
    func updateShift(
        id: String,
        roleLabel: String,
        startsAtUtc: Date,
        endsAtUtc: Date,
        capacity: Int,
        confirmChange: Bool,
        leadUserId: String?,
        notes: String?,
        orgId: String
    ) async throws -> Shift
    func deleteShift(id: String, orgId: String) async throws
    func getOrgMembers(orgId: String) async throws -> [StaffMember]
}

// MARK: - Live Repository

@MainActor
public final class LiveEventsRepository: EventsRepositoryProtocol {
    private let apiClient: APIClient
    private let authSession: AuthSession

    public init(apiClient: APIClient = APIClient(), authSession: AuthSession = .shared) {
        self.apiClient = apiClient
        self.authSession = authSession
    }

    public func getEvents(status: String, cursor: String?, orgId: String) async throws -> (events: [Event], nextCursor: String?) {
        nonisolated struct EventsResponse: Decodable, Sendable {
            let data: [Event]
            let pageInfo: PageInfo?
        }

        var queryItems: [URLQueryItem] = [
            URLQueryItem(name: "status", value: status),
            URLQueryItem(name: "limit", value: "20")
        ]
        if let cursor = cursor {
            queryItems.append(URLQueryItem(name: "cursor", value: cursor))
        }

        let token = await authSession.getAccessToken()
        let endpoint = Endpoint(
            path: "/events",
            method: .get,
            queryItems: queryItems
        )

        let response: EventsResponse = try await apiClient.send(endpoint, token: token, orgId: orgId)
        return (events: response.data, nextCursor: response.pageInfo?.nextCursor)
    }

    public func createEvent(
        title: String,
        description: String?,
        venue: String,
        startsAt: Date,
        endsAt: Date,
        orgId: String
    ) async throws -> Event {
        nonisolated struct CreateEventRequest: Encodable, Sendable {
            let title: String
            let description: String?
            let venue: String
            let startsAt: String
            let endsAt: String
        }

        nonisolated struct CreateEventResponse: Decodable, Sendable {
            let id: String
            let status: EventStatus
            let publicSlug: String
        }

        let formatter = ISO8601DateFormatter()
        let reqBody = CreateEventRequest(
            title: title,
            description: description,
            venue: venue,
            startsAt: formatter.string(from: startsAt),
            endsAt: formatter.string(from: endsAt)
        )

        let token = await authSession.getAccessToken()
        let endpoint = try Endpoint.json(
            path: "/events",
            method: .post,
            body: reqBody
        )

        let response: CreateEventResponse = try await apiClient.send(endpoint, token: token, orgId: orgId)
        return Event(
            id: response.id,
            title: title,
            description: description,
            venue: venue,
            startsAt: startsAt,
            endsAt: endsAt,
            status: response.status,
            publicSlug: response.publicSlug,
            totalConfirmed: 0,
            totalCapacity: 0
        )
    }

    public func getEventDetail(id: String, orgId: String) async throws -> EventDetail {
        let token = await authSession.getAccessToken()
        let endpoint = Endpoint(path: "/events/\(id)", method: .get)
        let eventDetail: EventDetail = try await apiClient.send(endpoint, token: token, orgId: orgId)
        return eventDetail
    }

    public func publishEvent(id: String, orgId: String) async throws -> Event {
        let token = await authSession.getAccessToken()
        let endpoint = Endpoint(path: "/events/\(id)/publish", method: .post)
        let event: Event = try await apiClient.send(endpoint, token: token, orgId: orgId)
        return event
    }

    public func cancelEvent(id: String, orgId: String) async throws -> Event {
        let token = await authSession.getAccessToken()
        let endpoint = Endpoint(path: "/events/\(id)/cancel", method: .post)
        let event: Event = try await apiClient.send(endpoint, token: token, orgId: orgId)
        return event
    }

    public func createShift(
        eventId: String,
        roleLabel: String,
        startsAtUtc: Date,
        endsAtUtc: Date,
        capacity: Int,
        cancelCutoffHours: Int,
        leadUserId: String?,
        notes: String?,
        orgId: String
    ) async throws -> Shift {
        nonisolated struct CreateShiftRequest: Encodable, Sendable {
            let roleLabel: String
            let startsAtUtc: String
            let endsAtUtc: String
            let capacity: Int
            let cancelCutoffHours: Int
            let leadUserId: String?
            let notes: String?
        }

        let formatter = ISO8601DateFormatter()
        let body = CreateShiftRequest(
            roleLabel: roleLabel,
            startsAtUtc: formatter.string(from: startsAtUtc),
            endsAtUtc: formatter.string(from: endsAtUtc),
            capacity: capacity,
            cancelCutoffHours: cancelCutoffHours,
            leadUserId: leadUserId,
            notes: notes
        )

        let token = await authSession.getAccessToken()
        let endpoint = try Endpoint.json(path: "/events/\(eventId)/shifts", method: .post, body: body)
        let shift: Shift = try await apiClient.send(endpoint, token: token, orgId: orgId)
        return shift
    }

    public func updateShift(
        id: String,
        roleLabel: String,
        startsAtUtc: Date,
        endsAtUtc: Date,
        capacity: Int,
        confirmChange: Bool,
        leadUserId: String?,
        notes: String?,
        orgId: String
    ) async throws -> Shift {
        nonisolated struct UpdateShiftRequest: Encodable, Sendable {
            let roleLabel: String
            let startsAtUtc: String
            let endsAtUtc: String
            let capacity: Int
            let confirmChange: Bool
            let leadUserId: String?
            let notes: String?
        }

        let formatter = ISO8601DateFormatter()
        let body = UpdateShiftRequest(
            roleLabel: roleLabel,
            startsAtUtc: formatter.string(from: startsAtUtc),
            endsAtUtc: formatter.string(from: endsAtUtc),
            capacity: capacity,
            confirmChange: confirmChange,
            leadUserId: leadUserId,
            notes: notes
        )

        let token = await authSession.getAccessToken()
        let endpoint = try Endpoint.json(path: "/shifts/\(id)", method: .patch, body: body)
        let shift: Shift = try await apiClient.send(endpoint, token: token, orgId: orgId)
        return shift
    }

    public func deleteShift(id: String, orgId: String) async throws {
        let token = await authSession.getAccessToken()
        let endpoint = Endpoint(path: "/shifts/\(id)", method: .delete)
        try await apiClient.sendVoid(endpoint, token: token, orgId: orgId)
    }

    public func getOrgMembers(orgId: String) async throws -> [StaffMember] {
        nonisolated struct MembersResponse: Decodable, Sendable {
            let data: [StaffMember]
        }

        let token = await authSession.getAccessToken()
        let endpoint = Endpoint(path: "/organisations/\(orgId)/members", method: .get)
        let response: MembersResponse = try await apiClient.send(endpoint, token: token, orgId: orgId)
        return response.data
    }
}

// MARK: - Mock Repository

@MainActor
public final class MockEventsRepository: EventsRepositoryProtocol {
    public var simulatedEvents: [Event] = []
    public var simulatedDetails: [String: EventDetail] = [:]
    public var simulatedMembers: [StaffMember] = []
    public var shouldThrowError: AppError? = nil

    public init(initialEvents: [Event]? = nil) {
        setupDefaults(initialEvents: initialEvents)
    }

    private func setupDefaults(initialEvents: [Event]?) {
        if let initialEvents = initialEvents {
            self.simulatedEvents = initialEvents
        } else {
            self.simulatedEvents = Self.defaultMockEvents()
        }

        self.simulatedMembers = [
            StaffMember(id: "usr_1", name: "Sarah Ahmed", email: "sarah@example.com", role: .owner),
            StaffMember(id: "usr_2", name: "Bilal Qureshi", email: "bilal@example.com", role: .coordinator),
            StaffMember(id: "usr_3", name: "Tariq Vance", email: "tariq@example.com", role: .shiftLead),
            StaffMember(id: "usr_4", name: "Zainab Ali", email: "zainab@example.com", role: .shiftLead)
        ]

        // Populate detail entries with shifts
        for event in simulatedEvents {
            var shifts: [Shift] = []
            if event.id == "evt_1" {
                shifts = [
                    Shift(
                        id: "shf_1",
                        roleLabel: "Morning Sorter & Packer",
                        startsAtUtc: event.startsAt,
                        endsAtUtc: Calendar.current.date(byAdding: .hour, value: 3, to: event.startsAt) ?? event.startsAt,
                        capacity: 10,
                        confirmedCount: 8,
                        cancelCutoffHours: 24,
                        leadUserId: "usr_3",
                        leadUserName: "Tariq Vance",
                        notes: "Report to Hall B staging dock."
                    ),
                    Shift(
                        id: "shf_2",
                        roleLabel: "Afternoon Distribution Lead",
                        startsAtUtc: Calendar.current.date(byAdding: .hour, value: 3, to: event.startsAt) ?? event.startsAt,
                        endsAtUtc: event.endsAt,
                        capacity: 10,
                        confirmedCount: 6,
                        cancelCutoffHours: 24,
                        leadUserId: nil,
                        leadUserName: nil,
                        notes: "Directing car queue and vehicle boot loading."
                    )
                ]
            } else if event.id == "evt_2" {
                shifts = [
                    Shift(
                        id: "shf_3",
                        roleLabel: "Kit Assembler",
                        startsAtUtc: event.startsAt,
                        endsAtUtc: event.endsAt,
                        capacity: 10,
                        confirmedCount: 8,
                        cancelCutoffHours: 24,
                        leadUserId: "usr_4",
                        leadUserName: "Zainab Ali",
                        notes: "Packing emergency thermal survival kits."
                    )
                ]
            }

            self.simulatedDetails[event.id] = EventDetail(
                id: event.id,
                title: event.title,
                description: event.description,
                venue: event.venue,
                startsAt: event.startsAt,
                endsAt: event.endsAt,
                status: event.status,
                publicSlug: event.publicSlug,
                totalConfirmed: event.totalConfirmed,
                totalCapacity: event.totalCapacity,
                shifts: shifts
            )
        }
    }

    public func getEvents(status: String, cursor: String?, orgId: String) async throws -> (events: [Event], nextCursor: String?) {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        let filtered: [Event]
        switch status.lowercased() {
        case "upcoming":
            filtered = simulatedEvents.filter { $0.status == .published || $0.status == .live }
        case "drafts":
            filtered = simulatedEvents.filter { $0.status == .draft }
        case "past":
            filtered = simulatedEvents.filter { $0.status == .completed || $0.status == .cancelled }
        default:
            filtered = simulatedEvents
        }

        return (events: filtered, nextCursor: nil)
    }

    public func createEvent(
        title: String,
        description: String?,
        venue: String,
        startsAt: Date,
        endsAt: Date,
        orgId: String
    ) async throws -> Event {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        let newEvent = Event(
            id: UUID().uuidString,
            title: title,
            description: description,
            venue: venue,
            startsAt: startsAt,
            endsAt: endsAt,
            status: .draft,
            publicSlug: "mock_\(Int.random(in: 1000...9999))",
            totalConfirmed: 0,
            totalCapacity: 0
        )
        simulatedEvents.insert(newEvent, at: 0)
        simulatedDetails[newEvent.id] = EventDetail(
            id: newEvent.id,
            title: newEvent.title,
            description: newEvent.description,
            venue: newEvent.venue,
            startsAt: newEvent.startsAt,
            endsAt: newEvent.endsAt,
            status: .draft,
            publicSlug: newEvent.publicSlug,
            totalConfirmed: 0,
            totalCapacity: 0,
            shifts: []
        )
        return newEvent
    }

    public func getEventDetail(id: String, orgId: String) async throws -> EventDetail {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        guard let detail = simulatedDetails[id] else {
            throw AppError.notFound
        }
        return detail
    }

    public func publishEvent(id: String, orgId: String) async throws -> Event {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        guard var detail = simulatedDetails[id] else {
            throw AppError.notFound
        }
        detail.status = .published
        simulatedDetails[id] = detail

        if let idx = simulatedEvents.firstIndex(where: { $0.id == id }) {
            let updated = Event(
                id: detail.id,
                title: detail.title,
                description: detail.description,
                venue: detail.venue,
                startsAt: detail.startsAt,
                endsAt: detail.endsAt,
                status: .published,
                publicSlug: detail.publicSlug,
                totalConfirmed: detail.totalConfirmed,
                totalCapacity: detail.totalCapacity
            )
            simulatedEvents[idx] = updated
            return updated
        }
        throw AppError.notFound
    }

    public func cancelEvent(id: String, orgId: String) async throws -> Event {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        guard var detail = simulatedDetails[id] else {
            throw AppError.notFound
        }
        detail.status = .cancelled
        simulatedDetails[id] = detail

        if let idx = simulatedEvents.firstIndex(where: { $0.id == id }) {
            let updated = Event(
                id: detail.id,
                title: detail.title,
                description: detail.description,
                venue: detail.venue,
                startsAt: detail.startsAt,
                endsAt: detail.endsAt,
                status: .cancelled,
                publicSlug: detail.publicSlug,
                totalConfirmed: detail.totalConfirmed,
                totalCapacity: detail.totalCapacity
            )
            simulatedEvents[idx] = updated
            return updated
        }
        throw AppError.notFound
    }

    public func createShift(
        eventId: String,
        roleLabel: String,
        startsAtUtc: Date,
        endsAtUtc: Date,
        capacity: Int,
        cancelCutoffHours: Int,
        leadUserId: String?,
        notes: String?,
        orgId: String
    ) async throws -> Shift {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        guard var detail = simulatedDetails[eventId] else {
            throw AppError.notFound
        }

        let leadName = simulatedMembers.first(where: { $0.id == leadUserId })?.name
        let newShift = Shift(
            id: UUID().uuidString,
            roleLabel: roleLabel,
            startsAtUtc: startsAtUtc,
            endsAtUtc: endsAtUtc,
            capacity: capacity,
            confirmedCount: 0,
            cancelCutoffHours: cancelCutoffHours,
            leadUserId: leadUserId,
            leadUserName: leadName,
            notes: notes
        )

        detail.shifts.append(newShift)
        detail.totalCapacity += capacity
        simulatedDetails[eventId] = detail

        // Update list event model
        if let idx = simulatedEvents.firstIndex(where: { $0.id == eventId }) {
            let e = simulatedEvents[idx]
            simulatedEvents[idx] = Event(
                id: e.id,
                title: e.title,
                description: e.description,
                venue: e.venue,
                startsAt: e.startsAt,
                endsAt: e.endsAt,
                status: e.status,
                publicSlug: e.publicSlug,
                totalConfirmed: e.totalConfirmed,
                totalCapacity: detail.totalCapacity
            )
        }

        return newShift
    }

    public func updateShift(
        id: String,
        roleLabel: String,
        startsAtUtc: Date,
        endsAtUtc: Date,
        capacity: Int,
        confirmChange: Bool,
        leadUserId: String?,
        notes: String?,
        orgId: String
    ) async throws -> Shift {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        for (eventId, var detail) in simulatedDetails {
            if let idx = detail.shifts.firstIndex(where: { $0.id == id }) {
                let existing = detail.shifts[idx]
                if capacity < existing.confirmedCount {
                    throw AppError.server(
                        code: .unknown,
                        rawCode: "CAPACITY_BELOW_CONFIRMED",
                        message: "Capacity cannot be reduced below current confirmed signups (\(existing.confirmedCount)).",
                        requestId: nil
                    )
                }

                let leadName = simulatedMembers.first(where: { $0.id == leadUserId })?.name
                let updated = Shift(
                    id: existing.id,
                    roleLabel: roleLabel,
                    startsAtUtc: startsAtUtc,
                    endsAtUtc: endsAtUtc,
                    capacity: capacity,
                    confirmedCount: existing.confirmedCount,
                    cancelCutoffHours: existing.cancelCutoffHours,
                    leadUserId: leadUserId,
                    leadUserName: leadName,
                    notes: notes
                )
                detail.shifts[idx] = updated
                detail.totalCapacity = detail.shifts.reduce(0) { $0 + $1.capacity }
                simulatedDetails[eventId] = detail
                return updated
            }
        }
        throw AppError.notFound
    }

    public func deleteShift(id: String, orgId: String) async throws {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        for (eventId, var detail) in simulatedDetails {
            if let idx = detail.shifts.firstIndex(where: { $0.id == id }) {
                let existing = detail.shifts[idx]
                if existing.confirmedCount > 0 {
                    throw AppError.server(
                        code: .unknown,
                        rawCode: "SHIFT_HAS_SIGNUPS",
                        message: "A shift with confirmed volunteer signups cannot be deleted.",
                        requestId: nil
                    )
                }
                detail.shifts.remove(at: idx)
                detail.totalCapacity = detail.shifts.reduce(0) { $0 + $1.capacity }
                simulatedDetails[eventId] = detail
                return
            }
        }
        throw AppError.notFound
    }

    public func getOrgMembers(orgId: String) async throws -> [StaffMember] {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }
        return simulatedMembers
    }

    private func simulateLatency() async throws {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
    }

    public static func defaultMockEvents() -> [Event] {
        let calendar = Calendar.current
        let now = Date()

        let tomorrow = calendar.date(byAdding: .day, value: 1, to: now) ?? now
        let nextWeek = calendar.date(byAdding: .day, value: 7, to: now) ?? now
        let pastDate = calendar.date(byAdding: .day, value: -5, to: now) ?? now

        return [
            Event(
                id: "evt_1",
                title: "Community Food Drive & Distribution",
                description: "Sorting and packing fresh produce boxes for local families.",
                venue: "Civic Hall, Main Warehouse",
                startsAt: tomorrow,
                endsAt: calendar.date(byAdding: .hour, value: 6, to: tomorrow) ?? tomorrow,
                status: .published,
                publicSlug: "cfd-nov26",
                totalConfirmed: 14,
                totalCapacity: 20
            ),
            Event(
                id: "evt_2",
                title: "Winter Shelter Warming Packs",
                description: "Assembling thermal blankets, hats, and non-perishable snack kits.",
                venue: "St. Jude Centre, Hall A",
                startsAt: nextWeek,
                endsAt: calendar.date(byAdding: .hour, value: 4, to: nextWeek) ?? nextWeek,
                status: .published,
                publicSlug: "wsp-nov26",
                totalConfirmed: 8,
                totalCapacity: 10
            ),
            Event(
                id: "evt_3",
                title: "Annual Benefit Gala Setup",
                description: "Stage construction, sound checking, and banquet arrangement.",
                venue: "Harbour Grand Pavilion",
                startsAt: calendar.date(byAdding: .day, value: 14, to: now) ?? now,
                endsAt: calendar.date(byAdding: .day, value: 14, to: now) ?? now,
                status: .draft,
                publicSlug: "gala-setup",
                totalConfirmed: 0,
                totalCapacity: 0
            ),
            Event(
                id: "evt_4",
                title: "Autumn Riverside Cleanup",
                description: "Cleaned 3 miles of riverbanks with community volunteers.",
                venue: "Millers Wharf Park",
                startsAt: pastDate,
                endsAt: calendar.date(byAdding: .hour, value: 3, to: pastDate) ?? pastDate,
                status: .completed,
                publicSlug: "river-cleanup-26",
                totalConfirmed: 25,
                totalCapacity: 25
            )
        ]
    }
}
