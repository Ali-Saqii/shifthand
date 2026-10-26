//
//  Endpoint.swift
//  shifthand
//
//  Describes API requests: path, HTTP method, headers, query items, body, and idempotency key.
//

import Foundation

public nonisolated enum HTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case patch = "PATCH"
    case delete = "DELETE"
    case put = "PUT"
}

public nonisolated struct Endpoint: Sendable {
    public let path: String
    public let method: HTTPMethod
    public let queryItems: [URLQueryItem]?
    public let headers: [String: String]
    public let body: Data?
    public let idempotencyKey: String?

    public init(
        path: String,
        method: HTTPMethod = .get,
        queryItems: [URLQueryItem]? = nil,
        headers: [String: String] = [:],
        body: Data? = nil,
        idempotencyKey: String? = nil
    ) {
        self.path = path
        self.method = method
        self.queryItems = queryItems
        self.headers = headers
        self.body = body
        self.idempotencyKey = idempotencyKey
    }

    /// Helper to create JSON-bodied endpoint
    public static func json<T: Encodable>(
        path: String,
        method: HTTPMethod,
        body: T,
        queryItems: [URLQueryItem]? = nil,
        idempotencyKey: String? = nil,
        additionalHeaders: [String: String] = [:]
    ) throws -> Endpoint {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(body)
        var headers = additionalHeaders
        headers["Content-Type"] = "application/json"
        headers["Accept"] = "application/json"
        return Endpoint(
            path: path,
            method: method,
            queryItems: queryItems,
            headers: headers,
            body: data,
            idempotencyKey: idempotencyKey
        )
    }

    /// Construct a URLRequest with authorization header, organisation header, and baseURL
    public func urlRequest(baseURL: URL, token: String? = nil, orgId: String? = nil) throws -> URLRequest {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            throw AppError.network("Malformed base URL")
        }

        // Normalize path joining
        let fullPath: String
        let basePath = components.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let subPath = path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if basePath.isEmpty {
            fullPath = "/" + subPath
        } else {
            fullPath = "/" + basePath + "/" + subPath
        }
        components.path = fullPath

        if let queryItems = queryItems, !queryItems.isEmpty {
            components.queryItems = queryItems
        }

        guard let url = components.url else {
            throw AppError.network("Malformed request URL for path: \(path)")
        }

        var request = URLRequest(url: url)
        request.httpMethod = method.rawValue
        request.httpBody = body

        // Standard headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if body != nil {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // Authorization header
        if let token = token, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        // Organisation-scoped header (X-Org-Id)
        if let orgId = orgId, !orgId.isEmpty {
            request.setValue(orgId, forHTTPHeaderField: "X-Org-Id")
        }

        // Idempotency-Key header if provided
        if let idempotencyKey = idempotencyKey {
            request.setValue(idempotencyKey, forHTTPHeaderField: "Idempotency-Key")
        }

        // Custom headers
        for (header, value) in headers {
            request.setValue(value, forHTTPHeaderField: header)
        }

        return request
    }
}
