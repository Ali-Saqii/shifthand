//
//  AppSession.swift
//  shifthand
//
//  MainActor observable session holding user profile, organisation memberships,
//  and active role. Drives role-based navigation and authentication routing.
//

import SwiftUI
import Observation

@Observable
@MainActor
public final class AppSession {
    public var currentUser: User?
    public var memberships: [Membership] = []
    public var activeMembership: Membership?
    public var isLoadingSession: Bool = false
    public var sessionError: AppError?

    public let authRepository: AuthRepositoryProtocol

    public init(authRepository: AuthRepositoryProtocol) {
        self.authRepository = authRepository
    }

    public convenience init() {
        self.init(authRepository: MockAuthRepository())
    }

    public var isAuthenticated: Bool {
        return currentUser != nil
    }

    public var membershipCount: Int {
        return memberships.count
    }

    public var activeRole: StaffRole? {
        return activeMembership?.role
    }

    /// Sign in with email and password
    public func login(email: String, password: String) async throws {
        isLoadingSession = true
        sessionError = nil
        defer { isLoadingSession = false }

        do {
            let result = try await authRepository.login(email: email, password: password)
            self.currentUser = result.user
            self.memberships = result.memberships
            self.activeMembership = result.memberships.first
        } catch let err as AppError {
            self.sessionError = err
            throw err
        } catch {
            let generic = AppError.unknown(error.localizedDescription)
            self.sessionError = generic
            throw generic
        }
    }

    /// Register a new staff user account
    public func register(name: String, email: String, password: String) async throws {
        isLoadingSession = true
        sessionError = nil
        defer { isLoadingSession = false }

        do {
            let result = try await authRepository.register(name: name, email: email, password: password)
            self.currentUser = result.user
            self.memberships = result.memberships
            self.activeMembership = nil
        } catch let err as AppError {
            self.sessionError = err
            throw err
        } catch {
            let generic = AppError.unknown(error.localizedDescription)
            self.sessionError = generic
            throw generic
        }
    }

    /// Refresh profile and memberships from GET /me
    public func refreshMe() async {
        do {
            let result = try await authRepository.getMe()
            self.currentUser = result.user
            self.memberships = result.memberships

            // Retain active membership if it still exists; otherwise default to first
            if let active = activeMembership,
               let updated = result.memberships.first(where: { $0.organisationId == active.organisationId }) {
                self.activeMembership = updated
            } else {
                self.activeMembership = result.memberships.first
            }
        } catch {
            // If session expired or invalid, reset
            if case .unauthorized = (error as? AppError) {
                logout()
            }
        }
    }

    /// Create an organisation as Owner (Day 3)
    public func createOrganisation(name: String, timezone: String) async throws {
        isLoadingSession = true
        defer { isLoadingSession = false }

        let org = try await authRepository.createOrganisation(name: name, timezone: timezone)
        let newMembership = Membership(organisationId: org.id, organisationName: org.name, role: .owner)
        self.memberships.append(newMembership)
        self.activeMembership = newMembership
    }

    /// Join an organisation with an 8-character invite code (Day 3)
    public func joinOrganisation(code: String) async throws {
        isLoadingSession = true
        defer { isLoadingSession = false }

        let membership = try await authRepository.joinOrganisation(code: code)
        self.memberships.append(membership)
        self.activeMembership = membership
    }

    /// Select an active organisation (Day 4 Org Switcher)
    public func setActiveOrganisation(_ membership: Membership) {
        self.activeMembership = membership
    }

    /// Sign out and clear active session
    public func logout() {
        Task {
            try? await authRepository.logout()
        }
        self.currentUser = nil
        self.memberships = []
        self.activeMembership = nil
        self.sessionError = nil
    }

    /// Delete staff account (App Store requirement)
    public func deleteAccount() async throws {
        try await authRepository.deleteAccount()
        self.currentUser = nil
        self.memberships = []
        self.activeMembership = nil
        self.sessionError = nil
    }
}
