//
//  Constants.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 10.03.2026.
//

import Foundation

/// Centralised constants for JikanSwift.
public enum Constants {
    /// Base URL for Jikan API v4.
    public static let baseURL = "https://api.jikan.moe/v4"

    /// Default timeout interval (seconds) for every request.
    public static let defaultTimeoutInterval: TimeInterval = 30

    /// Jikan enforces a rate-limit of ~3 req/s for the public tier.
    /// This value is exposed so a future rate-limiter can reference it.
    public static let rateLimitPerSecond: Int = 3

    /// Default page size when the caller does not specify one.
    public static let defaultPageSize: Int = 25
}

