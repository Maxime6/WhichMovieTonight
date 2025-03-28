import SwiftUI

struct FindyCard<Content: View>: View {
    let content: Content
    var glowColor: Color = FindyColors.neonBlue
    var isInteractive: Bool = false
    @State private var isPressed = false

    init(
        glowColor: Color = FindyColors.neonBlue,
        isInteractive: Bool = false,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.glowColor = glowColor
        self.isInteractive = isInteractive
    }

    var body: some View {
        content
            .padding(FindyLayout.cardPadding)
            .frame(maxWidth: FindyLayout.cardMaxWidth)
            .frame(minHeight: FindyLayout.cardMinHeight)
            .background(
                RoundedRectangle(cornerRadius: FindyLayout.cornerRadius)
                    .fill(Color.white.opacity(FindyEffects.cardOpacity))
                    .background(
                        RoundedRectangle(cornerRadius: FindyLayout.cornerRadius)
                            .fill(.ultraThinMaterial)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: FindyLayout.cornerRadius)
                            .stroke(glowColor.opacity(0.3), lineWidth: 0.5)
                    )
            )
            .neonGlow(
                color: glowColor,
                radius: isPressed ? FindyEffects.softGlow : FindyEffects.neonGlow
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(FindyEffects.cardAppearAnimation, value: isPressed)
            .onTapGesture {
                guard isInteractive else { return }
                withAnimation(FindyEffects.buttonPressAnimation) {
                    isPressed = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        isPressed = false
                    }
                }
            }
    }
}

// MARK: - Preview Provider

struct FindyCard_Previews: PreviewProvider {
    static var previews: some View {
        ZStack {
            Color.black.edgesIgnoringSafeArea(.all)

            FindyCard {
                VStack(alignment: .leading, spacing: FindyLayout.spacing) {
                    Text("Sample Card")
                        .font(FindyTypography.headline)
                        .foregroundColor(FindyColors.textPrimary)

                    Text("This is a preview of how the card looks with some content inside it.")
                        .font(FindyTypography.body)
                        .foregroundColor(FindyColors.textSecondary)
                }
            }
            .padding()
        }
    }
}
