//
//  AnimeDetails.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 10.03.2026.
//

import Foundation

/// Full anime resource returned by `/anime/{id}`.
///
/// Contains everything in `AnimeBrief` plus extended metadata
/// (genres, studios, aired dates, related entries, etc.).
public struct AnimeDetails: Decodable, Sendable, Identifiable, Equatable {

    // MARK: – Core (mirrors AnimeBrief)

    public let id: Int
    public let url: String?
    public let title: String
    public let titleEnglish: String?
    public let titleJapanese: String?
    public let titleSynonyms: [String]?

    // MARK: – Media metadata

    public let type: String?
    public let source: String?
    public let episodes: Int?
    public let status: String?
    public let airing: Bool?
    public let aired: Aired?
    public let duration: String?
    public let rating: String?       // PG-13, R, …

    // MARK: – Scores & stats

    public let score: Double?
    public let scoredBy: Int?
    public let rank: Int?
    public let popularity: Int?
    public let members: Int?
    public let favorites: Int?

    // MARK: – Rich content

    public let synopsis: String?
    public let background: String?
    public let season: String?
    public let year: Int?

    // MARK: – Images

    public let images: AnimeImages?
    public let trailer: Trailer?

    // MARK: – Relations

    public let genres: [MALEntity]?
    public let themes: [MALEntity]?
    public let demographics: [MALEntity]?
    public let studios: [MALEntity]?
    public let producers: [MALEntity]?
    public let licensors: [MALEntity]?

    // MARK: – CodingKeys

    private enum CodingKeys: String, CodingKey {
        case id             = "mal_id"
        case url, title
        case titleEnglish   = "title_english"
        case titleJapanese  = "title_japanese"
        case titleSynonyms  = "title_synonyms"
        case type, source, episodes, status, airing, aired
        case duration, rating, score
        case scoredBy       = "scored_by"
        case rank, popularity, members, favorites
        case synopsis, background, season, year
        case images, trailer
        case genres, themes, demographics
        case studios, producers, licensors
    }
}

// MARK: – Supporting types

public struct Aired: Decodable, Sendable, Equatable {
    public let from: String?
    public let to: String?
    public let string: String?      // human-readable, e.g. "Apr 3, 1998 to Apr 24, 1999"
}

public struct Trailer: Decodable, Sendable, Equatable {
    public let youtubeId: String?
    public let url: String?
    public let embedUrl: String?

    private enum CodingKeys: String, CodingKey {
        case youtubeId = "youtube_id"
        case url
        case embedUrl  = "embed_url"
    }
}

/// Generic MAL resource reference (genre, studio, producer, …).
public struct MALEntity: Decodable, Sendable, Identifiable, Equatable {
    public let id: Int
    public let type: String?
    public let name: String
    public let url: String?

    private enum CodingKeys: String, CodingKey {
        case id   = "mal_id"
        case type, name, url
    }
}

