import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel: HomeViewModel
    @State private var showingMovieDetails = false

    init(nickname: String, currentMood: Mood) {
        _viewModel = StateObject(wrappedValue: HomeViewModel(nickname: nickname, currentMood: currentMood))
    }

    var body: some View {
        ZStack {
            // Background
            FindyColors.backgroundPrimary
                .ignoresSafeArea()

            // Content
            ScrollView {
                VStack(spacing: FindyLayout.largeSpacing) {
                    // Welcome header
                    welcomeHeader

                    // Main recommendation
                    if let mainMovie = viewModel.mainRecommendation {
                        VStack(alignment: .leading, spacing: FindyLayout.spacing) {
                            Text("Today's Pick for You")
                                .font(FindyTypography.title)
                                .foregroundColor(FindyColors.textPrimary)
                                .neonGlow()

                            MovieCard(
                                movie: mainMovie,
                                isMainCard: true
                            ) {
                                viewModel.selectedMovie = mainMovie
                                showingMovieDetails = true
                            }
                        }
                    }

                    // Alternative recommendations
                    if !viewModel.alternativeRecommendations.isEmpty {
                        VStack(alignment: .leading, spacing: FindyLayout.spacing) {
                            Text("Other Matches")
                                .font(FindyTypography.headline)
                                .foregroundColor(FindyColors.textPrimary)

                            VStack(spacing: FindyLayout.spacing) {
                                ForEach(viewModel.alternativeRecommendations) { movie in
                                    MovieCard(
                                        movie: movie,
                                        isMainCard: false
                                    ) {
                                        viewModel.selectedMovie = movie
                                        showingMovieDetails = true
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .refreshable {
                await viewModel.refreshRecommendations()
            }
        }
        .sheet(isPresented: $showingMovieDetails) {
            if let selectedMovie = viewModel.selectedMovie {
                MovieDetailsView(movie: selectedMovie)
            }
        }
    }

    private var welcomeHeader: some View {
        VStack(spacing: FindyLayout.spacing) {
            // Greeting
            Text("Hey \(viewModel.nickname)! 👋")
                .font(FindyTypography.largeTitle)
                .foregroundColor(FindyColors.textPrimary)
                .neonGlow()

            // Mood indicator
            HStack {
                Image(systemName: viewModel.currentMood.icon)
                    .font(.system(size: FindyLayout.iconSize))
                Text("You're feeling \(viewModel.currentMood.rawValue.lowercased())")
                    .font(FindyTypography.body)
            }
            .foregroundColor(FindyColors.textSecondary)
        }
    }
}

// MARK: - Movie Details View

struct MovieDetailsView: View {
    let movie: Movie
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ZStack {
            FindyColors.backgroundPrimary
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: FindyLayout.largeSpacing) {
                    // TODO: Add movie poster/backdrop image

                    VStack(alignment: .leading, spacing: FindyLayout.spacing) {
                        // Title and year
                        Text(movie.title)
                            .font(FindyTypography.title)
                            .foregroundColor(FindyColors.textPrimary)
                            + Text(" (\(movie.formattedReleaseYear))")
                            .font(FindyTypography.headline)
                            .foregroundColor(FindyColors.textSecondary)

                        // Movie details
                        HStack(spacing: FindyLayout.largeSpacing) {
                            Label(
                                String(format: "%.1f", movie.rating),
                                systemImage: "star.fill"
                            )
                            .foregroundColor(.yellow)

                            Label(
                                movie.formattedRuntime,
                                systemImage: "clock.fill"
                            )
                            .foregroundColor(FindyColors.textSecondary)

                            Label(
                                "\(movie.matchPercentage)% Match",
                                systemImage: "checkmark.circle.fill"
                            )
                            .foregroundColor(FindyColors.neonBlue)
                        }
                        .font(FindyTypography.body)

                        // Genres
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(movie.genres, id: \.self) { genre in
                                    Text(genre.rawValue)
                                        .font(FindyTypography.caption)
                                        .foregroundColor(FindyColors.textSecondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            RoundedRectangle(cornerRadius: 8)
                                                .fill(Color.white.opacity(0.1))
                                        )
                                }
                            }
                        }

                        // Overview
                        Text("Overview")
                            .font(FindyTypography.headline)
                            .foregroundColor(FindyColors.textPrimary)

                        Text(movie.overview)
                            .font(FindyTypography.body)
                            .foregroundColor(FindyColors.textSecondary)

                        // Available on
                        if !movie.streamingPlatforms.isEmpty {
                            Text("Available on")
                                .font(FindyTypography.headline)
                                .foregroundColor(FindyColors.textPrimary)

                            HStack(spacing: FindyLayout.spacing) {
                                ForEach(movie.streamingPlatforms, id: \.self) { platform in
                                    Label(
                                        platform.rawValue,
                                        systemImage: platform.icon
                                    )
                                    .font(FindyTypography.body)
                                    .foregroundColor(FindyColors.textSecondary)
                                }
                            }
                        }
                    }
                }
                .padding()
            }

            // Close button
            VStack {
                HStack {
                    Spacer()

                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 32))
                            .foregroundColor(FindyColors.textSecondary)
                    }
                    .padding()
                }

                Spacer()
            }
        }
    }
}

#Preview {
    HomeView(nickname: "John", currentMood: .happy)
}
