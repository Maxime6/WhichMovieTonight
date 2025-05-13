//
//  MovieSuggestionDTO.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 02/05/2025.
//

import Foundation

struct MovieSuggestionDTO: Codable {
    let title: String
    let genres: [String]
    let posterUrl: String
    let platforms: [String]
    
    enum Codingkeys: String, CodingKey {
        case title
        case genres
        case posterUrl = "poster_url"
        case platforms
    }
}

struct OpenAIMovieDTO: Decodable {
    let title: String
    let genres: [String]
    let posterUrl: String
    let platforms: [String]

    enum CodingKeys: String, CodingKey {
        case title
        case genres
        case posterUrl = "poster_url"
        case platforms
    }
}
