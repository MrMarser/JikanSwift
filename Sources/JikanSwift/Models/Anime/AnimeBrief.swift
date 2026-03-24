//
//  AnimeBrief.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 10.03.2026.
//

import Foundation

/// Lightweight anime representation used in list/search results.
///
/// Maps to the objects inside `"data": [...]` of `/anime?q=…` and `/top/anime`.
public struct AnimeBrief: Decodable, Sendable, Identifiable, Equatable {

    // MARK: – Core

    public let id: Int              // mal_id
    public let url: String?
    public let title: String
    public let titleEnglish: String?
    public let titleJapanese: String?

    // MARK: – Media metadata

    public let type: String?        // TV, Movie, OVA, …
    public let source: String?      // Manga, Light novel, …
    public let episodes: Int?
    public let status: String?      // Airing, Finished Airing, …
    public let score: Double?
    public let scoredBy: Int?
    public let rank: Int?
    public let popularity: Int?
    public let members: Int?

    // MARK: – Images

    public let images: AnimeImages?

    // MARK: – Synopsis (truncated in search results)

    public let synopsis: String?

    // MARK: – CodingKeys

    private enum CodingKeys: String, CodingKey {
        case id            = "mal_id"
        case url
        case title
        case titleEnglish  = "title_english"
        case titleJapanese = "title_japanese"
        case type, source, episodes, status
        case score
        case scoredBy      = "scored_by"
        case rank, popularity, members
        case images
        case synopsis
    }
}

// MARK: – Nested image model

public struct AnimeImages: Decodable, Sendable, Equatable {
    public let jpg: ImageURLSet?
    public let webp: ImageURLSet?
}

public struct ImageURLSet: Decodable, Sendable, Equatable {
    public let imageURL: String?
    public let smallImageURL: String?
    public let largeImageURL: String?

    private enum CodingKeys: String, CodingKey {
        case imageURL      = "image_url"
        case smallImageURL = "small_image_url"
        case largeImageURL = "large_image_url"
    }
}

