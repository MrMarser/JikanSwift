//
//  CachePolicy.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 20.03.2026.
//

import Foundation

/// Policy that controls whether a request may be served from cache.
public enum CachePolicy: Sendable {
    /// Always hit the network; ignore any cached value.
    case ignoreCache

    /// Return cache if available AND not expired; otherwise fetch.
    case returnCacheElseLoad

    /// Return cache if available (even if stale); refresh in background.
    case returnCacheAndRefresh
}

/// Abstract caching contract.
///
/// Implement this protocol to plug in any storage backend
/// (in-memory, `URLCache`, Core Data, SQLite, file-system, etc.).
/// The ``JikanClient`` accepts an optional `ResponseCaching` instance;
/// when it is `nil`, all requests go straight to the network.
public protocol ResponseCaching: Sendable {

    /// Retrieve previously stored raw data for a cache key.
    func cachedResponse(for key: String) async -> Data?

    /// Store raw response data under the given key.
    func store(_ data: Data, for key: String) async

    /// Explicitly remove a single entry.
    func remove(for key: String) async

    /// Wipe the entire cache.
    func removeAll() async
}

