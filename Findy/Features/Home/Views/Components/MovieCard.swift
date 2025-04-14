import SwiftUI

struct MovieCard: View {
    let movie: Movie
    let isMainCard: Bool
    let action: () -> Void

    var body: some View {
        FindyCard(
            glowColor: isMainCard ? FindyColors.electricBlue : FindyColors.neonBlue,
            isInteractive: true
        ) {
            VStack(alignment: .leading, spacing: FindyLayout.spacing) {
                // Header with match percentage
                HStack {
                    Text("\(movie.matchPercentage)% Match")
                        .font(FindyTypography.caption)
                        .foregroundColor(FindyColors.neonCyan)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .stroke(FindyColors.neonCyan, lineWidth: 1)
                        )

                    Spacer()

                    // Streaming platforms
                    HStack(spacing: 8) {
                        ForEach(movie.streamingPlatforms, id: \.self) { platform in
                            Image(systemName: platform.icon)
                                .font(.system(size: 16))
                                .foregroundColor(FindyColors.textSecondary)
                        }
                    }
                }

                if isMainCard {
                    // Title and year
                    Text(movie.title)
                        .font(FindyTypography.headline)
                        .foregroundColor(FindyColors.textPrimary)
                        + Text(" (\(movie.formattedReleaseYear))")
                        .font(FindyTypography.body)
                        .foregroundColor(FindyColors.textSecondary)

                    // Overview
                    Text(movie.overview)
                        .font(FindyTypography.body)
                        .foregroundColor(FindyColors.textSecondary)
                        .lineLimit(3)

                    // Movie details
                    HStack(spacing: FindyLayout.spacing) {
                        // Rating
                        Label(
                            String(format: "%.1f", movie.rating),
                            systemImage: "star.fill"
                        )
                        .foregroundColor(FindyColors.warning)

                        // Runtime
                        Label(
                            movie.formattedRuntime,
                            systemImage: "clock.fill"
                        )
                        .foregroundColor(FindyColors.textSecondary)
                    }
                    .font(FindyTypography.caption)

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
                                            .fill(FindyColors.backgroundSecondary)
                                    )
                            }
                        }
                    }
                } else {
                    // Compact view for alternative recommendations
                    VStack(alignment: .leading, spacing: FindyLayout.spacing) {
                        Text(movie.title)
                            .font(FindyTypography.headline)
                            .foregroundColor(FindyColors.textPrimary)

                        HStack {
                            Label(
                                String(format: "%.1f", movie.rating),
                                systemImage: "star.fill"
                            )
                            .foregroundColor(FindyColors.warning)
                            .font(FindyTypography.caption)

                            Text("•")
                                .foregroundColor(FindyColors.textSecondary)

                            Text(movie.formattedRuntime)
                                .font(FindyTypography.caption)
                                .foregroundColor(FindyColors.textSecondary)
                        }
                    }
                }
            }
        }
        .onTapGesture(perform: action)
    }
}

#Preview {
    ZStack {
        FindyColors.backgroundPrimary.ignoresSafeArea()

        VStack(spacing: FindyLayout.spacing) {
            MovieCard(movie: .preview, isMainCard: true) {}
            MovieCard(movie: .preview, isMainCard: false) {}
        }
        .padding()
    }
}
