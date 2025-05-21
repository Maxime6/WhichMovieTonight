import SwiftUI

struct ActorSelectionView: View {
    @StateObject private var preferencesService = UserPreferencesService()
    @Environment(\.dismiss) private var dismiss

    @State private var actorInput: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""

    var body: some View {
        VStack(spacing: 24) {
            Text("Ajoutez vos acteurs préférés")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .padding(.top)

            Text("Ces préférences nous aideront à vous suggérer des films avec vos acteurs préférés")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

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
                }
                .padding(.horizontal)

                ScrollView {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 150, maximum: 200), spacing: 16)], spacing: 16) {
                        ForEach(preferencesService.favoriteActors, id: \.self) { actor in
                            ActorChip(actor: actor) {
                                preferencesService.removeActor(actor)
                            }
                        }
                    }
                    .padding()
                }
            }

            AIActionButton(title: "Continuer") {
                dismiss()
            }
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

struct ActorChip: View {
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
    }
}

#Preview {
    ActorSelectionView()
}
