import SwiftUI

struct NotificationPanel: View {
    @Binding var isPresented: Bool
    let notifications: [AppNotification]
    let onMarkAsRead: (String) -> Void
    let onMarkAllAsRead: () -> Void
    let onDeleteNotification: (String) -> Void

    @State private var dragOffset: CGSize = .zero

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background overlay
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        dismissPanel()
                    }

                // Notification panel
                VStack(spacing: 0) {
                    notificationContent(screenHeight: geometry.size.height)

                    Spacer()
                }
                .offset(y: 0)
                .offset(y: dragOffset.height)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.height < 0 {
                                dragOffset = CGSize(width: 0, height: value.translation.height * 0.3)
                            } else {
                                dragOffset = value.translation
                            }
                        }
                        .onEnded { value in
                            if value.translation.height > 100 {
                                dismissPanel()
                            } else {
                                withAnimation(.spring()) {
                                    dragOffset = .zero
                                }
                            }
                        }
                )
            }
        }
        // Animation is now handled by the parent view with transitions
    }

    private func notificationContent(screenHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Drag indicator
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 40, height: 6)
                .padding(.top, 8)

            // Header
            HStack {
                Text("Notifications")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                if !notifications.filter({ !$0.isRead }).isEmpty {
                    Button("Mark all read") {
                        onMarkAllAsRead()
                    }
                    .font(.caption)
                    .foregroundColor(.blue)
                }

                Button(action: dismissPanel) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 8)

            Divider()

            // Notifications list
            if notifications.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(notifications) { notification in
                            NotificationRow(
                                notification: notification,
                                onMarkAsRead: { onMarkAsRead(notification.id) },
                                onDelete: { onDeleteNotification(notification.id) }
                            )
                            .transition(.slide)
                        }
                    }
                }
            }
        }
        .frame(height: screenHeight / 3)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .clipped()
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "bell.slash")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("No notifications")
                .font(.headline)
                .foregroundColor(.primary)

            Text("You're all caught up!")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func dismissPanel() {
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            isPresented = false
        }
        dragOffset = .zero
    }
}

// MARK: - Notification Row

struct NotificationRow: View {
    let notification: AppNotification
    let onMarkAsRead: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(Color(notification.type.color).opacity(0.2))
                    .frame(width: 40, height: 40)

                Image(systemName: notification.type.iconName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(notification.type.color))
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notification.title)
                        .font(.subheadline)
                        .fontWeight(notification.isRead ? .medium : .semibold)
                        .foregroundColor(.primary)
                        .lineLimit(2)

                    Spacer()

                    if !notification.isRead {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                    }
                }

                Text(notification.message)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(3)

                HStack {
                    Text(notification.timeAgo)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Spacer()
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(notification.isRead ? Color.clear : Color.blue.opacity(0.05))
        .onTapGesture {
            if !notification.isRead {
                onMarkAsRead()
            }
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button("Delete", role: .destructive) {
                onDelete()
            }

            if !notification.isRead {
                Button("Mark Read") {
                    onMarkAsRead()
                }
                .tint(.blue)
            }
        }
    }
}

#Preview {
    @State var isPresented = true

    let sampleNotifications = [
        AppNotification(
            userId: "user1",
            type: .dailyRecommendations,
            title: "🎬 Your daily picks are ready!",
            message: "Discover 5 new movies selected just for you"
        ),
        AppNotification(
            userId: "user1",
            type: .movieWatchConfirmation,
            title: "Did you watch Inception?",
            message: "Let us know if you enjoyed your movie selection!"
        ),
    ]

    return NotificationPanel(
        isPresented: $isPresented,
        notifications: sampleNotifications,
        onMarkAsRead: { _ in },
        onMarkAllAsRead: {},
        onDeleteNotification: { _ in }
    )
}
