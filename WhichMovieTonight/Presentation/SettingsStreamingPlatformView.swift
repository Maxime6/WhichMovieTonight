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
                        StreamingPlatformSettingsButton(
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

struct StreamingPlatformSettingsButton: View {
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
        StreamingPlatformSettingsView()
            .environmentObject(UserPreferencesService())
    }
}
