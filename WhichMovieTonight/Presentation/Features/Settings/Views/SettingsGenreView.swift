import FirebaseAuth
import SwiftUI

struct GenreSettingsView: View {
    @EnvironmentObject private var userProfileService: UserProfileService
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
                        GenreButton(
                            genre: genre,
                            isSelected: userProfileService.isGenreSelected(genre),
                            action: {
                                Task {
                                    guard let userId = Auth.auth().currentUser?.uid else { return }
                                    await userProfileService.toggleGenre(genre, userId: userId)
                                }
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
    }
}

#Preview {
    NavigationStack {
        GenreSettingsView()
            .environmentObject(UserProfileService())
    }
}
