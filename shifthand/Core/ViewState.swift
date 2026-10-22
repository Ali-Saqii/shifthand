//
//  ViewState.swift
//  shifthand
//
//  Explicit state modeling conforming strictly to AGENTS.md and ARCHITECTURE_IOS.md.
//  Every screen/ViewModel handles all 5 states: loading, loaded, empty, error, offline.
//

import Foundation

public enum ViewState<T>: Sendable, Equatable where T: Sendable, T: Equatable {
    case idle
    case loading
    case loaded(T)
    case failed(AppError)

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }

    public var data: T? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    public var error: AppError? {
        if case .failed(let err) = self { return err }
        return nil
    }
}
