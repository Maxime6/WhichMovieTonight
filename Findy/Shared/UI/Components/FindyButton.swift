import SwiftUI

struct FindyButton: View {
    let title: String
    let action: () -> Void
    let style: ButtonStyle
    @State private var isPressed = false

    enum ButtonStyle {
        case primary
        case secondary
        case ghost
    }

    init(
        _ title: String,
        style: ButtonStyle = .primary,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.style = style
        self.action = action
    }

    var body: some View {
        Button(action: {
            withAnimation(FindyEffects.buttonPressAnimation) {
                isPressed = true
                action()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isPressed = false
                }
            }
        }) {
            Text(title)
                .font(FindyTypography.headline)
                .foregroundColor(foregroundColor)
                .frame(maxWidth: .infinity)
                .frame(height: FindyLayout.buttonHeight)
                .background(backgroundView)
                .cornerRadius(FindyLayout.buttonCornerRadius)
                .overlay(
                    RoundedRectangle(cornerRadius: FindyLayout.buttonCornerRadius)
                        .stroke(borderColor, lineWidth: isPressed ? 2 : 1)
                )
                .neonGlow(color: glowColor, radius: isPressed ? FindyEffects.softGlow : FindyEffects.neonGlow)
                .scaleEffect(isPressed ? 0.98 : 1.0)
        }
    }

    private var foregroundColor: Color {
        switch style {
        case .primary, .secondary:
            return FindyColors.textPrimary
        case .ghost:
            return FindyColors.electricBlue
        }
    }

    private var glowColor: Color {
        switch style {
        case .primary:
            return FindyColors.electricBlue
        case .secondary:
            return FindyColors.neonPurple
        case .ghost:
            return .clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return FindyColors.electricBlue
        case .secondary:
            return FindyColors.neonPurple
        case .ghost:
            return FindyColors.electricBlue.opacity(0.5)
        }
    }

    @ViewBuilder
    private var backgroundView: some View {
        switch style {
        case .primary:
            FindyColors.primaryGradient
        case .secondary:
            FindyColors.subtleGradient
        case .ghost:
            Color.clear
        }
    }
}
