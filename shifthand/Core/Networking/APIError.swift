//
//  APIError.swift
//  shifthand
//
//  Typed errors mapped from backend error envelope and transport layer.
//  The app switches on error.code, never on message text.
//

import Foundation

// MARK: - Known Server Error Codes

public nonisolated enum ServerErrorCode: String, Sendable, Equatable {
    case shiftFull = "SHIFT_FULL"
    case shiftOverlap = "SHIFT_OVERLAP"
    case alreadyCheckedIn = "ALREADY_CHECKED_IN"
    case notMember = "NOT_MEMBER"
    case validationFailed = "VALIDATION_FAILED"
    case invalidCredentials = "INVALID_CREDENTIALS"
    case emailTaken = "EMAIL_TAKEN"
    case unauthorized = "UNAUTHORIZED"
    case forbidden = "FORBIDDEN"
    case notFound = "NOT_FOUND"
    case refreshInvalid = "REFRESH_INVALID"
    case unknown = "UNKNOWN"

    public init(rawValue: String) {
        switch rawValue.uppercased() {
        case "SHIFT_FULL": self = .shiftFull
        case "SHIFT_OVERLAP": self = .shiftOverlap
        case "ALREADY_CHECKED_IN": self = .alreadyCheckedIn
        case "NOT_MEMBER": self = .notMember
        case "VALIDATION_FAILED": self = .validationFailed
        case "INVALID_CREDENTIALS": self = .invalidCredentials
        case "EMAIL_TAKEN": self = .emailTaken
        case "UNAUTHORIZED": self = .unauthorized
        case "FORBIDDEN": self = .forbidden
        case "NOT_FOUND": self = .notFound
        case "REFRESH_INVALID": self = .refreshInvalid
        default: self = .unknown
        }
    }
}

// MARK: - Server Error Envelope

public nonisolated struct ServerErrorEnvelope: Decodable, Sendable {
    public let error: ServerErrorDetail

    public nonisolated struct ServerErrorDetail: Decodable, Sendable {
        public let code: String
        public let message: String
        public let details: [String: String]?
        public let requestId: String?

        public init(code: String, message: String, details: [String: String]? = nil, requestId: String? = nil) {
            self.code = code
            self.message = message
            self.details = details
            self.requestId = requestId
        }
    }

    public init(error: ServerErrorDetail) {
        self.error = error
    }
}

// MARK: - AppError

public nonisolated enum AppError: Error, LocalizedError, Equatable, Sendable {
    case server(code: ServerErrorCode, rawCode: String, message: String, requestId: String?)
    case alreadyCheckedIn(checkedInAt: String?, message: String)
    case network(String)
    case decoding(String)
    case unauthorized
    case notFound
    case unknown(String)

    public var errorDescription: String? {
        switch self {
        case .server(_, _, let message, _):
            return message
        case .alreadyCheckedIn(let time, let message):
            if let time = time {
                return "Already here since \(time)"
            }
            return message
        case .network(let message):
            return "Network connection error: \(message)"
        case .decoding(let message):
            return "Data formatting error: \(message)"
        case .unauthorized:
            return "Session expired. Please sign in again."
        case .notFound:
            return "Requested resource not found."
        case .unknown(let message):
            return message
        }
    }

    public var isAlreadyCheckedIn: Bool {
        if case .alreadyCheckedIn = self { return true }
        if case .server(.alreadyCheckedIn, _, _, _) = self { return true }
        return false
    }
}
