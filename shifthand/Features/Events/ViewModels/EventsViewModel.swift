//
//  EventsViewModel.swift
//  shifthand
//
//  ViewModel managing Event list state, segmented filter, and network operations.
//  Conforms strictly to AGENTS.md ViewState pattern.
//

import SwiftUI
import Observation

@Observable
@MainActor
public final class EventsViewModel {
    public enum EventFilter: String, CaseIterable, Identifiable {
        case upcoming = "Upcoming"
        case drafts = "Drafts"
        case past = "Past"
        public var id: String { rawValue }

        public var queryParam: String {
            switch self {
            case .upcoming: return "upcoming"
            case .drafts: return "drafts"
            case .past: return "past"
            }
        }
    }

    public var selectedFilter: EventFilter = .upcoming {
        didSet {
            Task {
                await loadEvents(isRefresh: false)
            }
        }
    }

    public var state: ViewState<[Event]> = .idle
    public var errorMessage: String? = nil

    private let eventsRepository: EventsRepositoryProtocol
    private let appSession: AppSession

    public init(
        appSession: AppSession,
        eventsRepository: EventsRepositoryProtocol
    ) {
        self.appSession = appSession
        self.eventsRepository = eventsRepository
    }

    public convenience init(appSession: AppSession) {
        self.init(appSession: appSession, eventsRepository: MockEventsRepository())
    }

    public var activeOrgId: String {
        return appSession.activeMembership?.organisationId ?? ""
    }

    public func loadEvents(isRefresh: Bool = false) async {
        guard !activeOrgId.isEmpty else {
            state = .failed(.unknown("No active organisation selected."))
            return
        }

        if !isRefresh {
            state = .loading
        }
        errorMessage = nil

        do {
            let result = try await eventsRepository.getEvents(
                status: selectedFilter.queryParam,
                cursor: nil,
                orgId: activeOrgId
            )
            state = .loaded(result.events)
        } catch let appError as AppError {
            state = .failed(appError)
            errorMessage = appError.errorDescription
        } catch {
            let err = AppError.unknown(error.localizedDescription)
            state = .failed(err)
            errorMessage = err.errorDescription
        }
    }
}
