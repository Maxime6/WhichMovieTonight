import FirebaseAuth
import SwiftUI

struct ActorSelectionView: View {
    @EnvironmentObject private var userProfileService: UserProfileService
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
                        ForEach(userProfileService.favoriteActors, id: \.self) { actor in
                            ActorChip(actor: actor) {
                                Task {
                                    guard let userId = Auth.auth().currentUser?.uid else { return }
                                    await userProfileService.removeActor(actor, userId: userId)
                                }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .dismissKeyboardOnTap()
        .alert("Acteur déjà ajouté", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
    }

    private func addActor() {
        let trimmedActor = actorInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedActor.isEmpty else { return }

        if userProfileService.favoriteActors.contains(trimmedActor) {
            alertMessage = "Cet acteur est déjà dans vos favoris"
            showingAlert = true
        } else {
            Task {
                guard let userId = Auth.auth().currentUser?.uid else { return }
                await userProfileService.addActor(trimmedActor, userId: userId)
            }
            actorInput = ""
        }
    }
}

#Preview {
    ActorSelectionView()
        .environmentObject(UserProfileService())
}
