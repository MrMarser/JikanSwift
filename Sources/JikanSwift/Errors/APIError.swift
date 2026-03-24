//
//  APIError.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 07.03.2026.
//

import Foundation

/// All errors that can surface from `JikanClient` operations.
public enum APIError: LocalizedError, Equatable {

    // MARK: – Network layer

    /// The URL built from the endpoint is malformed.
    case invalidURL(String)

    /// A transport-level failure (no connectivity, DNS, TLS, etc.).
    case networkFailure(URLError)

    /// The server returned an unexpected HTTP status code.
    case httpError(statusCode: Int, data: Data?)

    /// Jikan returned HTTP 429 — the caller should back off.
    case rateLimited(retryAfter: TimeInterval?)

    // MARK: – Decoding

    /// The response body could not be decoded into the expected model.
    case decodingFailed(context: String)

    // MARK: – Client

    /// A request was attempted while the client had already been invalidated.
    case clientDeallocated

    /// Catch-all for anything unexpected.
    case unknown(String)

    // MARK: – LocalizedError

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "Invalid URL: \(url)"
        case .networkFailure(let urlError):
            return "Network failure: \(urlError.localizedDescription)"
        case .httpError(let code, _):
            return "HTTP error \(code)"
        case .rateLimited(let retry):
            if let retry {
                return "Rate limited. Retry after \(Int(retry))s."
            }
            return "Rate limited. Please slow down."
        case .decodingFailed(let ctx):
            return "Decoding failed: \(ctx)"
        case .clientDeallocated:
            return "JikanClient has been deallocated."
        case .unknown(let msg):
            return msg
        }
    }

    // MARK: – Equatable (Data is not Equatable by default)

    public static func == (lhs: APIError, rhs: APIError) -> Bool {
        switch (lhs, rhs) {
        case (.invalidURL(let a), .invalidURL(let b)):
            return a == b
        case (.networkFailure(let a), .networkFailure(let b)):
            return a.code == b.code
        case (.httpError(let codeA, _), .httpError(let codeB, _)):
            return codeA == codeB
        case (.rateLimited(let a), .rateLimited(let b)):
            return a == b
        case (.decodingFailed(let a), .decodingFailed(let b)):
            return a == b
        case (.clientDeallocated, .clientDeallocated):
            return true
        case (.unknown(let a), .unknown(let b)):
            return a == b
        default:
            return false
        }
    }
}

