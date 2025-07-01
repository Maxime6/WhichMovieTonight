import SwiftUI

struct StreamingPlatformButton: View {
    let platform: StreamingPlatform
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: platform.icon)
                    .font(.system(size: 16))
                    .padding(.leading, 15)
                Spacer()
                Text(platform.rawValue)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            .foregroundColor(isSelected ? .cyan : .secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.black : Color.gray)
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.cyan : Color.clear, lineWidth: 1)
            )
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

#Preview {
    VStack {
        StreamingPlatformButton(
            platform: .netflix,
            isSelected: true,
            action: {}
        )

        StreamingPlatformButton(
            platform: .primeVideo,
            isSelected: false,
            action: {}
        )
    }
    .padding()
}
