//
//  shifthandTests.swift
//  shifthandTests
//
//  Comprehensive Unit & RBAC Tests conforming to AGENTS.md and PLAN_IOS.md Day 7.
//

import Testing
import Foundation
@testable import shifthand

struct Day1Tests {

    // MARK: - Endpoint & URL Request Tests

    @Test func testEndpointURLConstruction() throws {
        let baseURL = URL(string: "http://localhost:3000/api/v1")!
        let endpoint = Endpoint(
            path: "/events",
            method: .get,
            queryItems: [URLQueryItem(name: "status", value: "upcoming")],
            headers: ["X-Test": "Value"],
            idempotencyKey: "idem_12345"
        )

        let request = try endpoint.urlRequest(baseURL: baseURL, token: "test_jwt_token", orgId: "org_test_999")

        #expect(request.url?.absoluteString == "http://localhost:3000/api/v1/events?status=upcoming")
        #expect(request.httpMethod == "GET")
        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test_jwt_token")
        #expect(request.value(forHTTPHeaderField: "X-Org-Id") == "org_test_999")
        #expect(request.value(forHTTPHeaderField: "Idempotency-Key") == "idem_12345")
        #expect(request.value(forHTTPHeaderField: "X-Test") == "Value")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    @Test func testEndpointPathNormalization() throws {
        let baseURL = URL(string: "https://api.shifthand.org/api/v1/")!
        let endpoint = Endpoint(path: "events/4411/shifts")

        let request = try endpoint.urlRequest(baseURL: baseURL)
        #expect(request.url?.path == "/api/v1/events/4411/shifts")
    }

    // MARK: - API Error Mapping Tests

    @Test func testServerErrorEnvelopeDecoding() throws {
        let json = """
        {
            "error": {
                "code": "SHIFT_FULL",
                "message": "This shift is full",
                "details": { "waitlistAvailable": "true" },
                "requestId": "req_abc123"
            }
        }
        """.data(using: .utf8)!

        let envelope = try JSONDecoder().decode(ServerErrorEnvelope.self, from: json)
        #expect(envelope.error.code == "SHIFT_FULL")
        #expect(envelope.error.message == "This shift is full")
        #expect(envelope.error.requestId == "req_abc123")

        let code = ServerErrorCode(rawValue: envelope.error.code)
        #expect(code == .shiftFull)
    }

    @Test func testAlreadyCheckedInErrorDetection() {
        let error = AppError.alreadyCheckedIn(checkedInAt: "09:14", message: "Already checked in")
        #expect(error.isAlreadyCheckedIn)
        #expect(error.errorDescription == "Already here since 09:14")
    }

    // MARK: - KeychainStore Tests

    @Test func testKeychainStoreSaveAndRetrieve() throws {
        let store = KeychainStore(keyPrefix: "test_shifthand_")
        let token = "test_refresh_token_256bit_sample"

        try store.saveRefreshToken(token)
        let retrieved = store.getRefreshToken()
        #expect(retrieved == token)

        try store.deleteRefreshToken()
        let afterDelete = store.getRefreshToken()
        #expect(afterDelete == nil)
    }

    // MARK: - Design Tokens & Metrics Tests

    @Test func testDesignMetricsCompliance() {
        #expect(SHMetrics.cardCornerRadius == 16)
        #expect(SHMetrics.buttonCornerRadius == 12)
        #expect(SHMetrics.chipCornerRadius == 8)
        #expect(SHMetrics.minTouchTarget >= 44)
    }
}

// MARK: - Day 7 RBAC & Navigation Tests

struct Day7RBACTests {

    @Test func testStaffRolesValuesAndDisplayNames() {
        #expect(StaffRole.owner.rawValue == "owner")
        #expect(StaffRole.coordinator.rawValue == "coordinator")
        #expect(StaffRole.shiftLead.rawValue == "shift_lead")

        #expect(StaffRole.owner.displayName == "Owner")
        #expect(StaffRole.coordinator.displayName == "Coordinator")
        #expect(StaffRole.shiftLead.displayName == "Shift Lead")
    }

    @Test @MainActor func testSessionRoutingWithZeroMemberships() {
        let session = AppSession(authRepository: MockAuthRepository(initialMemberships: []))
        session.currentUser = User(id: "usr_1", name: "Alex Lee", email: "alex@example.com")

        #expect(session.isAuthenticated)
        #expect(session.membershipCount == 0)
        #expect(session.activeMembership == nil)
        #expect(session.activeRole == nil)
    }

