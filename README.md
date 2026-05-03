<p align="center">
  <h1 align="center">JikanSwift</h1>
  <p align="center">
    Type-safe Swift client for <a href="https://docs.api.jikan.moe/">Jikan API v4</a> — unofficial MyAnimeList REST API
  </p>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Swift-5.9+-F05138?logo=swift&logoColor=white" alt="Swift 5.9+">
  <img src="https://img.shields.io/badge/Platforms-iOS_15+_|_macOS_12+_|_tvOS_15+_|_watchOS_8+-007AFF" alt="Platforms">
  <img src="https://img.shields.io/badge/SPM-Compatible-brightgreen" alt="SPM Compatible">
  <img src="https://img.shields.io/badge/License-MIT-yellow" alt="MIT License">
</p>

---

JikanSwift provides a clean, protocol-oriented wrapper around the [Jikan REST API](https://jikan.moe) for accessing MyAnimeList data — anime search, details, rankings, schedules, characters and more.

Built entirely on Swift Concurrency (`async/await`) with full `Sendable` conformance, making it ready for Swift 6 strict concurrency.

## Highlights

- **Zero dependencies** — built on `Foundation` and `URLSession` only
- **Async/await from the ground up** — no callbacks, no Combine wrappers, no completion handlers
- **Protocol-oriented** — every layer is abstracted behind a protocol (`Endpoint`, `HTTPClientProtocol`, `ResponseCaching`), making it trivial to mock for tests
- **Pluggable caching** — ships with `InMemoryCache`; bring your own SQLite/CoreData/file-system backend by conforming to one protocol
- **Sendable everywhere** — safe to call from any actor, any task, any thread
- **Lightweight models** — `AnimeBrief` for lists, `AnimeDetails` for full data — no over-fetching

## Table of Contents

- [Requirements](#requirements)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [API Reference](#api-reference)
  - [Search](#search)
  - [Details](#details)
  - [Top Anime](#top-anime)
  - [Schedules](#schedules)
  - [Characters](#characters)
  - [Random Anime](#random-anime)
  - [Generic Request](#generic-request)
- [Pagination](#pagination)
- [Caching](#caching)
  - [Cache Policies](#cache-policies)
  - [Built-in InMemoryCache](#built-in-inmemorycache)
  - [Custom Cache Backend](#custom-cache-backend)
- [Error Handling](#error-handling)
- [Architecture](#architecture)
  - [Project Structure](#project-structure)
  - [Request Pipeline](#request-pipeline)
  - [Design Decisions](#design-decisions)
- [Testing](#testing)
  - [Running Tests](#running-tests)
  - [Mocking the Network](#mocking-the-network)
- [Extending the Library](#extending-the-library)
- [Rate Limiting](#rate-limiting)
- [License](#license)

## Requirements

| Dependency | Minimum Version |
|:-----------|:----------------|
| Swift      | 5.9             |
| iOS        | 15.0            |
| macOS      | 12.0            |
| tvOS       | 15.0            |
| watchOS    | 8.0             |
| Xcode      | 15.0            |

No external packages required.

## Installation

### Swift Package Manager

Add JikanSwift as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/MrMarser/JikanSwift.git", from: "1.0.0")
]
```

Then add `"JikanSwift"` to your target's dependencies:

```swift
.target(
    name: "YourApp",
    dependencies: ["JikanSwift"]
)
```

### Xcode

1. Open your project in Xcode
2. Go to **File → Add Package Dependencies…**
3. Paste the repository URL
4. Select the version rule and add to your target

## Quick Start

```swift
import JikanSwift

let client = JikanClient()

// Search for anime
let results = try await client.searchAnime(query: "Cowboy Bebop")
for anime in results.data {
    print("\(anime.title) — score: \(anime.score ?? 0)")
}

// Get full details by MAL ID
let bebop = try await client.animeDetails(id: 1)
print(bebop.synopsis ?? "No synopsis")
print(bebop.studios?.map(\.name) ?? [])   // ["Sunrise"]

// Today's airing schedule
let schedule = try await client.schedules(day: .monday)
```

## API Reference

Every method on `JikanClient` is `async throws` and can be called from any Swift concurrency context — a `Task`, a `@MainActor` view model, a detached task, etc.

### Search

```swift
let results = try await client.searchAnime(
    query: "Attack on Titan",
    page: 1,
    limit: 10
)

// results.data       → [AnimeBrief]
// results.pagination → Pagination?
```

Returns a `JikanResponse<AnimeBrief>` containing an array of lightweight anime objects and pagination metadata.

### Details

```swift
let anime = try await client.animeDetails(id: 1)

anime.title              // "Cowboy Bebop"
anime.titleJapanese      // "カウボーイビバップ"
anime.score              // 8.75
anime.episodes           // 26
anime.aired?.string      // "Apr 3, 1998 to Apr 24, 1999"
anime.rating             // "R - 17+ (violence & profanity)"
anime.genres             // [MALEntity] — Action, Award Winning
anime.studios            // [MALEntity] — Sunrise
anime.trailer?.youtubeId // "qig4KOK2R2g"
```

Returns `AnimeDetails` — the full model with genres, studios, producers, aired dates, trailer, synopsis, background and more.

### Top Anime

```swift
// Most popular (default)
let popular = try await client.topAnime()

// By filter
let airing   = try await client.topAnime(filter: .airing)
let upcoming = try await client.topAnime(filter: .upcoming)
let favorites = try await client.topAnime(filter: .favorite)

// With pagination
let page3 = try await client.topAnime(filter: .bypopularity, page: 3, limit: 10)
```

Available filters: `.airing`, `.upcoming`, `.bypopularity`, `.favorite`.

### Schedules

```swift
// Full weekly schedule
let all = try await client.schedules()

// Filter by day
let monday = try await client.schedules(day: .monday)
let friday = try await client.schedules(day: .friday, page: 2)
```

Available days: `.monday` through `.sunday`, plus `.unknown` and `.other`.

### Characters

```swift
let characters = try await client.animeCharacters(id: 1)

for entry in characters.data {
    print("\(entry.character.name) — \(entry.role ?? "")")

    for va in entry.voiceActors ?? [] {
        print("  VA: \(va.person.name) (\(va.language ?? ""))")
    }
}
```

Returns `JikanResponse<AnimeCharacter>` with character info, role and voice actors.

### Random Anime

```swift
let surprise = try await client.randomAnime()
print(surprise.title)
```

Always hits the network (cache is ignored) since each call returns a different result.

### Generic Request

For advanced use or endpoints not yet wrapped by a convenience method, use the generic `request` method directly:

```swift
let response: JikanResponse<AnimeBrief> = try await client.request(
    endpoint: JikanEndpoint.animeSearch(query: "Gintama", page: 1, limit: 5),
    cachePolicy: .ignoreCache
)
```

This is the same pipeline every convenience method uses internally.

## Pagination

Collection endpoints return `JikanResponse<T>` which includes pagination metadata:

```swift
let response = try await client.searchAnime(query: "Gundam")

if let pagination = response.pagination {
    print("Page: \(pagination.currentPage ?? 0)")
    print("Total pages: \(pagination.lastVisiblePage)")
    print("Has next: \(pagination.hasNextPage)")
    print("Total items: \(pagination.items?.total ?? 0)")
}
```

Example — iterating through all pages:

```swift
var page = 1
var hasMore = true

while hasMore {
    let response = try await client.searchAnime(query: "Gundam", page: page)

    for anime in response.data {
        // process each anime
    }

    hasMore = response.pagination?.hasNextPage ?? false
    page += 1

    // respect Jikan rate limit (~3 req/s)
    try await Task.sleep(for: .milliseconds(350))
}
```

## Caching

JikanSwift ships with an optional, protocol-based caching layer. By default caching is **disabled** — pass a `ResponseCaching` implementation to the client to enable it.

### Cache Policies

Every method accepts an optional `cachePolicy` parameter:

| Policy                   | Behavior                                                                |
|:-------------------------|:------------------------------------------------------------------------|
| `.ignoreCache`           | Always hit the network. Skip both read and write.                       |
| `.returnCacheElseLoad`   | Return cached response if available and not expired; otherwise fetch.   |
| `.returnCacheAndRefresh` | Return cached response immediately (even if stale). Caller may refresh in background. |

Default policy for all methods is `.returnCacheElseLoad`.

### Built-in InMemoryCache

```swift
let client = JikanClient(
    cache: InMemoryCache(countLimit: 200, ttl: 300)  // 5 min TTL, max 200 entries
)

// First call → network request
let a = try await client.searchAnime(query: "Naruto")

// Second call → served from cache instantly
let b = try await client.searchAnime(query: "Naruto")

// Force a fresh network fetch
let c = try await client.searchAnime(query: "Naruto", cachePolicy: .ignoreCache)
```

`InMemoryCache` is backed by `NSCache`, so the system can automatically evict entries under memory pressure.

### Custom Cache Backend

Conform to `ResponseCaching` to plug in any storage you need:

```swift
public protocol ResponseCaching: Sendable {
    func cachedResponse(for key: String) async -> Data?
    func store(_ data: Data, for key: String) async
    func remove(for key: String) async
    func removeAll() async
}
```

Example — file-system cache:

```swift
final class DiskCache: ResponseCaching {
    private let directory: URL

    init(directory: URL) {
        self.directory = directory
        try? FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
    }

    func cachedResponse(for key: String) async -> Data? {
        try? Data(contentsOf: fileURL(for: key))
    }

    func store(_ data: Data, for key: String) async {
        try? data.write(to: fileURL(for: key))
    }

    func remove(for key: String) async {
        try? FileManager.default.removeItem(at: fileURL(for: key))
    }

    func removeAll() async {
        try? FileManager.default.removeItem(at: directory)
        try? FileManager.default.createDirectory(
            at: directory, withIntermediateDirectories: true
        )
    }

    private func fileURL(for key: String) -> URL {
        let safe = key.addingPercentEncoding(
            withAllowedCharacters: .alphanumerics
        ) ?? key
        return directory.appendingPathComponent(safe)
    }
}

// Usage
let client = JikanClient(cache: DiskCache(directory: myCacheDirectory))
```

## Error Handling

All errors are thrown as `APIError` — a single enum covering every failure mode:

```swift
do {
    let anime = try await client.animeDetails(id: 999999)
} catch let error as APIError {
    switch error {
    case .httpError(let statusCode, _):
        // Server returned a non-2xx status (e.g. 404 Not Found)
        print("HTTP \(statusCode)")

    case .rateLimited(let retryAfter):
        // Jikan returned HTTP 429 — back off and retry
        if let seconds = retryAfter {
            try await Task.sleep(for: .seconds(seconds))
        }

    case .networkFailure(let urlError):
        // No connection, DNS failure, timeout, TLS error, etc.
        print("Network error: \(urlError.code)")

    case .decodingFailed(let context):
        // Response JSON didn't match the expected model
        print("Decode error: \(context)")

    case .invalidURL(let url):
        // Malformed URL (shouldn't happen in normal usage)
        print("Bad URL: \(url)")

    case .clientDeallocated:
        // Client was released before the request completed
        break

    case .unknown(let message):
        print(message)
    }
}
```

`APIError` conforms to `LocalizedError` (so `.localizedDescription` works out of the box) and `Equatable` (so you can assert on specific errors in tests).

## Architecture

### Project Structure

```
JikanSwift/
├── Package.swift
├── Sources/JikanSwift/
│   ├── Client/
│   │   ├── JikanClient.swift         # Facade — the only type consumers interact with
│   │   ├── HTTPClient.swift          # Protocol + URLSession implementation
│   │   └── RequestBuilder.swift      # Endpoint → URLRequest conversion
│   ├── Endpoint/
│   │   ├── Endpoint.swift            # Protocol with sensible defaults
│   │   ├── HTTPMethod.swift          # GET, POST, PUT, PATCH, DELETE
│   │   └── JikanEndpoints.swift      # Concrete Jikan API routes (enum)
│   ├── Models/
│   │   ├── Common/
│   │   │   └── JikanResponse.swift   # Generic response wrappers + Pagination
│   │   └── Anime/
│   │       ├── AnimeBrief.swift       # Lightweight model for search/list results
│   │       ├── AnimeDetails.swift     # Full model with all metadata
│   │       └── AnimeCharacter.swift   # Characters + voice actors
│   ├── Cache/
│   │   ├── CachePolicy.swift         # CachePolicy enum + ResponseCaching protocol
│   │   └── InMemoryCache.swift       # NSCache-based default implementation
│   ├── Errors/
│   │   └── APIError.swift            # Unified error enum
│   └── Utilities/
│       └── Constants.swift           # Base URL, timeouts, rate limit values
├── Tests/JikanSwiftTests/
│   ├── EndpointTests.swift           # Path, query, HTTP method, cache key
│   ├── RequestBuilderTests.swift     # URL composition, headers, edge cases
│   ├── DecodingTests.swift           # Fixture-based model decoding
│   └── Fixtures/
│       ├── anime_search.json
│       └── anime_details.json
└── Examples/
    
```

### Request Pipeline

Every API call flows through the same six-step pipeline inside `JikanClient.request()`:

```
┌───────────────┐
│  Cache Read   │ ← if policy allows and cache hit → return immediately
└──────┬────────┘
       ▼
┌───────────────┐
│ RequestBuilder│ ← Endpoint → URLRequest (URL + query + headers)
└──────┬────────┘
       ▼
┌───────────────┐
│  HTTPClient   │ ← URLSession.data(for:) or mock transport
└──────┬────────┘
       ▼
┌───────────────┐
│   Validate    │ ← Check HTTP status: 2xx OK, 429 rate-limited, else error
└──────┬────────┘
       ▼
┌───────────────┐
│   Decode      │ ← JSONDecoder → generic T: Decodable
└──────┬────────┘
       ▼
┌───────────────┐
│  Cache Write  │ ← Store raw Data for future hits
└───────────────┘
```

### Design Decisions

**Endpoint as value, not behavior.** Each `JikanEndpoint` case describes *what* to call — path, query items, HTTP method. It knows nothing about *how* the request is executed. `RequestBuilder` handles the conversion to `URLRequest`, and `HTTPClient` handles the transport. This separation means you can test each layer in complete isolation.

**Protocol-based dependency injection.** `HTTPClientProtocol` and `ResponseCaching` are protocols, not concrete classes. `JikanClient` accepts them through its initializer. In production you get `URLSession`; in tests you inject a mock that returns fixture data — zero network, deterministic results, instant execution.

**Two-tier models.** `AnimeBrief` is intentionally lightweight — it only includes fields returned in search and list endpoints. `AnimeDetails` adds genres, studios, aired dates, trailer, background, etc. This mirrors how the Jikan API itself works and prevents callers from depending on fields that aren't present in list responses.

**Cache is optional by default.** The client works perfectly without a cache (`cache: nil`). When you're ready to add caching, pass `InMemoryCache()` or your own `ResponseCaching` implementation — no code changes needed anywhere else. Every `Endpoint` generates a deterministic `cacheKey` from its method, path, and query parameters.

**Sendable conformance.** Every public type — `JikanClient`, all models, `InMemoryCache`, `APIError` — conforms to `Sendable`. This means the library is safe to use with Swift 6 strict concurrency checking and works correctly across actors and task groups without data races.

## Testing

### Running Tests

```bash
swift test
```

All tests are **offline** — they use bundled JSON fixtures and pure logic. No network access required.

The test suite covers:

| Test file                  | What it verifies                                          |
|:---------------------------|:----------------------------------------------------------|
| `EndpointTests.swift`      | Path generation, query items, HTTP method, cache key determinism |
| `RequestBuilderTests.swift`| URL composition, headers, query encoding, timeouts, special characters, error cases |
| `DecodingTests.swift`      | Fixture-based decoding for search responses, details, pagination, nested models, edge cases |

### Mocking the Network

To test code that depends on `JikanClient`, inject a mock transport:

```swift
struct MockHTTPClient: HTTPClientProtocol {
    let data: Data
    let statusCode: Int

    func execute(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        )!
        return (data, response)
    }
}

// In your test
let fixture = try Data(contentsOf: Bundle.module.url(
    forResource: "anime_search", withExtension: "json", subdirectory: "Fixtures"
)!)

let client = JikanClient(
    httpClient: MockHTTPClient(data: fixture, statusCode: 200)
)

let results = try await client.searchAnime(query: "anything")
XCTAssertFalse(results.data.isEmpty)
```

You can also mock error scenarios:

```swift
// Simulate a 404
let client = JikanClient(
    httpClient: MockHTTPClient(data: Data(), statusCode: 404)
)

do {
    _ = try await client.animeDetails(id: 999)
    XCTFail("Should have thrown")
} catch let error as APIError {
    XCTAssertEqual(error, .httpError(statusCode: 404, data: Data()))
}
```

## Extending the Library

### Adding a new domain (e.g. Manga)

The architecture is designed to be extended without modifying existing files:

**1. Create models** in `Models/Manga/`:
```swift
// Sources/JikanSwift/Models/Manga/MangaBrief.swift
public struct MangaBrief: Decodable, Sendable, Identifiable {
    public let id: Int
    public let title: String
    public let chapters: Int?
    public let score: Double?
    // ...

    private enum CodingKeys: String, CodingKey {
        case id = "mal_id"
        case title, chapters, score
    }
}
```

**2. Add endpoint cases** to `JikanEndpoint`:
```swift
case mangaSearch(query: String, page: Int = 1, limit: Int = 25)
case mangaDetails(id: Int)
```

**3. Add convenience methods** to `JikanClient`:
```swift
public func searchManga(
    query: String,
    page: Int = 1
) async throws -> JikanResponse<MangaBrief> {
    try await request(
        endpoint: JikanEndpoint.mangaSearch(query: query, page: page)
    )
}
```

### Using a custom endpoint

If you need a route not yet defined in `JikanEndpoint`, create your own type conforming to `Endpoint`:

```swift
struct UserAnimeListEndpoint: Endpoint {
    let username: String
    let status: String

    var path: String { "/users/\(username)/animelist" }
    var queryItems: [String: String?]? { ["status": status] }
}

let response: JikanResponse<AnimeBrief> = try await client.request(
    endpoint: UserAnimeListEndpoint(username: "john", status: "watching")
)
```

## Rate Limiting

The public Jikan API enforces a rate limit of approximately **3 requests per second**. JikanSwift does **not** auto-throttle — the caller is responsible for pacing requests.

Recommendations:

- Add `Task.sleep(for: .milliseconds(350))` between rapid sequential calls
- Use caching to avoid redundant network requests
- Handle `.rateLimited` errors with exponential backoff:

```swift
func fetchWithRetry<T: Decodable & Sendable>(
    endpoint: Endpoint,
    maxRetries: Int = 3
) async throws -> T {
    for attempt in 0..<maxRetries {
        do {
            return try await client.request(endpoint: endpoint)
        } catch APIError.rateLimited(let retryAfter) {
            let delay = retryAfter ?? Double(attempt + 1)
            try await Task.sleep(for: .seconds(delay))
        }
    }
    return try await client.request(endpoint: endpoint)
}
```

The rate limit constant is exposed as `Constants.rateLimitPerSecond` for reference.

## License

MIT — see [LICENSE](LICENSE) for details.
