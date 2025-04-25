//
//  HomeViewModel.swift
//  WichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var userName: String = "Maxime"
    @Published var selectedMovie: Movie?
    
    func fetchUser() {
        userName = "Maxime"
    }
    
    func findTonightMovie() async throws {
        try await Task.sleep(for: .seconds(2))
        selectedMovie = MockMovie.sample
    }
}
