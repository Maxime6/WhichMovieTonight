//
//  MovieCardView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct MovieCardView: View {
    @Environment(\.colorScheme) var colorScheme

    let movie: Movie
    let namespace: Namespace.ID?
    let onPosterTap: (() -> Void)?

    init(movie: Movie, namespace: Namespace.ID? = nil, onPosterTap: (() -> Void)? = nil) {
        self.movie = movie
        self.namespace = namespace
        self.onPosterTap = onPosterTap
    }

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 8) {
                posterView(geometry: geometry)

                VStack(spacing: 6) {
                    Text(movie.title)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)

                    // Genres
                    if !movie.genres.isEmpty {
                        Text(movie.genres.prefix(2).joined(separator: " • "))
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Rating
                    if let ratingString = movie.imdbRating,
                       let rating = Double(ratingString),
                       rating > 0
                    {
                        HStack(spacing: 4) {
                            Image(systemName: "star.fill")
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .font(.caption)
                            Text(String(format: "%.1f", rating))
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.primary)
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
        }
    }

    @ViewBuilder
    private func posterView(geometry: GeometryProxy) -> some View {
        let posterHeight = geometry.size.height * 0.7 // Plus grand pourcentage pour l'affiche
        let posterWidth = posterHeight * 0.67 // Aspect ratio 2:3

        if let url = movie.posterURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: posterWidth, height: posterHeight)
                case let .success(image):
                    Button(action: {
                        onPosterTap?()
                    }) {
                        image
                            .resizable()
                            .scaledToFill()
                            .frame(width: posterWidth, height: posterHeight)
                            .clipShape(RoundedRectangle(cornerRadius: DesignSystem.mediumRadius))
                            .overlay(
                                // Subtle gradient overlay
                                RoundedRectangle(cornerRadius: DesignSystem.mediumRadius)
                                    .fill(
                                        LinearGradient(
                                            colors: [
                                                .clear,
                                                .black.opacity(0.1),
                                                .black.opacity(0.2),
                                            ],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                            )
                            .primaryShadow()
                    }
                    .buttonStyle(PlainButtonStyle())
                    .if(namespace != nil) { view in
                        view.matchedGeometryEffect(id: "moviePoster-\(movie.id)", in: namespace!, isSource: false)
                    }
                case .failure:
                    placeHolderPoster(width: posterWidth, height: posterHeight)
                @unknown default:
                    placeHolderPoster(width: posterWidth, height: posterHeight)
                }
            }
        } else {
            placeHolderPoster(width: posterWidth, height: posterHeight)
        }
    }

    private func placeHolderPoster(width: CGFloat, height: CGFloat) -> some View {
        Button(action: {
            onPosterTap?()
        }) {
            RoundedRectangle(cornerRadius: DesignSystem.largeRadius)
                .fill(.gray.opacity(0.2))
                .frame(width: width, height: height)
                .overlay {
                    Image(systemName: "film")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .foregroundStyle(DesignSystem.primaryGradient)
                }
                .subtleShadow()
        }
        .buttonStyle(PlainButtonStyle())
        .if(namespace != nil) { view in
            view.matchedGeometryEffect(id: "moviePoster-placeholder", in: namespace!, isSource: false)
        }
    }

    private var genreTags: some View {
        HStack(spacing: 8) {
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

                    .shadow(color: .cyan.opacity(0.3), radius: 2, x: 2, y: 2)
            }
        }
    }
}

#Preview {
    MovieCardView(movie: Movie.preview)
}

struct StreamingPlatformLogoView: View {
    let platform: StreamingPlatform

    var body: some View {
        Image(platform.icon)
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

struct WrapHStack<Content: View>: View {
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: () -> Content

    init(spacing: CGFloat = 8, alignment: HorizontalAlignment = .leading, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        /// Flow layout from SwiftUI-Introspect or custom
        /// Using a LazyVgrid for now
        FlowLayout(spacing: spacing, alignment: alignment, content: content)
    }
}

// Extension to conditionally apply modifiers
extension View {
    @ViewBuilder func `if`<Content: View>(_ condition: Bool, transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }
}
