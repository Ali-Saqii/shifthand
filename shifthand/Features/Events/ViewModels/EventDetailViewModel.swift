//
//  EventDetailViewModel.swift
//  shifthand
//
//  ViewModel for Event Detail screen (Screen #3).
//  Manages shift lists, publishing, cancellation, and public sharing.
//  Conforms strictly to AGENTS.md ViewState pattern.
//

import SwiftUI
import Observation

@Observable
@MainActor
public final class EventDetailViewModel {
    public let eventId: String
    public var state: ViewState<EventDetail> = .idle
    public var errorMessage: String? = nil
    public var isPublishing: Bool = false
    public var isCancelling: Bool = false

    private let eventsRepository: EventsRepositoryProtocol
    private let appSession: AppSession

    public init(
        eventId: String,
        appSession: AppSession,
        eventsRepository: EventsRepositoryProtocol
    ) {
        self.eventId = eventId
        self.appSession = appSession
        self.eventsRepository = eventsRepository
    }

    public convenience init(
        eventId: String,
        appSession: AppSession
    ) {
        self.init(
            eventId: eventId,
            appSession: appSession,
            eventsRepository: MockEventsRepository()
        )
    }

    public var activeOrgId: String {
        return appSession.activeMembership?.organisationId ?? ""
    }

    public func loadDetail(isRefresh: Bool = false) async {
        guard !activeOrgId.isEmpty else {
            state = .failed(.unknown("No active organisation selected."))
            return
        }

        if !isRefresh {
            state = .loading
        }
        errorMessage = nil

        do {
            let detail = try await eventsRepository.getEventDetail(id: eventId, orgId: activeOrgId)
            state = .loaded(detail)
        } catch let appError as AppError {
            state = .failed(appError)
            errorMessage = appError.errorDescription
        } catch {
            let err = AppError.unknown(error.localizedDescription)
            state = .failed(err)
            errorMessage = err.errorDescription
        }
    }

    public func publishEvent() async {
        guard !activeOrgId.isEmpty else { return }

        isPublishing = true
        errorMessage = nil

        do {
            _ = try await eventsRepository.publishEvent(id: eventId, orgId: activeOrgId)
            await loadDetail(isRefresh: true)
            isPublishing = false
        } catch let appError as AppError {
            isPublishing = false
            errorMessage = appError.errorDescription
        } catch {
            isPublishing = false
            errorMessage = error.localizedDescription
        }
    }

    public func cancelEvent() async {
        guard !activeOrgId.isEmpty else { return }

        isCancelling = true
        errorMessage = nil

        do {
            _ = try await eventsRepository.cancelEvent(id: eventId, orgId: activeOrgId)
            await loadDetail(isRefresh: true)
            isCancelling = false
        } catch let appError as AppError {
            isCancelling = false
            errorMessage = appError.errorDescription
        } catch {
            isCancelling = false
            errorMessage = error.localizedDescription
        }
    }
}
