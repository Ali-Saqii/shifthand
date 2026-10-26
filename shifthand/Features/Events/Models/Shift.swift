//
//  Shift.swift
//  shifthand
//
//  Shift domain model and helper structs conforming to SHIFTHAND_MVP_SPEC_v2.md Section 5.4.
//

import Foundation

public nonisolated struct Shift: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let roleLabel: String
    public let startsAtUtc: Date
    public let endsAtUtc: Date
    public let capacity: Int
    public let confirmedCount: Int
    public let cancelCutoffHours: Int
    public let leadUserId: String?
    public let leadUserName: String?
    public let notes: String?

    public init(
        id: String,
        roleLabel: String,
        startsAtUtc: Date,
        endsAtUtc: Date,
        capacity: Int,
        confirmedCount: Int = 0,
        cancelCutoffHours: Int = 24,
        leadUserId: String? = nil,
        leadUserName: String? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.roleLabel = roleLabel
        self.startsAtUtc = startsAtUtc
        self.endsAtUtc = endsAtUtc
        self.capacity = capacity
        self.confirmedCount = confirmedCount
        self.cancelCutoffHours = cancelCutoffHours
        self.leadUserId = leadUserId
        self.leadUserName = leadUserName
        self.notes = notes
    }

    public var isFull: Bool {
        return capacity > 0 && confirmedCount >= capacity
    }

    public var seatsLeft: Int {
        return max(0, capacity - confirmedCount)
    }
}

public nonisolated struct EventDetail: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let description: String?
    public let venue: String
    public let startsAt: Date
    public let endsAt: Date
    public var status: EventStatus
    public let publicSlug: String
    public var totalConfirmed: Int
    public var totalCapacity: Int
    public var shifts: [Shift]

    public init(
        id: String,
        title: String,
        description: String? = nil,
        venue: String,
        startsAt: Date,
        endsAt: Date,
        status: EventStatus,
        publicSlug: String,
        totalConfirmed: Int = 0,
        totalCapacity: Int = 0,
        shifts: [Shift] = []
    ) {
        self.id = id
        self.title = title
        self.description = description
        self.venue = venue
        self.startsAt = startsAt
        self.endsAt = endsAt
        self.status = status
        self.publicSlug = publicSlug
        self.totalConfirmed = totalConfirmed
        self.totalCapacity = totalCapacity
        self.shifts = shifts
    }

    public var publicURL: URL {
        return URL(string: "https://shifthand.org/e/\(publicSlug)") ?? URL(string: "https://shifthand.org")!
    }
}
