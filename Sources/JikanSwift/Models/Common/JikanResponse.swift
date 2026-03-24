//
//  JikanResponse.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 10.03.2026.
//

import Foundation

/// Generic top-level envelope returned by Jikan for **collection** endpoints.
///
/// Single-resource endpoints return `JikanSingleResponse<T>` instead.
public struct JikanResponse<T: Decodable & Sendable>: Decodable, Sendable {
    public let data: [T]
    public let pagination: Pagination?
}

/// Top-level envelope for endpoints that return a **single** resource
/// (e.g. `/anime/{id}`).
public struct JikanSingleResponse<T: Decodable & Sendable>: Decodable, Sendable {
    public let data: T
}

// MARK: – Pagination metadata

public struct Pagination: Decodable, Sendable, Equatable {
    public let lastVisiblePage: Int
    public let hasNextPage: Bool
    public let currentPage: Int?
    public let items: PaginationItems?

    private enum CodingKeys: String, CodingKey {
        case lastVisiblePage = "last_visible_page"
        case hasNextPage     = "has_next_page"
        case currentPage     = "current_page"
        case items
    }
}

public struct PaginationItems: Decodable, Sendable, Equatable {
    public let count: Int
    public let total: Int
    public let perPage: Int

    private enum CodingKeys: String, CodingKey {
        case count
        case total
        case perPage = "per_page"
    }
}

