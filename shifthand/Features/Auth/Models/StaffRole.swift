//
//  StaffRole.swift
//  shifthand
//
//  Staff roles per organisation membership. Determined strictly on the server.
//

import Foundation

public nonisolated enum StaffRole: String, Codable, Sendable, CaseIterable {
    case owner = "owner"
    case coordinator = "coordinator"
    case shiftLead = "shift_lead"

    public var displayName: String {
        switch self {
        case .owner: return "Owner"
        case .coordinator: return "Coordinator"
        case .shiftLead: return "Shift Lead"
        }
    }
}
