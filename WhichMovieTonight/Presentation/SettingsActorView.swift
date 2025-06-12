import SwiftUI

struct ActorSettingsView: View {
    @EnvironmentObject private var preferencesService: UserPreferencesService
    @Environment(\.dismiss) private var dismiss

    @State private var actorInput: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 12) {
                Text("Gérez vos acteurs favoris")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text("Ajoutez ou supprimez vos acteurs préférés pour des recommandations personnalisées")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            .padding(.top)

            VStack(spacing: 16) {
                HStack {
                    TextField("Nom de l'acteur", text: $actorInput)
                        .textFieldStyle(.roundedBorder)
                        .autocapitalization(.words)

                    Button {
                        addActor()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.cyan.gradient)
                    }
                    .disabled(actorInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                .padding(.horizontal)

                if preferencesService.favoriteActors.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "person.2")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary)

                        Text("Aucun acteur ajouté")
                            .font(.headline)
                            .foregroundColor(.secondary)

                        Text("Ajoutez vos acteurs préférés pour des recommandations personnalisées")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)], spacing: 16) {
                            ForEach(preferencesService.favoriteActors, id: \.self) { actor in
                                ActorSettingsChip(actor: actor) {
                                    preferencesService.removeActor(actor)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }

            Spacer()
        }
        .navigationTitle("Acteurs favoris")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Terminé") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
        .alert("Acteur déjà ajouté", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func addActor() {
        let trimmedActor = actorInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedActor.isEmpty else { return }

        if preferencesService.favoriteActors.contains(trimmedActor) {
            alertMessage = "Cet acteur est déjà dans vos favoris"
            showingAlert = true
        } else {
            preferencesService.addActor(trimmedActor)
            actorInput = ""
        }
    }
}

struct ActorSettingsChip: View {
    let actor: String
    let onRemove: () -> Void

    var body: some View {
        HStack {
            Text(actor)
                .font(.subheadline)
                .fontWeight(.medium)

            Button {
                onRemove()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.gray)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    NavigationStack {
        ActorSettingsView()
            .environmentObject(UserPreferencesService())
    }
}
