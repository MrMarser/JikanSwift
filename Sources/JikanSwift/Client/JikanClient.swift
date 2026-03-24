//
//  JikanClient.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 07.03.2026.
//

import Foundation

/// Primary entry point for consumers of JikanSwift.
///
/// ```swift
/// let client = JikanClient()
/// let results = try await client.searchAnime(query: "Naruto")
/// ```
///
/// Thread-safe — every method is a plain `async throws` function
/// that can be called from any Swift concurrency context.
public final class JikanClient: Sendable {

    // MARK: – Dependencies

    private let httpClient: HTTPClientProtocol
    private let requestBuilder: RequestBuilder
    private let decoder: JSONDecoder
    private let cache: ResponseCaching?

    // MARK: – Init

    /// Creates a new client.
    ///
    /// - Parameters:
    ///   - httpClient:     Transport layer (defaults to `URLSession.shared`).
    ///   - requestBuilder: Converts endpoints into `URLRequest`s.
    ///   - cache:          Optional response cache. Pass `nil` to disable.
    public init(
        httpClient: HTTPClientProtocol = HTTPClient(),
        requestBuilder: RequestBuilder = .init(),
        cache: ResponseCaching? = nil
    ) {
        self.httpClient = httpClient
        self.requestBuilder = requestBuilder
        self.cache = cache

        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        self.decoder = decoder
    }

    // MARK: – Anime convenience methods

    /// Search anime by title.
    public func searchAnime(
        query: String,
        page: Int = 1,
        limit: Int = Constants.defaultPageSize,
        cachePolicy: CachePolicy = .returnCacheElseLoad
    ) async throws -> JikanResponse<AnimeBrief> {
        try await request(
            endpoint: JikanEndpoint.animeSearch(query: query, page: page, limit: limit),
            cachePolicy: cachePolicy
        )
    }

    /// Fetch full details for a single anime.
    public func animeDetails(
        id: Int,
        cachePolicy: CachePolicy = .returnCacheElseLoad
    ) async throws -> AnimeDetails {
        let response: JikanSingleResponse<AnimeDetails> = try await request(
            endpoint: JikanEndpoint.animeDetails(id: id),
            cachePolicy: cachePolicy
        )
        return response.data
    }

    /// Fetch top anime list.
    public func topAnime(
        filter: JikanEndpoint.AnimeTopFilter = .bypopularity,
        page: Int = 1,
        limit: Int = Constants.defaultPageSize,
        cachePolicy: CachePolicy = .returnCacheElseLoad
    ) async throws -> JikanResponse<AnimeBrief> {
        try await request(
            endpoint: JikanEndpoint.animeTop(filter: filter, page: page, limit: limit),
            cachePolicy: cachePolicy
        )
    }

    /// Fetch a random anime.
    public func randomAnime(
    ) async throws -> AnimeDetails {
        let response: JikanSingleResponse<AnimeDetails> = try await request(
            endpoint: JikanEndpoint.animeRandom,
            cachePolicy: .ignoreCache
        )
        return response.data
    }

    /// Fetch characters for a given anime.
    public func animeCharacters(
        id: Int,
        cachePolicy: CachePolicy = .returnCacheElseLoad
    ) async throws -> JikanResponse<AnimeCharacter> {
        try await request(
            endpoint: JikanEndpoint.animeCharacters(id: id),
            cachePolicy: cachePolicy
        )
    }

    /// Fetch airing schedule.
    public func schedules(
        day: JikanEndpoint.ScheduleDay? = nil,
        page: Int = 1,
        cachePolicy: CachePolicy = .returnCacheElseLoad
    ) async throws -> JikanResponse<AnimeBrief> {
        try await request(
            endpoint: JikanEndpoint.schedules(day: day, page: page),
            cachePolicy: cachePolicy
        )
    }

    // MARK: – Generic request pipeline

    /// The central request pipeline shared by every convenience method.
    ///
    /// 1. Check cache (if policy allows).
    /// 2. Build `URLRequest` via `RequestBuilder`.
    /// 3. Execute via `HTTPClientProtocol`.
    /// 4. Validate HTTP status.
    /// 5. Decode JSON.
    /// 6. Store in cache (if caching is enabled).
    public func request<T: Decodable & Sendable>(
        endpoint: Endpoint,
        cachePolicy: CachePolicy = .returnCacheElseLoad
    ) async throws -> T {

        let cacheKey = endpoint.cacheKey

        // ── 1. Cache read ──────────────────────────────────
        if cachePolicy != .ignoreCache, let cache {
            if let cached = await cache.cachedResponse(for: cacheKey) {
                if let decoded: T = try? decode(cached) {
                    // For `.returnCacheAndRefresh` we return cached
                    // immediately; a background refresh is left to the
                    // caller (or a future middleware).
                    return decoded
                }
            }
        }

        // ── 2. Build request ───────────────────────────────
        let urlRequest = try requestBuilder.build(from: endpoint)

        // ── 3. Execute ─────────────────────────────────────
        let (data, response) = try await httpClient.execute(urlRequest)

        // ── 4. Validate ────────────────────────────────────
        try validate(response: response, data: data)

        // ── 5. Decode ──────────────────────────────────────
        let decoded: T = try decode(data)

        // ── 6. Cache write ─────────────────────────────────
        if let cache, cachePolicy != .ignoreCache {
            await cache.store(data, for: cacheKey)
        }

        return decoded
    }

    // MARK: – Private helpers

    private func validate(response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { return }

        switch http.statusCode {
        case 200...299:
            return
        case 429:
            let retryAfter = http.value(forHTTPHeaderField: "Retry-After")
                .flatMap(TimeInterval.init)
            throw APIError.rateLimited(retryAfter: retryAfter)
        default:
            throw APIError.httpError(statusCode: http.statusCode, data: data)
        }
    }

    private func decode<T: Decodable>(_ data: Data) throws -> T {
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(
                context: "\(T.self): \(error.localizedDescription)"
            )
        }
    }
}
