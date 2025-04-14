import SwiftUI

struct OnboardingSelectionButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: FindyLayout.spacing) {
                Image(systemName: icon)
                    .font(.system(size: FindyLayout.iconSize))
                    .foregroundColor(isSelected ? FindyColors.neonBlue : FindyColors.textSecondary)
                    .frame(width: FindyLayout.iconSize)

                Text(title)
                    .font(FindyTypography.body)
                    .foregroundColor(isSelected ? FindyColors.textPrimary : FindyColors.textSecondary)
                    .lineLimit(1)

                Spacer(minLength: FindyLayout.spacing)
            }
            .padding(.horizontal, FindyLayout.cardPadding)
            .padding(.vertical, FindyLayout.spacing)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(
                RoundedRectangle(cornerRadius: FindyLayout.buttonCornerRadius)
                    .fill(FindyColors.backgroundPrimary)
                    .overlay(
                        RoundedRectangle(cornerRadius: FindyLayout.buttonCornerRadius)
                            .fill(isSelected ? FindyColors.neonBlue.opacity(0.1) : .clear)
                    )
            )
            .overlay(
                RoundedRectangle(cornerRadius: FindyLayout.buttonCornerRadius)
                    .stroke(
                        isSelected ? FindyColors.neonBlue : FindyColors.textSecondary.opacity(0.2),
                        lineWidth: isSelected ? 1.5 : 1
                    )
            )
            .neonGlow(
                color: isSelected ? FindyColors.neonBlue : .clear,
                radius: isSelected ? FindyEffects.softGlow : 0
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        FindyColors.backgroundPrimary.ignoresSafeArea()

        VStack(spacing: FindyLayout.spacing) {
            OnboardingSelectionButton(
                title: "Action",
                icon: "flame.fill",
                isSelected: true
            ) {}

            OnboardingSelectionButton(
                title: "Comedy",
                icon: "face.smiling.fill",
                isSelected: false
            ) {}

            OnboardingSelectionButton(
                title: "Documentary",
                icon: "camera.fill",
                isSelected: false
            ) {}
        }
        .padding()
    }
}
