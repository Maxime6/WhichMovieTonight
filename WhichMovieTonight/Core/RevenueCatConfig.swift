import Foundation

enum RevenueCatConfig {
    // MARK: - API Keys

    // RevenueCat API key is securely stored in APIKeys.plist
    static var apiKey: String {
        guard let key = Config.revenueCatAPIKey else {
            fatalError("RevenueCat API key not found. Please add REVENUECAT_API_KEY to APIKeys.plist")
        }
        return key
    }

    // MARK: - Product IDs

    static let monthlyProductID = "MovieBuddy_AI_Premium_Monthly"
    static let yearlyProductID = "MovieBuddy_AI_Premium_Yearly"

    // MARK: - Entitlement ID

    static let premiumEntitlementID = "Premium"

    // MARK: - Feature Flags

    static let enableDebugLogging = true
}
