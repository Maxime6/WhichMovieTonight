//
//  OMDBService.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 05/05/2025.
//

import Foundation

final class OMDBService {
    private let apiKey = "a8e95e30" // Clé API gratuite OMDB
    private let baseURL = "https://www.omdbapi.com/"

    enum OMDBError: Error {
        case invalidURL
        case noData
        case movieNotFound
        case apiError(String)
    }

    func searchMovie(title: String) async throws -> OMDBSearchResult? {
        guard let url = URL(string: "\(baseURL)?apikey=\(apiKey)&s=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&type=movie") else {
            throw OMDBError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let searchResponse = try JSONDecoder().decode(OMDBSearchResponse.self, from: data)

        if searchResponse.response == "False" {
            if let error = searchResponse.error {
                throw OMDBError.apiError(error)
            }
            throw OMDBError.movieNotFound
        }

        return searchResponse.search?.first
    }

    func getMovieDetails(imdbID: String) async throws -> OMDBMovieDTO {
        guard let url = URL(string: "\(baseURL)?apikey=\(apiKey)&i=\(imdbID)&plot=full") else {
            throw OMDBError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let movieDetails = try JSONDecoder().decode(OMDBMovieDTO.self, from: data)

        if movieDetails.response == "False" {
            if let error = movieDetails.error {
                throw OMDBError.apiError(error)
            }
            throw OMDBError.movieNotFound
        }

        return movieDetails
    }

    func getMovieDetailsByTitle(title: String) async throws -> OMDBMovieDTO {
        guard let url = URL(string: "\(baseURL)?apikey=\(apiKey)&t=\(title.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&plot=full") else {
            throw OMDBError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 15.0 // Timeout de 15 secondes pour OMDB

        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let movieDetails = try JSONDecoder().decode(OMDBMovieDTO.self, from: data)

            if movieDetails.response == "False" {
                if let error = movieDetails.error {
                    throw OMDBError.apiError(error)
                }
                throw OMDBError.movieNotFound
            }

            return movieDetails
        } catch {
            print("OMDB request failed: \(error)")
            throw error
        }
    }
}
