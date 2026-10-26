//
//  Organisation.swift
//  shifthand
//
//  Organisation workspace model created by Owner.
//

import Foundation

public nonisolated struct Organisation: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let timezone: String
    public let role: StaffRole

    public init(id: String, name: String, timezone: String, role: StaffRole = .owner) {
        self.id = id
        self.name = name
        self.timezone = timezone
        self.role = role
    }
}
