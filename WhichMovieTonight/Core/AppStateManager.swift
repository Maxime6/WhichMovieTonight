import FirebaseAuth
import Foundation
import RevenueCat

@MainActor
class AppStateManager: ObservableObject {
    @Published var appState: AppState = .launch
    @Published var isSubscribed: Bool = false
    @Published var isTrialActive: Bool = false
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var shouldShowPaywall: Bool = false

    private let userProfileService: UserProfileService

    // MARK: - App States

    enum AppState {
        case launch
        case needsOnboarding
        case needsAuthentication
        case authenticated
    }

    enum SubscriptionStatus {
        case unknown
        case notSubscribed
        case trialActive
        case subscribed
        case expired
    }

    // MARK: - Initialization

    init(userProfileService: UserProfileService) {
        self.userProfileService = userProfileService
    }

    // MARK: - App Initialization

    func initializeApp() async {
        // Check authentication
        if let currentUser = Auth.auth().currentUser {
            // Load user preferences from Firebase to check if onboarding is completed
            await userProfileService.loadUserPreferences(userId: currentUser.uid)

            // Check if user has completed onboarding
            if userProfileService.hasCompletedOnboarding {
                // User is authenticated and has completed onboarding
                // Set to authenticated state - premium checks will happen when needed
                appState = .authenticated
            } else {
                appState = .needsOnboarding
            }
        } else {
            appState = .needsAuthentication
        }
    }

    // MARK: - Premium Access Check

    /// Check if user has premium access for generating new recommendations
    func checkPremiumAccess() async -> Bool {
        // Safety check: ensure RevenueCat is configured
        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, cannot check premium access")
            return false
        }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionState(from: customerInfo)

            let hasPremium = isSubscribed || isTrialActive
            print("📱 Premium access check: \(hasPremium)")
            return hasPremium
        } catch {
            print("❌ Error checking premium access: \(error)")
            subscriptionStatus = .unknown
            isSubscribed = false
            isTrialActive = false
            return false
        }
    }

    /// Show paywall for premium features
    func showPaywallForPremiumFeature() async {
        shouldShowPaywall = true
    }

    // MARK: - Subscription Management

    func checkSubscriptionStatus() async {
        // Safety check: ensure RevenueCat is configured
        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, skipping subscription check")
            return
        }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionState(from: customerInfo)

            // Debug: Check available offerings
            let offerings = try await Purchases.shared.offerings()
            if let current = offerings.current {
                print("📱 Current offering: \(current.identifier)")
                print("📱 Available packages:")
                for package in current.availablePackages {
                    print("   - \(package.identifier): \(package.storeProduct.localizedTitle)")
                    print("     Price: \(package.storeProduct.localizedPriceString)")
                    if let introPrice = package.storeProduct.introductoryDiscount {
                        print("     Intro Price: \(introPrice.localizedPriceString)")
                    }
                }
            } else {
                print("❌ No current offering available")
            }
        } catch {
            print("❌ Error checking subscription status: \(error)")
            subscriptionStatus = .unknown
            isSubscribed = false
            isTrialActive = false
        }
    }

    private func updateSubscriptionState(from customerInfo: CustomerInfo) {
        // Check if user has active entitlement
        let hasActiveEntitlement = customerInfo.entitlements.active["Premium"] != nil

        if hasActiveEntitlement {
            let entitlement = customerInfo.entitlements.active["Premium"]!

            if entitlement.isActive {
                if entitlement.periodType == .trial {
                    subscriptionStatus = .trialActive
                    isTrialActive = true
                    isSubscribed = false
                } else {
                    subscriptionStatus = .subscribed
                    isSubscribed = true
                    isTrialActive = false
                }
            } else {
                subscriptionStatus = .expired
                isSubscribed = false
                isTrialActive = false
            }
        } else {
            subscriptionStatus = .notSubscribed
            isSubscribed = false
            isTrialActive = false
        }

        print("📱 Subscription Status: \(subscriptionStatus)")
        print("📱 Is Subscribed: \(isSubscribed)")
        print("📱 Is Trial Active: \(isTrialActive)")
    }

    func handleSubscriptionUpdate() async {
        // Safety check: ensure RevenueCat is configured
        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, skipping subscription update")
            return
        }

        await checkSubscriptionStatus()

        if isSubscribed || isTrialActive {
            shouldShowPaywall = false
        } else {
            shouldShowPaywall = true
        }
    }

    func handleSuccessfulPurchase() async {
        // Safety check: ensure RevenueCat is configured
        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, skipping purchase handling")
            return
        }

        await checkSubscriptionStatus()

        if isSubscribed || isTrialActive {
            shouldShowPaywall = false
        }
    }

    // MARK: - Authentication Handling

    func handleSuccessfulAuthentication() async {
        guard let currentUser = Auth.auth().currentUser else {
            appState = .needsAuthentication
            return
        }

        // Load user preferences from Firebase
        await userProfileService.loadUserPreferences(userId: currentUser.uid)

        // If user has completed onboarding, set to authenticated
        if userProfileService.hasCompletedOnboarding {
            appState = .authenticated
        } else {
            // User is authenticated but needs onboarding
            appState = .needsOnboarding
        }
    }

    func handleSignOut() {
        appState = .needsAuthentication
        isSubscribed = false
        isTrialActive = false
        subscriptionStatus = .unknown
        shouldShowPaywall = false
    }

    func handleAccountDeletion() {
        appState = .needsAuthentication
        isSubscribed = false
        isTrialActive = false
        subscriptionStatus = .unknown
        shouldShowPaywall = false
    }

    func completeOnboarding() {
        // After onboarding, set to authenticated state
        appState = .authenticated
    }
}
