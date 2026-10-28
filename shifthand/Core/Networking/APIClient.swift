//
//  APIClient.swift
//  shifthand
//
//  Actor handling all network transport, request serialization, and error mapping.
//  Thread-safe and concurrency-safe by design.
//

import Foundation

// MARK: - Generic Data Envelope

public nonisolated struct DataEnvelope<T: Decodable>: Decodable {
    public let data: T
    public let meta: [String: AnyDecodable]?

    public init(data: T, meta: [String: AnyDecodable]? = nil) {
        self.data = data
        self.meta = meta
    }
}

// MARK: - AnyDecodable Helper for Dynamic Metadata

public nonisolated struct AnyDecodable: Decodable, @unchecked Sendable {
    public let value: Any

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let intVal = try? container.decode(Int.self) {
            value = intVal
        } else if let doubleVal = try? container.decode(Double.self) {
            value = doubleVal
        } else if let stringVal = try? container.decode(String.self) {
            value = stringVal
        } else if let boolVal = try? container.decode(Bool.self) {
            value = boolVal
        } else {
            value = ""
        }
    }
}

// MARK: - APIClient Actor

public actor APIClient {
    public let baseURL: URL
    private let urlSession: URLSession
    private let decoder: JSONDecoder

    public init(baseURL: URL = Config.apiBaseURL, session: URLSession = .shared) {
        self.baseURL = baseURL
        self.urlSession = session
        let dec = JSONDecoder()
        dec.dateDecodingStrategy = .iso8601
        self.decoder = dec
    }

    /// Sends an endpoint request, automatically unwrapping { "data": T } if present.
    public func send<T: Decodable>(
        _ endpoint: Endpoint,
        token: String? = nil,
        orgId: String? = nil
    ) async throws -> T {
        let request = try endpoint.urlRequest(baseURL: baseURL, token: token, orgId: orgId)
        let (data, response) = try await performData(for: request)
        try handleHTTPStatus(response: response, data: data)

        // Try decoding as wrapped DataEnvelope<T> first
        if let envelope = try? decoder.decode(DataEnvelope<T>.self, from: data) {
            return envelope.data
        }

        // Fall back to direct T decoding
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw AppError.decoding("Failed to decode \(T.self): \(error.localizedDescription)")
        }
    }

    /// Sends an endpoint request where no response body is expected (e.g. 204 No Content).
    public func sendVoid(
        _ endpoint: Endpoint,
        token: String? = nil,
        orgId: String? = nil
    ) async throws {
        let request = try endpoint.urlRequest(baseURL: baseURL, token: token, orgId: orgId)
        let (data, response) = try await performData(for: request)
        try handleHTTPStatus(response: response, data: data)
    }

    // MARK: - Private Helpers

    private func performData(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await urlSession.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError.network("Received non-HTTP response from server")
            }
            return (data, httpResponse)
        } catch let appError as AppError {
            throw appError
        } catch let urlError as URLError {
            throw AppError.network(urlError.localizedDescription)
        } catch {
            throw AppError.network(error.localizedDescription)
        }
    }

    private func handleHTTPStatus(response: HTTPURLResponse, data: Data) throws {
        let statusCode = response.statusCode

        // 2xx Success
        if (200...299).contains(statusCode) {
            return
        }

        // 401 Unauthorized
        if statusCode == 401 {
            throw AppError.unauthorized
        }

        // Try decoding standard server error envelope
        if let serverError = try? decoder.decode(ServerErrorEnvelope.self, from: data) {
            let detail = serverError.error
            let serverCode = ServerErrorCode(rawValue: detail.code)

            // Special handling for 409 ALREADY_CHECKED_IN
            if statusCode == 409 && serverCode == .alreadyCheckedIn {
                let checkedInTime = detail.details?["checkedInAt"]
                throw AppError.alreadyCheckedIn(checkedInAt: checkedInTime, message: detail.message)
            }

            throw AppError.server(
                code: serverCode,
                rawCode: detail.code,
                message: detail.message,
                requestId: detail.requestId
            )
        }

        // Generic HTTP error fallbacks
        if statusCode == 404 {
            throw AppError.notFound
        }

        let rawString = String(data: data, encoding: .utf8) ?? "HTTP \(statusCode)"
        throw AppError.unknown("Server error (HTTP \(statusCode)): \(rawString)")
    }
}
