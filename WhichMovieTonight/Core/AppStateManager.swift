import FirebaseAuth
import Foundation
import RevenueCat

@MainActor
class AppStateManager: ObservableObject {
    @Published var appState: AppState = .launch
    @Published var isSubscribed: Bool = false
    @Published var isTrialActive: Bool = false
    @Published var subscriptionStatus: SubscriptionStatus = .unknown
    @Published var shouldShowPaywall: Bool = false {
        didSet {
            print("🔒 shouldShowPaywall changed to: \(shouldShowPaywall)")
        }
    }

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
                appState = .authenticated
                // Always check premium status on app launch
                await checkAndShowPaywallIfNeeded()
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
        print("🔍 Checking premium access...")
        // Safety check: ensure RevenueCat is configured
        guard Purchases.isConfigured else {
            print("⚠️ RevenueCat not configured yet, cannot check premium access")
            return false
        }

        do {
            let customerInfo = try await Purchases.shared.customerInfo()
            updateSubscriptionState(from: customerInfo)

            let hasPremium = isSubscribed || isTrialActive
            print("📱 Premium access check result: \(hasPremium)")
            return hasPremium
        } catch {
            print("❌ Error checking premium access: \(error)")
            subscriptionStatus = .unknown
            isSubscribed = false
            isTrialActive = false
            return false
        }
    }

    /// Check if user needs premium and show paywall automatically
    func checkAndShowPaywallIfNeeded() async {
        print("🔍 Checking if paywall should be shown automatically...")

        // Reset paywall state first
        shouldShowPaywall = false

        // Check premium access
        let hasPremiumAccess = await checkPremiumAccess()

        if !hasPremiumAccess {
            print("🔒 User is not premium - showing paywall automatically")
            shouldShowPaywall = true
        } else {
            print("✅ User has premium access - no paywall needed")
            shouldShowPaywall = false
        }
    }

    /// Show paywall for premium features
    func showPaywallForPremiumFeature() async {
        print("🔒 Showing paywall for premium feature")
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

        // Only hide paywall if user is premium, don't automatically show it
        if isSubscribed || isTrialActive {
            shouldShowPaywall = false
        }
        // Removed automatic paywall showing - it should only be shown when explicitly requested
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
            print("🎉 Purchase successful - paywall hidden")
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
        print("🔒 User signed out - paywall reset")
    }

    func handleAccountDeletion() {
        appState = .needsAuthentication
        isSubscribed = false
        isTrialActive = false
        subscriptionStatus = .unknown
        shouldShowPaywall = false
        print("🔒 User account deleted - paywall reset")
    }

    func completeOnboarding() {
        // After onboarding, set to authenticated state
        appState = .authenticated
    }
}
