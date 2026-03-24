//
//  RequestBuilder.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 07.03.2026.
//

import Foundation

/// Builds a concrete `URLRequest` from any `Endpoint`.
///
/// Stateless and side-effect free — safe to call from any thread/task.
public struct RequestBuilder: Sendable {

    private let baseURL: String
    private let timeoutInterval: TimeInterval

    public init(
        baseURL: String = Constants.baseURL,
        timeoutInterval: TimeInterval = Constants.defaultTimeoutInterval
    ) {
        self.baseURL = baseURL
        self.timeoutInterval = timeoutInterval
    }

    /// Construct a fully-formed `URLRequest` from the given endpoint.
    /// - Throws: `APIError.invalidURL` if URL composition fails.
    public func build(from endpoint: Endpoint) throws -> URLRequest {
        // 1. Compose base + path
        guard var components = URLComponents(string: baseURL + endpoint.path) else {
            throw APIError.invalidURL(baseURL + endpoint.path)
        }

        // 2. Attach query items (strip nils)
        if let queryItems = endpoint.queryItems {
            let items = queryItems.compactMap { key, value -> URLQueryItem? in
                guard let value else { return nil }
                return URLQueryItem(name: key, value: value)
            }
            if !items.isEmpty {
                components.queryItems = items
            }
        }

        // 3. Final URL
        guard let url = components.url else {
            throw APIError.invalidURL(components.string ?? "unknown")
        }

        // 4. Build request
        var request = URLRequest(url: url, timeoutInterval: timeoutInterval)
        request.httpMethod = endpoint.method.rawValue

        // 5. Default headers
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        if let body = endpoint.body {
            request.httpBody = body
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }

        // 6. Endpoint-specific headers (override defaults if needed)
        endpoint.headers?.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        return request
    }
}
