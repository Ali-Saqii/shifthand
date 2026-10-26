//
//  AuthRepository.swift
//  shifthand
//
//  Data layer protocol, Mock, and Live implementations for staff authentication and organisations.
//

import Foundation

// MARK: - Protocol

@MainActor
public protocol AuthRepositoryProtocol: Sendable {
    func login(email: String, password: String) async throws -> (user: User, memberships: [Membership])
    func register(name: String, email: String, password: String) async throws -> (user: User, memberships: [Membership])
    func getMe() async throws -> (user: User, memberships: [Membership])
    func logout() async throws
    func deleteAccount() async throws
    func createOrganisation(name: String, timezone: String) async throws -> Organisation
    func joinOrganisation(code: String) async throws -> Membership
}

// MARK: - Live Repository

@MainActor
public final class LiveAuthRepository: AuthRepositoryProtocol {
    private let apiClient: APIClient
    private let authSession: AuthSession

    public init(apiClient: APIClient = APIClient(), authSession: AuthSession = .shared) {
        self.apiClient = apiClient
        self.authSession = authSession
    }

    public func login(email: String, password: String) async throws -> (user: User, memberships: [Membership]) {
        nonisolated struct LoginRequest: Encodable, Sendable {
            let email: String
            let password: String
        }

        nonisolated struct LoginResponse: Decodable, Sendable {
            let token: String
            let refreshToken: String?
            let user: User
        }

        let endpoint = try Endpoint.json(
            path: "/auth/login",
            method: .post,
            body: LoginRequest(email: email, password: password)
        )

        let response: LoginResponse = try await apiClient.send(endpoint)
        if let refresh = response.refreshToken {
            try await authSession.setTokens(accessToken: response.token, refreshToken: refresh)
        }

        // Fetch memberships from /me
        let meData = try await getMe()
        return (user: meData.user, memberships: meData.memberships)
    }

    public func register(name: String, email: String, password: String) async throws -> (user: User, memberships: [Membership]) {
        nonisolated struct RegisterRequest: Encodable, Sendable {
            let name: String
            let email: String
            let password: String
        }

        nonisolated struct RegisterResponse: Decodable, Sendable {
            let token: String
            let refreshToken: String?
            let user: User
        }

        let endpoint = try Endpoint.json(
            path: "/auth/register",
            method: .post,
            body: RegisterRequest(name: name, email: email, password: password)
        )

        let response: RegisterResponse = try await apiClient.send(endpoint)
        if let refresh = response.refreshToken {
            try await authSession.setTokens(accessToken: response.token, refreshToken: refresh)
        }

        // Newly registered user has 0 memberships
        return (user: response.user, memberships: [])
    }

    public func getMe() async throws -> (user: User, memberships: [Membership]) {
        nonisolated struct MeResponse: Decodable, Sendable {
            let user: User
            let memberships: [Membership]
        }

        let token = await authSession.getAccessToken()
        let endpoint = Endpoint(path: "/me", method: .get)
        let response: MeResponse = try await apiClient.send(endpoint, token: token)
        return (user: response.user, memberships: response.memberships)
    }

    public func logout() async throws {
        let token = await authSession.getAccessToken()
        let endpoint = Endpoint(path: "/auth/logout", method: .post)
        _ = try? await apiClient.sendVoid(endpoint, token: token)
        try await authSession.clearSession()
    }

    public func deleteAccount() async throws {
        let token = await authSession.getAccessToken()
        let endpoint = Endpoint(path: "/me", method: .delete)
        try await apiClient.sendVoid(endpoint, token: token)
        try await authSession.clearSession()
    }

    public func createOrganisation(name: String, timezone: String) async throws -> Organisation {
        nonisolated struct CreateOrgRequest: Encodable, Sendable {
            let name: String
            let timezone: String
        }

        nonisolated struct CreateOrgResponse: Decodable, Sendable {
            let id: String
            let name: String
            let timezone: String
            let role: StaffRole
        }

        let token = await authSession.getAccessToken()
        let endpoint = try Endpoint.json(
            path: "/organisations",
            method: .post,
            body: CreateOrgRequest(name: name, timezone: timezone)
        )

        let response: CreateOrgResponse = try await apiClient.send(endpoint, token: token)
        return Organisation(id: response.id, name: response.name, timezone: response.timezone, role: response.role)
    }

    public func joinOrganisation(code: String) async throws -> Membership {
        nonisolated struct JoinRequest: Encodable, Sendable {
            let code: String
        }

        nonisolated struct JoinResponse: Decodable, Sendable {
            let organisationId: String
            let organisationName: String
            let role: StaffRole
        }

        let token = await authSession.getAccessToken()
        let endpoint = try Endpoint.json(
            path: "/organisations/join",
            method: .post,
            body: JoinRequest(code: code)
        )

        let response: JoinResponse = try await apiClient.send(endpoint, token: token)
        return Membership(organisationId: response.organisationId, organisationName: response.organisationName, role: response.role)
    }
}

// MARK: - Mock Repository

@MainActor
public final class MockAuthRepository: AuthRepositoryProtocol {
    public var simulatedUser: User = User(id: "usr_mock_1", name: "Sarah Ahmed", email: "sarah@example.com")
    public var simulatedMemberships: [Membership] = []
    public var shouldThrowError: AppError? = nil

    public init(initialMemberships: [Membership] = []) {
        self.simulatedMemberships = initialMemberships
    }

    public func login(email: String, password: String) async throws -> (user: User, memberships: [Membership]) {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        if email == "bad@example.com" {
            throw AppError.server(code: .invalidCredentials, rawCode: "INVALID_CREDENTIALS", message: "Invalid email or password", requestId: nil)
        }

        return (user: simulatedUser, memberships: simulatedMemberships)
    }

    public func register(name: String, email: String, password: String) async throws -> (user: User, memberships: [Membership]) {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        simulatedUser = User(id: UUID().uuidString, name: name, email: email)
        simulatedMemberships = []
        return (user: simulatedUser, memberships: [])
    }

    public func getMe() async throws -> (user: User, memberships: [Membership]) {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }
        return (user: simulatedUser, memberships: simulatedMemberships)
    }

    public func logout() async throws {
        try await simulateLatency()
    }

    public func deleteAccount() async throws {
        try await simulateLatency()
        simulatedMemberships = []
    }

    public func createOrganisation(name: String, timezone: String) async throws -> Organisation {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        let newOrg = Organisation(id: UUID().uuidString, name: name, timezone: timezone, role: .owner)
        let membership = Membership(organisationId: newOrg.id, organisationName: newOrg.name, role: .owner)
        simulatedMemberships.append(membership)
        return newOrg
    }

    public func joinOrganisation(code: String) async throws -> Membership {
        try await simulateLatency()
        if let error = shouldThrowError { throw error }

        let cleanCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        if cleanCode == "EXPIRED1" {
            throw AppError.server(code: .unknown, rawCode: "INVITE_EXPIRED", message: "This invite code has expired", requestId: nil)
        }
        if cleanCode.count != 8 {
            throw AppError.server(code: .validationFailed, rawCode: "INVALID_CODE", message: "Invite code must be 8 characters", requestId: nil)
        }

        let newMembership = Membership(organisationId: UUID().uuidString, organisationName: "Joined Org (\(cleanCode))", role: .coordinator)
        simulatedMemberships.append(newMembership)
        return newMembership
    }

    private func simulateLatency() async throws {
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2s
    }
}
