//
//  JikanEndpoint.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 07.03.2026.
//

import Foundation

/// Concrete Jikan API v4 routes.
///
/// Each case fully describes one API call (path + query).
/// New domains (manga, characters, etc.) should be added
/// as additional nested enums inside `JikanEndpoint`.
public enum JikanEndpoint: Endpoint {

    // MARK: – Anime

    /// Search anime by query string with optional pagination.
    case animeSearch(query: String, page: Int = 1, limit: Int = Constants.defaultPageSize)

    /// Fetch full details for a single anime by MAL id.
    case animeDetails(id: Int)

    /// Top anime list with optional filter and pagination.
    case animeTop(filter: AnimeTopFilter = .bypopularity, page: Int = 1, limit: Int = Constants.defaultPageSize)

    /// Fetch anime recommendations for a given MAL id.
    case animeRecommendations(id: Int)

    /// Fetch episodes list for a given anime.
    case animeEpisodes(id: Int, page: Int = 1)

    /// Fetch characters for a given anime.
    case animeCharacters(id: Int)

    /// Fetch currently airing anime schedule (optionally filtered by day).
    case schedules(day: ScheduleDay? = nil, page: Int = 1)

    /// Fetch a random anime.
    case animeRandom

    // MARK: – Endpoint conformance

    public var path: String {
        switch self {
        case .animeSearch:                return "/anime"
        case .animeDetails(let id):       return "/anime/\(id)"
        case .animeTop:                   return "/top/anime"
        case .animeRecommendations(let id): return "/anime/\(id)/recommendations"
        case .animeEpisodes(let id, _):   return "/anime/\(id)/episodes"
        case .animeCharacters(let id):    return "/anime/\(id)/characters"
        case .schedules:                  return "/schedules"
        case .animeRandom:                return "/random/anime"
        }
    }

    public var queryItems: [String: String?]? {
        switch self {
        case .animeSearch(let q, let page, let limit):
            return [
                "q": q,
                "page": "\(page)",
                "limit": "\(limit)"
            ]

        case .animeTop(let filter, let page, let limit):
            return [
                "filter": filter.rawValue,
                "page": "\(page)",
                "limit": "\(limit)"
            ]

        case .animeEpisodes(_, let page):
            return ["page": "\(page)"]

        case .schedules(let day, let page):
            var items: [String: String?] = ["page": "\(page)"]
            items["filter"] = day?.rawValue
            return items

        default:
            return nil
        }
    }
}

// MARK: – Supporting types

public extension JikanEndpoint {

    /// Filters accepted by the `/top/anime` endpoint.
    enum AnimeTopFilter: String, Sendable {
        case airing
        case upcoming
        case bypopularity
        case favorite
    }

    /// Days accepted by the `/schedules` endpoint.
    enum ScheduleDay: String, Sendable {
        case monday, tuesday, wednesday, thursday, friday, saturday, sunday, unknown, other
    }
}

