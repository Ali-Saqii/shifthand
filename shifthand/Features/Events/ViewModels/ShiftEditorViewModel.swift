//
//  ShiftEditorViewModel.swift
//  shifthand
//
//  ViewModel for Shift Editor (Screen #4).
//  Handles validation, capacity restrictions, change warnings, and lead assignments.
//  Conforms strictly to SHIFTHAND_MVP_SPEC_v2.md Section 5.4.
//

import SwiftUI
import Observation

@Observable
@MainActor
public final class ShiftEditorViewModel {
    public let eventId: String
    public let existingShift: Shift?
    public var roleLabel: String = ""
    public var startsAtUtc: Date
    public var endsAtUtc: Date
    public var capacity: Int = 5
    public var cancelCutoffHours: Int = 24
    public var selectedLeadId: String? = nil
    public var notes: String = ""
    public var confirmChange: Bool = false

    public var availableStaff: [StaffMember] = []
    public var state: ViewState<Shift> = .idle
    public var errorMessage: String? = nil
    public var isDeleting: Bool = false

    private let eventsRepository: EventsRepositoryProtocol
    private let appSession: AppSession

    public init(
        eventId: String,
        existingShift: Shift? = nil,
        eventStartDate: Date,
        appSession: AppSession,
        eventsRepository: EventsRepositoryProtocol
    ) {
        self.eventId = eventId
        self.existingShift = existingShift
        self.appSession = appSession
        self.eventsRepository = eventsRepository

        if let existing = existingShift {
            self.roleLabel = existing.roleLabel
            self.startsAtUtc = existing.startsAtUtc
            self.endsAtUtc = existing.endsAtUtc
            self.capacity = existing.capacity
            self.cancelCutoffHours = existing.cancelCutoffHours
            self.selectedLeadId = existing.leadUserId
            self.notes = existing.notes ?? ""
        } else {
            self.startsAtUtc = eventStartDate
            self.endsAtUtc = Calendar.current.date(byAdding: .hour, value: 4, to: eventStartDate) ?? eventStartDate
        }
    }

    public convenience init(
        eventId: String,
        existingShift: Shift? = nil,
        eventStartDate: Date,
        appSession: AppSession
    ) {
        self.init(
            eventId: eventId,
            existingShift: existingShift,
            eventStartDate: eventStartDate,
            appSession: appSession,
            eventsRepository: MockEventsRepository()
        )
    }

    public var isEditing: Bool {
        return existingShift != nil
    }

    public var isTimeChanged: Bool {
        guard let existing = existingShift else { return false }
        return existing.startsAtUtc != startsAtUtc || existing.endsAtUtc != endsAtUtc
    }

    public var requiresChangeWarning: Bool {
        guard let existing = existingShift else { return false }
        return isTimeChanged && existing.confirmedCount > 0
    }

    public var isDatesValid: Bool {
        return endsAtUtc > startsAtUtc
    }

    public var isCapacityValid: Bool {
        if let existing = existingShift {
            return capacity >= existing.confirmedCount && capacity >= 1
        }
        return capacity >= 1
    }

    public var isFormValid: Bool {
        return !roleLabel.trimmingCharacters(in: .whitespaces).isEmpty &&
               isDatesValid &&
               isCapacityValid
    }

    public func loadStaffMembers() async {
        guard let orgId = appSession.activeMembership?.organisationId else { return }
        do {
            self.availableStaff = try await eventsRepository.getOrgMembers(orgId: orgId)
        } catch {
            // Non-critical: defaults to empty staff list
        }
    }

    public func saveShift() async -> Shift? {
        guard isFormValid else {
            if !isDatesValid {
                errorMessage = "Shift end time must be after the start time."
            } else if !isCapacityValid, let existing = existingShift {
                errorMessage = "Capacity cannot be reduced below current confirmed signups (\(existing.confirmedCount))."
            } else {
                errorMessage = "Please enter a role label."
            }
            return nil
        }

        guard let orgId = appSession.activeMembership?.organisationId else {
            errorMessage = "No active organisation selected."
            return nil
        }

        state = .loading
        errorMessage = nil

        do {
            if let existing = existingShift {
                let updated = try await eventsRepository.updateShift(
                    id: existing.id,
                    roleLabel: roleLabel.trimmingCharacters(in: .whitespaces),
                    startsAtUtc: startsAtUtc,
                    endsAtUtc: endsAtUtc,
                    capacity: capacity,
                    confirmChange: confirmChange,
                    leadUserId: selectedLeadId,
                    notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                    orgId: orgId
                )
                state = .loaded(updated)
                return updated
            } else {
                let created = try await eventsRepository.createShift(
                    eventId: eventId,
                    roleLabel: roleLabel.trimmingCharacters(in: .whitespaces),
                    startsAtUtc: startsAtUtc,
                    endsAtUtc: endsAtUtc,
                    capacity: capacity,
                    cancelCutoffHours: cancelCutoffHours,
                    leadUserId: selectedLeadId,
                    notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
                    orgId: orgId
                )
                state = .loaded(created)
                return created
            }
        } catch let appError as AppError {
            state = .failed(appError)
            errorMessage = appError.errorDescription
            return nil
        } catch {
            let err = AppError.unknown(error.localizedDescription)
            state = .failed(err)
            errorMessage = err.errorDescription
            return nil
        }
    }

    public func deleteShift() async -> Bool {
        guard let shift = existingShift else { return false }
        guard let orgId = appSession.activeMembership?.organisationId else { return false }

        isDeleting = true
        errorMessage = nil

        do {
            try await eventsRepository.deleteShift(id: shift.id, orgId: orgId)
            isDeleting = false
            return true
        } catch let appError as AppError {
            isDeleting = false
            errorMessage = appError.errorDescription
            return false
        } catch {
            isDeleting = false
            errorMessage = error.localizedDescription
            return false
        }
    }
}
