//
//  EmptyStateView.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 31/12/2024.
//

import SwiftUI

struct EmptyStateView: View {
    let icon: String
    let title: String
    let subtitle: String
    let actionTitle: String?
    let actionIcon: String?
    let onAction: (() -> Void)?
    let showSparkles: Bool

    init(
        icon: String,
        title: String,
        subtitle: String,
        actionTitle: String? = nil,
        actionIcon: String? = nil,
        onAction: (() -> Void)? = nil,
        showSparkles: Bool = true
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.actionIcon = actionIcon
        self.onAction = onAction
        self.showSparkles = showSparkles
    }

    var body: some View {
        VStack(spacing: 24) {
            // Icon with sparkles
            ZStack {
                Image(systemName: icon)
                    .font(.system(size: 64))
                    .foregroundStyle(DesignSystem.primaryGradient)
                    .scaleEffect(1.0)
                    .animation(
                        .easeInOut(duration: 2.0)
                            .repeatForever(autoreverses: true),
                        value: UUID()
                    )

                if showSparkles {
                    // Subtle sparkles around the icon
                    HStack(spacing: 8) {
                        SparkleAnimation(delay: 0.0)
                        SparkleAnimation(delay: 0.3)
                        SparkleAnimation(delay: 0.6)
                    }
                    .offset(x: 40, y: -30)
                }
            }

            // Content
            VStack(spacing: 8) {
                Text(title)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundStyle(DesignSystem.primaryGradient)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            // Action Button (if provided)
            if let actionTitle = actionTitle,
               let actionIcon = actionIcon,
               let onAction = onAction
            {
                Button(action: onAction) {
                    HStack {
                        Image(systemName: actionIcon)
                        Text(actionTitle)
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .background(DesignSystem.primaryGradient)
                    .cornerRadius(DesignSystem.mediumRadius)
                    .primaryShadow()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    VStack(spacing: 20) {
        EmptyStateView(
            icon: "heart",
            title: "No Favorites Yet",
            subtitle: "Start building your collection by exploring AI recommendations",
            actionTitle: "Get Recommendations",
            actionIcon: "star.fill",
            onAction: { print("Action tapped") }
        )

        EmptyStateView(
            icon: "film.stack",
            title: "No Movies Yet",
            subtitle: "Your movie collection will appear here as you interact with recommendations",
            showSparkles: false
        )
    }
    .padding()
}
