//
//  User.swift
//  shifthand
//
//  Authenticated staff member profile.
//

import Foundation

public nonisolated struct User: Identifiable, Codable, Sendable, Equatable {
    public let id: String
    public let name: String
    public let email: String

    public init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}
