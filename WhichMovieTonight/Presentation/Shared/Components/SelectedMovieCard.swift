import SwiftUI

struct SelectedMovieCard: View {
    let movie: Movie
    let onTap: () -> Void
    let onDeselect: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            posterView

            VStack(alignment: .leading, spacing: 4) {
                Spacer()
                Text(movie.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .lineLimit(2)

                if !movie.genres.isEmpty {
                    Text(movie.genres.prefix(3).joined(separator: " • "))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                if let year = movie.year {
                    Text(year)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
            }
            .frame(maxHeight: .infinity, alignment: .top)

            Spacer()

            Button(action: onDeselect) {
                Image(systemName: "xmark.circle.fill")
                    .font(.title3)
                    .foregroundColor(.secondary)
            }
            .buttonStyle(PlainButtonStyle())
        }
        .frame(height: 102)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
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
