//
//  Membership.swift
//  shifthand
//
//  Represents staff membership within an organisation and assigned role.
//

import Foundation

public nonisolated struct Membership: Identifiable, Codable, Sendable, Equatable {
    public var id: String { organisationId }
    public let organisationId: String
    public let organisationName: String
    public let role: StaffRole

    public init(organisationId: String, organisationName: String, role: StaffRole) {
        self.organisationId = organisationId
        self.organisationName = organisationName
        self.role = role
    }
}
