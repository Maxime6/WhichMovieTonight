import FirebaseAuth
import SwiftUI

struct StreamingPlatformSelectionView: View {
    @EnvironmentObject private var userProfileService: UserProfileService
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16),
    ]

    var body: some View {
        VStack(spacing: 24) {
            Text("Sélectionnez vos plateformes de streaming")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top)

            Text("Choisissez au moins une plateforme pour recevoir des recommandations personnalisées")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(StreamingPlatform.allCases) { platform in
                        StreamingPlatformButton(
                            platform: platform,
                            isSelected: userProfileService.isStreamingPlatformSelected(platform),
                            action: {
                                Task {
                                    guard let userId = Auth.auth().currentUser?.uid else { return }
                                    await userProfileService.toggleStreamingPlatform(platform, userId: userId)
                                }
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    StreamingPlatformSelectionView()
        .environmentObject(UserProfileService())
}
