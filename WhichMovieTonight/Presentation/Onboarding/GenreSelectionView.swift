import SwiftUI

struct GenreSelectionView: View {
    @StateObject private var preferencesService = UserPreferencesService()
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16),
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("Sélectionnez vos genres préférés")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top)

            Text("Ces préférences nous aideront à vous suggérer des films adaptés à vos goûts")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(MovieGenre.allCases) { genre in
                        GenreButton(
                            genre: genre,
                            isSelected: preferencesService.isGenreSelected(genre),
                            action: {
                                preferencesService.toggleGenre(genre)
                            }
                        )
                    }
                }
                .padding()
            }
            
            AIActionButton(title: "Continuer") {
                dismiss()
            }
        }
    }
}

struct GenreButton: View {
    let genre: MovieGenre
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: genre.icon)
                    .font(.system(size: 16))
                Text(genre.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
            .foregroundColor(isSelected ? .white : .primary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.cyan.gradient : Color.gray.opacity(0.1).gradient)
            .cornerRadius(8)
        }
    }
}

#Preview {
    GenreSelectionView()
}