    @Test @MainActor func testSessionRoutingSingleOwnerMembership() {
        let ownerOrg = Membership(organisationId: "org_1", organisationName: "Food Rescue", role: .owner)
        let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [ownerOrg]))
        session.currentUser = User(id: "usr_1", name: "Sarah Ahmed", email: "sarah@example.com")
        session.activeMembership = ownerOrg

        #expect(session.membershipCount == 1)
        #expect(session.activeRole == .owner)
        #expect(session.activeMembership?.organisationId == "org_1")
    }

    @Test @MainActor func testSessionRoutingSingleShiftLeadMembership() {
        let leadOrg = Membership(organisationId: "org_2", organisationName: "Youth Shelter", role: .shiftLead)
        let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [leadOrg]))
        session.currentUser = User(id: "usr_2", name: "Tariq Vance", email: "tariq@example.com")
        session.activeMembership = leadOrg

        #expect(session.membershipCount == 1)
        #expect(session.activeRole == .shiftLead)
        #expect(session.activeRole?.displayName == "Shift Lead")
    }

    @Test @MainActor func testSessionMultiOrgSwitcherUpdatesRole() {
        let orgOwner = Membership(organisationId: "org_1", organisationName: "Food Rescue", role: .owner)
        let orgLead = Membership(organisationId: "org_2", organisationName: "Youth Shelter", role: .shiftLead)

        let session = AppSession(authRepository: MockAuthRepository(initialMemberships: [orgOwner, orgLead]))
        session.currentUser = User(id: "usr_1", name: "Sarah Ahmed", email: "sarah@example.com")
        session.activeMembership = orgOwner

        #expect(session.membershipCount == 2)
        #expect(session.activeRole == .owner)

        // Switch to Org 2
        session.setActiveOrganisation(orgLead)
        #expect(session.activeMembership?.organisationId == "org_2")
        #expect(session.activeRole == .shiftLead)
    }
}

// MARK: - Day 7 Validation Tests

struct Day7ValidationTests {

    @Test func testEventCapacityAndFullState() {
        let eventNotFull = Event(
            id: "evt_1",
            title: "Food Drive",
            venue: "Hall A",
            startsAt: Date(),
            endsAt: Date().addingTimeInterval(3600),
            status: .published,
            publicSlug: "fd-1",
            totalConfirmed: 8,
            totalCapacity: 10
        )
        #expect(!eventNotFull.isFull)

        let eventFull = Event(
            id: "evt_2",
            title: "Food Drive Packed",
            venue: "Hall A",
            startsAt: Date(),
            endsAt: Date().addingTimeInterval(3600),
            status: .published,
            publicSlug: "fd-2",
            totalConfirmed: 10,
            totalCapacity: 10
        )
        #expect(eventFull.isFull)
    }

    @Test func testShiftCapacityAndSeatsLeft() {
        let shift = Shift(
            id: "shf_1",
            roleLabel: "Registration Desk",
            startsAtUtc: Date(),
            endsAtUtc: Date().addingTimeInterval(7200),
            capacity: 6,
            confirmedCount: 4
        )
        #expect(shift.seatsLeft == 2)
        #expect(!shift.isFull)

        let fullShift = Shift(
            id: "shf_2",
            roleLabel: "Greeter",
            startsAtUtc: Date(),
            endsAtUtc: Date().addingTimeInterval(7200),
            capacity: 5,
            confirmedCount: 5
        )
        #expect(fullShift.seatsLeft == 0)
        #expect(fullShift.isFull)
    }

    @Test @MainActor func testShiftCapacityReductionBelowConfirmedThrowsError() async {
        let repo = MockEventsRepository()
        let event = try! await repo.createEvent(
            title: "Test Event",
            description: nil,
            venue: "Warehouse",
            startsAt: Date(),
            endsAt: Date().addingTimeInterval(14400),
            orgId: "org_1"
        )

        let shift = try! await repo.createShift(
            eventId: event.id,
            roleLabel: "Driver",
            startsAtUtc: Date(),
            endsAtUtc: Date().addingTimeInterval(7200),
            capacity: 5,
            cancelCutoffHours: 24,
            leadUserId: nil,
            notes: nil,
            orgId: "org_1"
        )

        // Simulate confirmed signups by updating internal detail
        if var detail = repo.simulatedDetails[event.id] {
            detail.shifts[0] = Shift(
                id: shift.id,
                roleLabel: shift.roleLabel,
                startsAtUtc: shift.startsAtUtc,
                endsAtUtc: shift.endsAtUtc,
                capacity: 5,
                confirmedCount: 4
            )
            repo.simulatedDetails[event.id] = detail
        }

        // Attempting to reduce capacity to 2 (below 4 confirmed) should throw CAPACITY_BELOW_CONFIRMED
        do {
            _ = try await repo.updateShift(
                id: shift.id,
                roleLabel: "Driver",
                startsAtUtc: shift.startsAtUtc,
                endsAtUtc: shift.endsAtUtc,
                capacity: 2,
                confirmChange: false,
                leadUserId: nil,
                notes: nil,
                orgId: "org_1"
            )
            #expect(Bool(false), "Should have thrown CAPACITY_BELOW_CONFIRMED")
        } catch let appError as AppError {
            if case .server(_, let rawCode, _, _) = appError {
                #expect(rawCode == "CAPACITY_BELOW_CONFIRMED")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type")
        }
    }

    @Test @MainActor func testShiftDeletionBlockedWithConfirmedSignups() async {
        let repo = MockEventsRepository()
        // Event evt_1 has shift shf_1 with 8 confirmed volunteers
        do {
            try await repo.deleteShift(id: "shf_1", orgId: "org_1")
            #expect(Bool(false), "Should have thrown SHIFT_HAS_SIGNUPS")
        } catch let appError as AppError {
            if case .server(_, let rawCode, _, _) = appError {
                #expect(rawCode == "SHIFT_HAS_SIGNUPS")
            }
        } catch {
            #expect(Bool(false), "Unexpected error type")
        }
    }
}
