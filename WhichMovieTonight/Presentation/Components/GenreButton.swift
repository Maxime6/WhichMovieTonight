import SwiftUI

struct GenreButton: View {
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
    VStack {
        GenreButton(
            genre: .action,
            isSelected: true,
            action: {}
        )

        GenreButton(
            genre: .comedy,
            isSelected: false,
            action: {}
        )
    }
    .padding()
}
