//
//  AuthSession.swift
//  shifthand
//
//  Actor managing in-memory JWT access token, Keychain refresh token,
//  and single in-flight refresh task for concurrent 401 handling.
//

import Foundation

public actor AuthSession {
    public static let shared = AuthSession()

    private var accessToken: String?
    private let tokenStorage: TokenStorage
    private var refreshTask: Task<String, Error>?

    public init(tokenStorage: TokenStorage = KeychainStore.shared) {
        self.tokenStorage = tokenStorage
    }

    /// Read the current in-memory access token.
    public func getAccessToken() -> String? {
        return accessToken
    }

    /// Read the stored refresh token from Keychain.
    public func getRefreshToken() -> String? {
        return tokenStorage.getRefreshToken()
    }

    /// Set newly acquired tokens after login, register, or refresh.
    public func setTokens(accessToken: String, refreshToken: String) throws {
        self.accessToken = accessToken
        try tokenStorage.saveRefreshToken(refreshToken)
    }

    /// Clear all authentication tokens on logout or session invalidation.
    public func clearSession() throws {
        self.accessToken = nil
        try tokenStorage.deleteRefreshToken()
    }

    /// Check if user has an active session token.
    public var isAuthenticated: Bool {
        return accessToken != nil || tokenStorage.getRefreshToken() != nil
    }

    /// Execute single in-flight token refresh.
    /// Concurrent callers suspend and await the exact same refresh task.
    public func refresh(using client: APIClient) async throws -> String {
        // If a refresh is already in flight, await its result
        if let existingTask = refreshTask {
            return try await existingTask.value
        }

        guard let refreshToken = tokenStorage.getRefreshToken(), !refreshToken.isEmpty else {
            try? clearSession()
            throw AppError.unauthorized
        }

        let task = Task<String, Error> { () -> String in
            defer { self.clearRefreshTask() }

            struct RefreshRequest: Encodable {
                let refreshToken: String
            }

            struct RefreshResponse: Decodable {
                let token: String
                let refreshToken: String?
            }

            let endpoint = try Endpoint.json(
                path: "/auth/refresh",
                method: .post,
                body: RefreshRequest(refreshToken: refreshToken)
            )

            do {
                let response: RefreshResponse = try await client.send(endpoint)
                self.accessToken = response.token
                if let newRefresh = response.refreshToken {
                    try? self.tokenStorage.saveRefreshToken(newRefresh)
                }
                return response.token
            } catch {
                try? self.clearSession()
                throw AppError.unauthorized
            }
        }

        self.refreshTask = task
        return try await task.value
    }

    private func clearRefreshTask() {
        self.refreshTask = nil
    }
}
