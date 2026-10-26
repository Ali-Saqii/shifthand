//
//  CreateEventViewModel.swift
//  shifthand
//
//  ViewModel handling event creation form validation and submission.
//  Conforms to AGENTS.md and SHIFTHAND_MVP_SPEC_v2.md Section 5.3.
//

import SwiftUI
import Observation

@Observable
@MainActor
public final class CreateEventViewModel {
    public var title: String = ""
    public var descriptionText: String = ""
    public var venue: String = ""
    public var startsAt: Date
    public var endsAt: Date
    public var state: ViewState<Event> = .idle
    public var errorMessage: String? = nil

    private let eventsRepository: EventsRepositoryProtocol
    private let appSession: AppSession

    public init(
        appSession: AppSession,
        eventsRepository: EventsRepositoryProtocol
    ) {
        self.appSession = appSession
        self.eventsRepository = eventsRepository

        // Default to tomorrow 09:00 to 17:00
        let calendar = Calendar.current
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        self.startsAt = calendar.date(bySettingHour: 9, minute: 0, second: 0, of: tomorrow) ?? tomorrow
        self.endsAt = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: tomorrow) ?? tomorrow
    }

    public convenience init(appSession: AppSession) {
        self.init(appSession: appSession, eventsRepository: MockEventsRepository())
    }

    public var isDatesValid: Bool {
        return endsAt >= startsAt
    }

    public var isFormValid: Bool {
        return !title.trimmingCharacters(in: .whitespaces).isEmpty &&
               !venue.trimmingCharacters(in: .whitespaces).isEmpty &&
               isDatesValid
    }

    public func createEvent() async -> Event? {
        guard isFormValid else {
            if !isDatesValid {
                errorMessage = "Event end time must be after start time."
            } else {
                errorMessage = "Please enter an event title and venue."
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
            let event = try await eventsRepository.createEvent(
                title: title.trimmingCharacters(in: .whitespaces),
                description: descriptionText.trimmingCharacters(in: .whitespaces).isEmpty ? nil : descriptionText.trimmingCharacters(in: .whitespaces),
                venue: venue.trimmingCharacters(in: .whitespaces),
                startsAt: startsAt,
                endsAt: endsAt,
                orgId: orgId
            )
            state = .loaded(event)
            return event
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
}
