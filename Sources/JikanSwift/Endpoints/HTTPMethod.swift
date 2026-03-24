//
//  HTTPMethod.swift
//  JikanSwift
//
//  Created by Никита Гузарский on 07.03.2026.
//

import Foundation

/// HTTP methods supported by the client.
public enum HTTPMethod: String {
    case get    = "GET"
    case post   = "POST"
    case put    = "PUT"
    case patch  = "PATCH"
    case delete = "DELETE"
}

