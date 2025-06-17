import SwiftUI

struct StreamingPlatformSettingsView: View {
    @EnvironmentObject private var preferencesService: UserPreferencesService
    @Environment(\.dismiss) private var dismiss

    private let columns = [
        GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16),
    ]

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Gérez vos plateformes de streaming")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Sélectionnez les services auxquels vous avez accès pour des recommandations personnalisées")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top)

            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(StreamingPlatform.allCases) { platform in
                        StreamingPlatformButton(
                            platform: platform,
                            isSelected: preferencesService.isStreamingPlatformSelected(platform),
                            action: {
                                preferencesService.toggleStreamingPlatform(platform)
                            }
                        )
                    }
                }
                .padding()
            }

            Spacer()
        }
        .navigationTitle("Plateformes de streaming")
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

#Preview {
    NavigationStack {
        StreamingPlatformSettingsView()
            .environmentObject(UserPreferencesService())
    }
}
