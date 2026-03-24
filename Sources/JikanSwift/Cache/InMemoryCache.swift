//
//  InMemoryCache.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 20.03.2026.
//

import Foundation

/// Simple thread-safe in-memory cache backed by `NSCache`.
///
/// Intended as the default / fallback cache. Replace with a
/// persistent implementation (SQLite, file-system) for production needs.
public final class InMemoryCache: ResponseCaching, @unchecked Sendable {

    private let storage = NSCache<NSString, CacheEntry>()

    /// Time-to-live for each entry (seconds). `0` = never expires.
    private let ttl: TimeInterval

    public init(countLimit: Int = 200, ttl: TimeInterval = 300) {
        self.ttl = ttl
        storage.countLimit = countLimit
    }

    // MARK: – ResponseCaching

    public func cachedResponse(for key: String) async -> Data? {
        guard let entry = storage.object(forKey: key as NSString) else {
            return nil
        }
        if ttl > 0, Date().timeIntervalSince(entry.createdAt) > ttl {
            storage.removeObject(forKey: key as NSString)
            return nil
        }
        return entry.data
    }

    public func store(_ data: Data, for key: String) async {
        let entry = CacheEntry(data: data)
        storage.setObject(entry, forKey: key as NSString)
    }

    public func remove(for key: String) async {
        storage.removeObject(forKey: key as NSString)
    }

    public func removeAll() async {
        storage.removeAllObjects()
    }
}

// MARK: – Internal wrapper (NSCache requires class objects)

private final class CacheEntry: NSObject {
    let data: Data
    let createdAt: Date

    init(data: Data, createdAt: Date = .init()) {
        self.data = data
        self.createdAt = createdAt
    }
}

