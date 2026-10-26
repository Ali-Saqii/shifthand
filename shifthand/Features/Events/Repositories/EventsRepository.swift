//
//  EventsRepository.swift
//  shifthand
//
//  Data layer protocol, Mock, and Live implementations for Organisation Events.
//  Conforms strictly to AGENTS.md and SHIFTHAND_MVP_SPEC_v2.md Section 5.3.
//

import Foundation

// MARK: - Protocol

@MainActor
public protocol EventsRepositoryProtocol: Sendable {
    func getEvents(status: String, cursor: String?, orgId: String) async throws -> (events: [Event], nextCursor: String?)
    func createEvent(title: String, description: String?, venue: String, startsAt: Date, endsAt: Date, orgId: String) async throws -> Event
    func getEvent(id: String, orgId: String) async throws -> Event
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

    public func getEvent(id: String, orgId: String) async throws -> Event {
        let token = await authSession.getAccessToken()
        let endpoint = Endpoint(path: "/events/\(id)", method: .get)
        let event: Event = try await apiClient.send(endpoint, token: token, orgId: orgId)
        return event
    }
}

// MARK: - Mock Repository

@MainActor
public final class MockEventsRepository: EventsRepositoryProtocol {
    public var simulatedEvents: [Event] = []
    public var shouldThrowError: AppError? = nil

    public init(initialEvents: [Event]? = nil) {
        if let initialEvents = initialEvents {
            self.simulatedEvents = initialEvents
        } else {
            self.simulatedEvents = Self.defaultMockEvents()
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
        return newEvent
    }

    public func getEvent(id: String, orgId: String) async throws -> Event {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        guard let event = simulatedEvents.first(where: { $0.id == id }) else {
            throw AppError.notFound
        }
        return event
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
