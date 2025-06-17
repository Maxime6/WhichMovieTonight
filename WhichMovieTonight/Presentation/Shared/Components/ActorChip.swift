import SwiftUI

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
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    VStack {
        ActorChip(actor: "Leonardo DiCaprio") {}
        ActorChip(actor: "Scarlett Johansson") {}
    }
    .padding()
}
