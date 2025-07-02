//
//  SortOption.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 28/03/2025.
//

import Foundation

// MARK: - Sort Option Enum

enum SortOption: String, CaseIterable {
    case recentlyAdded
    case titleAscending
    case titleDescending
    case yearDescending
    case yearAscending
    case ratingDescending

    var displayName: String {
        switch self {
        case .recentlyAdded: return "Recently Added"
        case .titleAscending: return "Title A-Z"
        case .titleDescending: return "Title Z-A"
        case .yearDescending: return "Year (Newest)"
        case .yearAscending: return "Year (Oldest)"
        case .ratingDescending: return "Rating (High to Low)"
        }
    }

    var icon: String {
        switch self {
        case .recentlyAdded: return "clock.fill"
        case .titleAscending: return "textformat.abc"
        case .titleDescending: return "textformat.abc.dottedunderline"
        case .yearDescending: return "calendar.badge.plus"
        case .yearAscending: return "calendar.badge.minus"
        case .ratingDescending: return "star.fill"
        }
    }
}
