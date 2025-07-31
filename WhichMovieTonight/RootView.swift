import FirebaseAuth
import RevenueCatUI
import SwiftUI

struct RootView: View {
    @StateObject private var userProfileService = UserProfileService()
    @StateObject private var appStateManager: AppStateManager
    @EnvironmentObject var notificationService: NotificationService

    init() {
        let userProfileService = UserProfileService()
        _userProfileService = StateObject(wrappedValue: userProfileService)
        _appStateManager = StateObject(wrappedValue: AppStateManager(userProfileService: userProfileService))
    }

    var body: some View {
        ZStack {
            switch appStateManager.appState {
            case .launch:
                LaunchScreen()
                    .environmentObject(appStateManager)

            case .needsOnboarding:
                NewOnboardingView(userProfileService: userProfileService)
                    .environmentObject(appStateManager)
                    .environmentObject(userProfileService)
                    .environmentObject(notificationService)

            case .needsAuthentication:
                ValuePropositionView()
                    .environmentObject(appStateManager)
                    .environmentObject(userProfileService)

            case .authenticated:
                ContentView()
                    .environmentObject(appStateManager)
                    .environmentObject(userProfileService)
                    .environmentObject(notificationService)
            }
        }
        .sheet(isPresented: $appStateManager.shouldShowPaywall) {
            PaywallView(displayCloseButton: false)
                .onDisappear {
                    // Check subscription status when paywall disappears
                    // This handles successful purchases, restores, and cancellations
                    Task {
                        await appStateManager.checkSubscriptionStatus()

                        // If user successfully upgraded to premium, trigger any pending operations
                        if appStateManager.isSubscribed || appStateManager.isTrialActive {
                            print("🎉 User upgraded to premium - triggering pending operations")
                            // Trigger retry of pending operations in HomeViewModel
                            // This will be handled by the HomeView's environment object
                        }
                    }
                }
        }
        .onAppear {
            // Clear app badge when app opens
            notificationService.clearAppBadge()

            // Check if app was opened from notification
            checkIfOpenedFromNotification()
        }
    }

    private func checkIfOpenedFromNotification() {
        // This will be called when app opens
        // We'll track this in analytics to see if user opened from notification
        Task {
            await notificationService.trackAppOpenedFromNotification()
        }
    }
}

#Preview {
    RootView()
}
