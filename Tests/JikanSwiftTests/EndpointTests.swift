//
//  EndpointTests.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 24.03.2026.
//

import XCTest
@testable import JikanSwift

final class EndpointTests: XCTestCase {

    // MARK: – Path

    func testAnimeSearchPath() {
        let ep = JikanEndpoint.animeSearch(query: "Naruto")
        XCTAssertEqual(ep.path, "/anime")
        XCTAssertEqual(ep.method, .get)
    }

    func testAnimeDetailsPath() {
        let ep = JikanEndpoint.animeDetails(id: 42)
        XCTAssertEqual(ep.path, "/anime/42")
    }

    func testAnimeTopPath() {
        let ep = JikanEndpoint.animeTop(filter: .airing)
        XCTAssertEqual(ep.path, "/top/anime")
    }

    func testAnimeCharactersPath() {
        let ep = JikanEndpoint.animeCharacters(id: 1)
        XCTAssertEqual(ep.path, "/anime/1/characters")
    }

    func testAnimeRandomPath() {
        let ep = JikanEndpoint.animeRandom
        XCTAssertEqual(ep.path, "/random/anime")
    }

    func testSchedulesPath() {
        let ep = JikanEndpoint.schedules(day: .monday)
        XCTAssertEqual(ep.path, "/schedules")
    }

    // MARK: – Query items

    func testAnimeSearchQueryItems() {
        let ep = JikanEndpoint.animeSearch(query: "One Piece", page: 2, limit: 10)
        let items = ep.queryItems ?? [:]
        XCTAssertEqual(items["q"] as? String, "One Piece")
        XCTAssertEqual(items["page"] as? String, "2")
        XCTAssertEqual(items["limit"] as? String, "10")
    }

    func testAnimeTopQueryItemsContainFilter() {
        let ep = JikanEndpoint.animeTop(filter: .favorite, page: 3, limit: 5)
        let items = ep.queryItems ?? [:]
        XCTAssertEqual(items["filter"] as? String, "favorite")
    }

    func testAnimeDetailsHasNoQueryItems() {
        let ep = JikanEndpoint.animeDetails(id: 1)
        XCTAssertNil(ep.queryItems)
    }

    func testSchedulesDayQueryItem() {
        let ep = JikanEndpoint.schedules(day: .friday, page: 1)
        let items = ep.queryItems ?? [:]
        XCTAssertEqual(items["filter"] as? String, "friday")
    }

    // MARK: – Cache key stability

    func testCacheKeyIsDeterministic() {
        let a = JikanEndpoint.animeSearch(query: "test", page: 1, limit: 25).cacheKey
        let b = JikanEndpoint.animeSearch(query: "test", page: 1, limit: 25).cacheKey
        XCTAssertEqual(a, b)
    }

    func testCacheKeyDiffersForDifferentQueries() {
        let a = JikanEndpoint.animeSearch(query: "Naruto").cacheKey
        let b = JikanEndpoint.animeSearch(query: "Bleach").cacheKey
        XCTAssertNotEqual(a, b)
    }
}

