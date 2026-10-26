//
//  OnboardingViewModel.swift
//  shifthand
//
//  State and actions for staff onboarding (0 memberships):
//  Create organisation (with timezone) and join with 8-character invite code.
//

import SwiftUI
import Observation

@Observable
@MainActor
public final class OnboardingViewModel {
    // Create Org fields
    public var orgName: String = ""
    public var selectedTimezone: String = TimeZone.current.identifier
    public var isCreating: Bool = false
    public var createErrorMessage: String? = nil

    // Join Org fields
    public var inviteCode: String = ""
    public var isJoining: Bool = false
    public var joinErrorMessage: String? = nil

    private let appSession: AppSession

    public init(appSession: AppSession) {
        self.appSession = appSession
    }

    public var isCreateValid: Bool {
        return !orgName.trimmingCharacters(in: .whitespaces).isEmpty &&
               !selectedTimezone.isEmpty
    }

    public var isJoinValid: Bool {
        let clean = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines)
        return clean.count == 8
    }

    public func createOrganisation() async -> Bool {
        guard isCreateValid else {
            createErrorMessage = "Organisation name is required."
            return false
        }

        isCreating = true
        createErrorMessage = nil
        defer { isCreating = false }

        do {
            try await appSession.createOrganisation(
                name: orgName.trimmingCharacters(in: .whitespaces),
                timezone: selectedTimezone
            )
            return true
        } catch let appError as AppError {
            createErrorMessage = appError.errorDescription
            return false
        } catch {
            createErrorMessage = error.localizedDescription
            return false
        }
    }

    public func joinOrganisation() async -> Bool {
        let clean = inviteCode.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard clean.count == 8 else {
            joinErrorMessage = "Invite code must be 8 characters."
            return false
        }

        isJoining = true
        joinErrorMessage = nil
        defer { isJoining = false }

        do {
            try await appSession.joinOrganisation(code: clean)
            return true
        } catch let appError as AppError {
            joinErrorMessage = appError.errorDescription
            return false
        } catch {
            joinErrorMessage = error.localizedDescription
            return false
        }
    }

    public func signOut() {
        appSession.logout()
    }
}
