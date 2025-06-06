//
//  MovieDetailSheet.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct MovieDetailSheet: View {
    let movie: Movie
    let namespace: Namespace.ID
    @Binding var isPresented: Bool
    let source: MovieDetailSource
    let onSelectForTonight: (() -> Void)?
    @State private var scrollOffset: CGFloat = 0
    @State var counter: Int = 0
    @State var origin: CGPoint = .zero

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 0) {
                    // Hero poster section
                    heroSection

                    // Movie details
                    movieDetailsSection
                }
            }
            .background(Color(.systemBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Fermer") {
                        isPresented = false
                    }
                }

                if source == .suggestion {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Choisir pour ce soir") {
                            onSelectForTonight?()
                        }
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                    }
                }
            }
        }
    }

    private var heroSection: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [Color.black.opacity(0.6), Color.clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 300)

            VStack(spacing: 16) {
                // Hero poster with matched geometry
                if let url = movie.posterURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 160, height: 240)
                        case let .success(image):
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(width: 160, height: 240)
                                .cornerRadius(16)
                                .shadow(color: .black.opacity(0.3), radius: 10)
                                .onPressingChanged { point in
                                    if let point {
                                        origin = point
                                        counter += 1
                                    }
                                }
                                .modifier(RippleEffect(at: origin, trigger: counter))
                                .matchedGeometryEffect(id: "moviePoster-\(movie.id)", in: namespace, isSource: false)
                        case .failure:
                            posterPlaceholder
                                .matchedGeometryEffect(id: "moviePoster-placeholder", in: namespace, isSource: false)
                        @unknown default:
                            posterPlaceholder
                                .matchedGeometryEffect(id: "moviePoster-placeholder", in: namespace, isSource: false)
                        }
                    }
                } else {
                    posterPlaceholder
                        .matchedGeometryEffect(id: "moviePoster-placeholder", in: namespace, isSource: false)
                }

                // Movie title
                Text(movie.title)
                    .font(.title.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.5), radius: 2)
                    .padding(.horizontal)
            }
            .padding(.bottom, 24)
        }
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.gray.opacity(0.2))
            .frame(width: 160, height: 240)
            .overlay {
                Image(systemName: "film")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.secondary)
            }
    }

    private var movieDetailsSection: some View {
        VStack(spacing: 24) {
            // Quick info row
            quickInfoRow

            // Movie interaction buttons (like, dislike, favorite)
            MovieInteractionButtons(movie: movie)

            // Genres
            genresSection

            // Synopsis
            synopsisSection

            // Cast & Crew
            castCrewSection

            // Streaming platforms (if available)
            streamingSection

            // Select for tonight button (only from suggestions)
            if source == .suggestion {
                selectForTonightButton
            }
        }
        .padding()
    }

    private var quickInfoRow: some View {
        VStack(spacing: 16) {
            // Rating and basic info
            HStack(spacing: 20) {
                if let imdbRating = movie.imdbRating {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.title3)
                            Text(imdbRating)
                                .font(.title3.bold())
                        }
                        Text("IMDb")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let year = movie.year {
                    VStack(spacing: 4) {
                        Text(year)
                            .font(.title3.bold())
                        Text("Année")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let rated = movie.rated {
                    VStack(spacing: 4) {
                        Text(rated)
                            .font(.title3.bold())
                        Text("Classification")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                if let runtime = movie.runtime {
                    VStack(spacing: 4) {
                        Text(runtime)
                            .font(.title3.bold())
                        Text("Durée")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }

    private var genresSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Genres")
                    .font(.headline)
                Spacer()
            }

            FlowLayout(spacing: 8) {
                ForEach(movie.genres, id: \.self) { genre in
                    Text(genre)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .overlay {
                            Capsule()
                                .stroke(.primary.opacity(0.1))
                        }
                }
            }
        }
    }

    private var synopsisSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Synopsis")
                    .font(.headline)
                Spacer()
            }

            if let overview = movie.overview {
                Text(overview)
                    .font(.body)
                    .foregroundColor(.secondary)
                    .lineSpacing(4)
            } else {
                Text("Aucun synopsis disponible")
                    .font(.body)
                    .foregroundStyle(.tertiary)
                    .italic()
            }
        }
    }

    private var castCrewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let director = movie.director {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Réalisateur")
                        .font(.headline)
                    Text(director)
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }

            if let actors = movie.actors {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Acteurs principaux")
                        .font(.headline)
                    Text(actors)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(2)
                }
            }
        }
    }

    private var streamingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Disponible sur")
                    .font(.headline)
                Spacer()
            }

            // Placeholder for streaming platforms
            // This would need to be implemented based on your streaming data model
            HStack(spacing: 12) {
                ForEach(["Netflix", "Prime Video", "Apple TV+"], id: \.self) { platform in
                    Text(platform)
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.blue.opacity(0.1))
                        .foregroundColor(.blue)
                        .cornerRadius(8)
                }
            }
        }
    }

    private var selectForTonightButton: some View {
        VStack(spacing: 16) {
            Divider()
                .padding(.vertical)

            Button(action: {
                onSelectForTonight?()
            }) {
                HStack {
                    Image(systemName: "star.fill")
                    Text("Choisir pour ce soir")
                        .fontWeight(.semibold)
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.blue)
                .cornerRadius(12)
            }

            Text("Ce film deviendra votre film du soir")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview {
    @Namespace var namespace
    return MovieDetailSheet(
        movie: Movie.preview,
        namespace: namespace,
        isPresented: .constant(true),
        source: .suggestion,
        onSelectForTonight: {
            print("Selected for tonight!")
        }
    )
}
