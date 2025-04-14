import SwiftUI

struct FindyCard<Content: View>: View {
    let glowColor: Color
    let isInteractive: Bool
    let content: () -> Content

    @State private var isPressed: Bool = false

    init(
        glowColor: Color = FindyColors.electricBlue,
        isInteractive: Bool = true,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.glowColor = glowColor
        self.isInteractive = isInteractive
        self.content = content
    }

    var body: some View {
        content()
            .padding(FindyLayout.cardPadding)
            .background(
                ZStack {
                    // Base background with gradient
//                    RoundedRectangle(cornerRadius: FindyLayout.cornerRadius)
//                        .fill(FindyColors.subtleGradient)

                    // Glassmorphism effect
                    RoundedRectangle(cornerRadius: FindyLayout.cornerRadius)
                        .fill(FindyColors.backgroundPrimary)
                        .opacity(0.5)
                        .blur(radius: 0.5)

                    // Border with glow effect
                    RoundedRectangle(cornerRadius: FindyLayout.cornerRadius)
                        .stroke(glowColor, lineWidth: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: FindyLayout.cornerRadius)
                                .stroke(FindyColors.glowGradient, lineWidth: 1)
                        )
                }
            )
            .scaleEffect(isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isPressed)
            .gesture(
                isInteractive ?
                    DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        isPressed = true
                    }
                    .onEnded { _ in
                        isPressed = false
                    }
                    : nil
            )
    }
}

#Preview {
    ZStack {
        Color.black.edgesIgnoringSafeArea(.all)
        
        FindyCard(glowColor: .neonBlue) {
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
