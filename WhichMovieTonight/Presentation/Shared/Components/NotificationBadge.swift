import SwiftUI

struct NotificationBadge: View {
    let unreadCount: Int
    let onTap: () -> Void

    @State private var isPressed = false
    @State private var badgePulse = false

    var body: some View {
        Button(action: onTap) {
            ZStack {
                // Bell icon
                Image(systemName: "bell.fill")
                    .font(.title2)
                    .foregroundColor(.primary)

                // Badge with count
                if unreadCount > 0 {
                    ZStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 20, height: 20)
                            .scaleEffect(badgePulse ? 1.1 : 1.0)

                        Text(unreadCount > 99 ? "99+" : "\(unreadCount)")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .minimumScaleFactor(0.6)
                    }
                    .offset(x: 12, y: -12)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onReceive(NotificationCenter.default.publisher(for: .newNotificationReceived)) { _ in
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                badgePulse = true
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                    badgePulse = false
                }
            }
        }
        .scaleEffect(isPressed ? 0.9 : 1.0)
    }
}

// MARK: - Notification Names

#Preview {
    VStack(spacing: 20) {
        NotificationBadge(unreadCount: 0, onTap: {})

        NotificationBadge(unreadCount: 3, onTap: {})

        NotificationBadge(unreadCount: 99, onTap: {})

        NotificationBadge(unreadCount: 100, onTap: {})
    }
    .padding()
}
