//
//  Event.swift
//  shifthand
//
//  Event domain models and status enums conforming to SHIFTHAND_MVP_SPEC_v2.md Section 5.3.
//

import Foundation

public nonisolated enum EventStatus: String, Codable, Sendable, CaseIterable, Equatable {
    case draft = "draft"
    case published = "published"
    case live = "live"
    case completed = "completed"
    case cancelled = "cancelled"

    public var displayName: String {
        switch self {
        case .draft: return "Draft"
        case .published: return "Published"
        case .live: return "Live"
        case .completed: return "Completed"
        case .cancelled: return "Cancelled"
        }
    }

    public var iconName: String {
        switch self {
        case .draft: return "doc.text"
        case .published: return "checkmark.seal.fill"
        case .live: return "bolt.fill"
        case .completed: return "flag.checkered"
        case .cancelled: return "xmark.circle.fill"
        }
    }

    public var chipStyle: StatusChipStyle {
        switch self {
        case .draft: return .grey
        case .published: return .teal
        case .live: return .green
        case .completed: return .blue
        case .cancelled: return .red
        }
    }
}

public nonisolated struct Event: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let title: String
    public let description: String?
    public let venue: String
    public let startsAt: Date
    public let endsAt: Date
    public let status: EventStatus
    public let publicSlug: String
    public let totalConfirmed: Int
    public let totalCapacity: Int

    public init(
        id: String,
        title: String,
        description: String? = nil,
        venue: String,
        startsAt: Date,
        endsAt: Date,
        status: EventStatus = .draft,
        publicSlug: String,
        totalConfirmed: Int = 0,
        totalCapacity: Int = 0
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
    }

    public var isFull: Bool {
        return totalCapacity > 0 && totalConfirmed >= totalCapacity
    }
}

public nonisolated struct PageInfo: Codable, Sendable, Equatable {
    public let nextCursor: String?
    public let hasMore: Bool?

    public init(nextCursor: String? = nil, hasMore: Bool? = nil) {
        self.nextCursor = nextCursor
        self.hasMore = hasMore
    }
}
