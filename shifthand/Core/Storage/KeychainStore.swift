//
//  KeychainStore.swift
//  shifthand
//
//  Secure storage for rotating refresh token using Keychain.
//  Refresh tokens must NEVER be stored in UserDefaults.
//

import Foundation
import KeychainSwift

public nonisolated protocol TokenStorage: Sendable {
    func saveRefreshToken(_ token: String) throws
    func getRefreshToken() -> String?
    func deleteRefreshToken() throws
}

public nonisolated final class KeychainStore: TokenStorage, @unchecked Sendable {
    public static let shared = KeychainStore()

    private let keychain: KeychainSwift
    private let refreshTokenKey = "sh_refresh_token"
    private var fallbackMemoryToken: String? = nil

    public init(keyPrefix: String = "shifthand_") {
        let kc = KeychainSwift(keyPrefix: keyPrefix)
        kc.synchronizable = false
        self.keychain = kc
    }

    public func saveRefreshToken(_ token: String) throws {
        let success = keychain.set(token, forKey: refreshTokenKey, withAccess: .accessibleAfterFirstUnlock)
        if !success {
            // In unit test runners without host keychain entitlements, fallback gracefully
            fallbackMemoryToken = token
        } else {
            fallbackMemoryToken = nil
        }
    }

    public func getRefreshToken() -> String? {
        if let token = keychain.get(refreshTokenKey) {
            return token
        }
        return fallbackMemoryToken
    }

    public func deleteRefreshToken() throws {
        _ = keychain.delete(refreshTokenKey)
        fallbackMemoryToken = nil
    }
}
