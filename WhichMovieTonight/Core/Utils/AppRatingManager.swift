//
//  AppRatingManager.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 31/12/2024.
//

import Foundation
import StoreKit

@MainActor
class AppRatingManager: ObservableObject {
    @Published var shouldShowRatingPopup = false
    @Published var hasRatedApp = false

    private let userDefaults = UserDefaults.standard
    private let appUsageKey = "app_usage_count"
    private let lastRatingPromptKey = "last_rating_prompt_date"
    private let hasRatedKey = "has_rated_app"
    private let currentVersionKey = "current_app_version"

    private let minimumUsageCount = 5
    private let minimumDaysBetweenPrompts = 30

    init() {
        loadRatingState()
    }

    // MARK: - Public Methods

    func incrementAppUsage() {
        let currentCount = userDefaults.integer(forKey: appUsageKey)
        let newCount = currentCount + 1
        userDefaults.set(newCount, forKey: appUsageKey)

        checkIfShouldShowRating()
    }

    func showRatingPopup() {
        shouldShowRatingPopup = true
    }

    func dismissRatingPopup() {
        shouldShowRatingPopup = false
    }

    func handleRatingSubmitted(rating: Int) {
        hasRatedApp = true
        userDefaults.set(true, forKey: hasRatedKey)
        userDefaults.set(Date(), forKey: lastRatingPromptKey)
        shouldShowRatingPopup = false

        if rating == 5 {
            requestAppStoreReview()
        }
    }

    func requestAppStoreReview() {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
            return
        }

        SKStoreReviewController.requestReview(in: scene)
    }

    // MARK: - Private Methods

    private func loadRatingState() {
        hasRatedApp = userDefaults.bool(forKey: hasRatedKey)

        // Check if app version changed (reset rating state for new versions)
        let currentVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
        let savedVersion = userDefaults.string(forKey: currentVersionKey)

        if savedVersion != currentVersion {
            // New version, reset rating state
            hasRatedApp = false
            userDefaults.set(false, forKey: hasRatedKey)
            userDefaults.set(currentVersion, forKey: currentVersionKey)
        }
    }

    private func checkIfShouldShowRating() {
        // Don't show if user has already rated
        guard !hasRatedApp else { return }

        // Don't show if minimum usage count not reached
        let usageCount = userDefaults.integer(forKey: appUsageKey)
        guard usageCount >= minimumUsageCount else { return }

        // Don't show if we've shown recently
        if let lastPromptDate = userDefaults.object(forKey: lastRatingPromptKey) as? Date {
            let daysSinceLastPrompt = Calendar.current.dateComponents([.day], from: lastPromptDate, to: Date()).day ?? 0
            guard daysSinceLastPrompt >= minimumDaysBetweenPrompts else { return }
        }

        // Show rating popup
        shouldShowRatingPopup = true
    }
}
