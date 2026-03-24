//
//  Endpoint.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 07.03.2026.
//

import Foundation

/// A type-safe description of an API route.
///
/// Conforming types declare *what* to call; `RequestBuilder` turns the
/// description into a concrete `URLRequest`.
public protocol Endpoint {

    /// HTTP method for the request.
    var method: HTTPMethod { get }

    /// Path component appended to `Constants.baseURL` (e.g. `"/anime/1"`).
    var path: String { get }

    /// Query-string parameters. `nil` values are stripped automatically.
    var queryItems: [String: String?]? { get }

    /// HTTP headers added on top of the defaults produced by `RequestBuilder`.
    var headers: [String: String]? { get }

    /// Optional HTTP body (JSON-serialisable data).
    var body: Data? { get }

    /// A stable, human-readable key that uniquely identifies this request.
    /// Used by the (future) cache layer.
    var cacheKey: String { get }
}

// MARK: – Sensible defaults

public extension Endpoint {
    var method: HTTPMethod { .get }
    var queryItems: [String: String?]? { nil }
    var headers: [String: String]? { nil }
    var body: Data? { nil }

    /// Default cache key built from method + full path + sorted query items.
    var cacheKey: String {
        var components = "\(method.rawValue):\(path)"
        if let items = queryItems?.compactMapValues({ $0 }),
           !items.isEmpty {
            let sorted = items.sorted { $0.key < $1.key }
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: "&")
            components += "?\(sorted)"
        }
        return components
    }
}

