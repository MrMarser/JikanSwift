//
//  HTTPClient.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 07.03.2026.
//

import Foundation

// MARK: – Abstract transport

/// Minimal contract for executing HTTP requests.
///
/// The protocol exists so tests can inject a mock transport
/// without hitting the real network.
public protocol HTTPClientProtocol: Sendable {
    func execute(_ request: URLRequest) async throws -> (Data, URLResponse)
}

// MARK: – URLSession-based implementation

/// Production transport backed by `URLSession`.
public struct HTTPClient: HTTPClientProtocol {

    private let session: URLSession

    public init(session: URLSession = .shared) {
        self.session = session
    }

    /// Execute the request and return the raw pair.
    ///
    /// Uses `URLSession.data(for:)` which is available from
    /// iOS 15 / macOS 12 (our minimum deployment target).
    public func execute(_ request: URLRequest) async throws -> (Data, URLResponse) {
        do {
            return try await session.data(for: request)
        } catch let urlError as URLError {
            throw APIError.networkFailure(urlError)
        } catch {
            throw APIError.unknown(error.localizedDescription)
        }
    }
}
