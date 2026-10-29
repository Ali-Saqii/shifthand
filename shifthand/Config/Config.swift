//
//  Config.swift
//  shifthand
//
//  Reads runtime environment configuration from .xcconfig via Bundle.main.
//  No hard-coded base URLs.
//

import Foundation

public enum Config {
    nonisolated private static let defaultAPIBaseURL = "http://localhost:3000/api/v1"
    nonisolated private static let defaultPublicBaseURL = "http://localhost:3000"

    /// The base URL for authenticated and staff REST API calls.
    nonisolated public static var apiBaseURL: URL {
        if let urlString = Bundle.main.infoDictionary?["API_BASE_URL"] as? String,
           let url = URL(string: urlString),
           !urlString.isEmpty {
            return url
        }
        return URL(string: defaultAPIBaseURL)!
    }

    /// The base public web URL used for public event link generation.
    nonisolated public static var publicBaseURL: URL {
        if let urlString = Bundle.main.infoDictionary?["PUBLIC_BASE_URL"] as? String,
           let url = URL(string: urlString),
           !urlString.isEmpty {
            return url
        }
        return URL(string: defaultPublicBaseURL)!
    }
}
