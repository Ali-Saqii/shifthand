//
//  StaffMember.swift
//  shifthand
//
//  Staff member model representing an organisation member for shift lead assignment.
//

import Foundation

public nonisolated struct StaffMember: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let email: String
    public let role: StaffRole

    public init(id: String, name: String, email: String, role: StaffRole) {
        self.id = id
        self.name = name
        self.email = email
        self.role = role
    }
}
