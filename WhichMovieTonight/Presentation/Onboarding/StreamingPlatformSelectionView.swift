import SwiftUI

struct StreamingPlatformSelectionView: View {
    @EnvironmentObject private var preferencesService: UserPreferencesService
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
                            isSelected: preferencesService.isStreamingPlatformSelected(platform),
                            action: {
                                preferencesService.toggleStreamingPlatform(platform)
                            }
                        )
                    }
                }
                .padding()
            }
        }
    }
}

struct StreamingPlatformButton: View {
    let platform: StreamingPlatform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: platform.icon)
                    .font(.system(size: 16))
                Text(platform.rawValue)
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
    StreamingPlatformSelectionView()
        .environmentObject(UserPreferencesService())
}
