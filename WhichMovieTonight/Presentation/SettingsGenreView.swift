import SwiftUI

struct GenreSettingsView: View {
    @EnvironmentObject private var preferencesService: UserPreferencesService
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16),
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Gérez vos genres favoris")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Sélectionnez vos genres préférés pour des recommandations adaptées à vos goûts")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(MovieGenre.allCases) { genre in
                        GenreSettingsButton(
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

            Spacer()
        }
        .navigationTitle("Genres favoris")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Terminé") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}

struct GenreSettingsButton: View {
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
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 2)
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    NavigationStack {
        GenreSettingsView()
            .environmentObject(UserPreferencesService())
    }
}
