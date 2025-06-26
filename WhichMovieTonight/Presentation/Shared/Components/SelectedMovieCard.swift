import SwiftUI

struct SelectedMovieCard: View {
    let movie: Movie
    let onTap: () -> Void
    let onDeselect: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // Movie Poster (small, on the left)
            posterView

            // Movie Info
            VStack(alignment: .leading, spacing: 4) {
                Text(movie.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                // Genres
                if !movie.genres.isEmpty {
                    Text(movie.genres.prefix(3).joined(separator: " • "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }

                // Year
                if let year = movie.year {
                    Text(year)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }

            Spacer()

            // Deselect button
            Button(action: onDeselect) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThickMaterial)
                .shadow(color: .primary.opacity(0.1), radius: 4, x: 0, y: 2)
        )
        .onTapGesture {
            onTap()
        }
    }

    @ViewBuilder
    private var posterView: some View {
        if let url = movie.posterURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    ProgressView()
                        .frame(width: 60, height: 90)
                        .background(Color.gray.opacity(0.2))
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                case let .success(image):
                    image
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 90)
                        .clipShape(RoundedRectangle(cornerRadius: 8))

                case .failure:
                    posterPlaceholder

                @unknown default:
                    posterPlaceholder
                }
            }
        } else {
            posterPlaceholder
        }
    }

    private var posterPlaceholder: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(.gray.opacity(0.2))
            .frame(width: 60, height: 90)
            .overlay {
                Image(systemName: "film")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundStyle(.secondary)
            }
    }
}

#Preview {
    VStack(spacing: 16) {
        SelectedMovieCard(
            movie: Movie.preview,
            onTap: { print("Tapped") },
            onDeselect: { print("Deselected") }
        )

        Text("No film selected for tonight")
            .font(.subheadline)
            .foregroundColor(.secondary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(.ultraThinMaterial)
                    .stroke(.secondary.opacity(0.3), lineWidth: 1)
            )
    }
    .padding()
}
