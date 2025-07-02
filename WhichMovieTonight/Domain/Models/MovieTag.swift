//
//  MovieTag.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import Foundation
import SwiftUI

// MARK: - Movie Tag Enum

enum MovieTag: String, CaseIterable, Identifiable {
    case all
    case currentPicks
    case history
    case liked
    case disliked
    case favorites
    case seen
    case tonight

    var id: String { rawValue }

    // MARK: - Display Properties

    var displayName: String {
        switch self {
        case .all: return "All"
        case .currentPicks: return "Daily Picks"
        case .history: return "History"
        case .liked: return "Liked"
        case .disliked: return "Disliked"
        case .favorites: return "Favorites"
        case .seen: return "Seen"
        case .tonight: return "Tonight"
        }
    }

    var icon: String {
        switch self {
        case .all: return "film.stack"
        case .currentPicks: return "star.circle.fill"
        case .history: return "clock.fill"
        case .liked: return "hand.thumbsup.fill"
        case .disliked: return "hand.thumbsdown.fill"
        case .favorites: return "heart.fill"
        case .seen: return "checkmark.circle.fill"
        case .tonight: return "moon.stars.fill"
        }
    }

    var color: Color {
        switch self {
        case .all: return .blue
        case .currentPicks: return .orange
        case .history: return .gray
        case .liked: return .green
        case .disliked: return .red
        case .favorites: return .pink
        case .seen: return .purple
        case .tonight: return .indigo
        }
    }

    // MARK: - Priority for Primary Tag

    var priority: Int {
        switch self {
        case .seen: return 100
        case .tonight: return 90
        case .favorites: return 80
        case .liked: return 70
        case .disliked: return 60
        case .currentPicks: return 50
        case .history: return 40
        case .all: return 0
        }
    }
}

// MARK: - Filter Tag View Component

struct FilterTag: View {
    let tag: MovieTag
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: tag.icon)
                    .font(.callout)

                Text(tag.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(isSelected ? tag.color : Color.gray.opacity(0.2))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Filter Tags Row Component

struct FilterTagsRow: View {
    let selectedTag: MovieTag
    let onTagSelected: (MovieTag) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(MovieTag.allCases) { tag in
                    FilterTag(
                        tag: tag,
                        isSelected: selectedTag == tag,
                        action: { onTagSelected(tag) }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        FilterTagsRow(selectedTag: .all) { _ in }
        FilterTagsRow(selectedTag: .favorites) { _ in }
        FilterTagsRow(selectedTag: .seen) { _ in }
    }
    .padding()
}
