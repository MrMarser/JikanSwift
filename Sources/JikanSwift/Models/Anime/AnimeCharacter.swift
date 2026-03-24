//
//  AnimeCharacter.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 10.03.2026.
//

import Foundation

/// Character entry returned by `/anime/{id}/characters`.
public struct AnimeCharacter: Decodable, Sendable, Equatable {

    public let character: CharacterInfo
    public let role: String?
    public let voiceActors: [VoiceActor]?

    private enum CodingKeys: String, CodingKey {
        case character
        case role
        case voiceActors = "voice_actors"
    }
}

public struct CharacterInfo: Decodable, Sendable, Identifiable, Equatable {
    public let id: Int
    public let url: String?
    public let name: String
    public let images: CharacterImages?

    private enum CodingKeys: String, CodingKey {
        case id   = "mal_id"
        case url, name, images
    }
}

public struct CharacterImages: Decodable, Sendable, Equatable {
    public let jpg: ImageURLSet?
    public let webp: ImageURLSet?
}

public struct VoiceActor: Decodable, Sendable, Equatable {
    public let person: PersonInfo
    public let language: String?
}

public struct PersonInfo: Decodable, Sendable, Identifiable, Equatable {
    public let id: Int
    public let url: String?
    public let name: String
    public let images: PersonImages?

    private enum CodingKeys: String, CodingKey {
        case id   = "mal_id"
        case url, name, images
    }
}

public struct PersonImages: Decodable, Sendable, Equatable {
    public let jpg: ImageURLSet?
}

