//
//  RequestBuilderTests.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 24.03.2026.
//

import XCTest
@testable import JikanSwift

final class RequestBuilderTests: XCTestCase {

    private let builder = RequestBuilder()

    // MARK: – URL composition

    func testBuildProducesValidURL() throws {
        let ep = JikanEndpoint.animeDetails(id: 1)
        let request = try builder.build(from: ep)

        XCTAssertEqual(request.url?.host, "api.jikan.moe")
        XCTAssertEqual(request.url?.path, "/v4/anime/1")
        XCTAssertEqual(request.httpMethod, "GET")
    }

    func testBuildAttachesQueryItems() throws {
        let ep = JikanEndpoint.animeSearch(query: "Bebop", page: 1, limit: 10)
        let request = try builder.build(from: ep)

        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        let items = Dictionary(
            uniqueKeysWithValues: components.queryItems!.map { ($0.name, $0.value) }
        )

        XCTAssertEqual(items["q"], "Bebop")
        XCTAssertEqual(items["limit"], "10")
        XCTAssertEqual(items["page"], "1")
    }

    func testBuildStripsNilQueryValues() throws {
        let ep = JikanEndpoint.schedules(day: nil, page: 1)
        let request = try builder.build(from: ep)

        let components = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)!
        let names = components.queryItems?.map(\.name) ?? []

        XCTAssertTrue(names.contains("page"))
        XCTAssertFalse(names.contains("filter"))
    }

    // MARK: – Headers

    func testBuildSetsAcceptHeader() throws {
        let ep = JikanEndpoint.animeRandom
        let request = try builder.build(from: ep)

        XCTAssertEqual(
            request.value(forHTTPHeaderField: "Accept"),
            "application/json"
        )
    }

    func testBuildDoesNotSetContentTypeWithoutBody() throws {
        let ep = JikanEndpoint.animeDetails(id: 5)
        let request = try builder.build(from: ep)

        XCTAssertNil(request.value(forHTTPHeaderField: "Content-Type"))
    }

    // MARK: – Custom base URL

    func testCustomBaseURL() throws {
        let custom = RequestBuilder(baseURL: "https://custom.api/v4")
        let ep = JikanEndpoint.animeDetails(id: 99)
        let request = try custom.build(from: ep)

        XCTAssertTrue(request.url!.absoluteString.hasPrefix("https://custom.api/v4"))
        XCTAssertTrue(request.url!.absoluteString.contains("/anime/99"))
    }

    // MARK: – Timeout

    func testDefaultTimeout() throws {
        let ep = JikanEndpoint.animeRandom
        let request = try builder.build(from: ep)

        XCTAssertEqual(request.timeoutInterval, Constants.defaultTimeoutInterval)
    }

    func testCustomTimeout() throws {
        let fast = RequestBuilder(timeoutInterval: 5)
        let request = try fast.build(from: JikanEndpoint.animeRandom)

        XCTAssertEqual(request.timeoutInterval, 5)
    }

    // MARK: – Invalid URL

    func testBuildWithEmptyBaseURLThrows() {
        let broken = RequestBuilder(baseURL: "ht tp://bad url")
        let ep = JikanEndpoint.animeDetails(id: 1)

        XCTAssertThrowsError(try broken.build(from: ep)) { error in
            guard case APIError.invalidURL = error else {
                return XCTFail("Expected .invalidURL, got \(error)")
            }
        }
    }

    // MARK: – Encoding special characters

    func testQueryEncodesSpecialCharacters() throws {
        let ep = JikanEndpoint.animeSearch(query: "Re:Zero kara", page: 1, limit: 25)
        let request = try builder.build(from: ep)

        // URLComponents should percent-encode the colon in the query value
        XCTAssertNotNil(request.url)
        let absoluteString = request.url!.absoluteString
        XCTAssertTrue(
            absoluteString.contains("Re") && absoluteString.contains("Zero"),
            "Query should be present in URL: \(absoluteString)"
        )
    }
}

