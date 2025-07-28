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

            case .needsPaywall:
                // Show main app content but with paywall overlay
                ContentView()
                    .environmentObject(appStateManager)
                    .environmentObject(userProfileService)
                    .environmentObject(notificationService)

            case .authenticated:
                ContentView()
                    .environmentObject(appStateManager)
                    .environmentObject(userProfileService)
                    .environmentObject(notificationService)
            }
        }
//        .sheet(isPresented: $appStateManager.shouldShowPaywall) {
//            PaywallView(displayCloseButton: false)
//                .onDisappear {
//                    // Check subscription status when paywall disappears
//                    // This handles successful purchases, restores, and cancellations
//                    Task {
//                        await appStateManager.handleSubscriptionUpdate()
//                    }
//                }
//        }
        .onAppear {
            // Clear app badge when app opens
            notificationService.clearAppBadge()

            // Check if app was opened from notification
            checkIfOpenedFromNotification()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            // Check subscription status when app becomes active (in case user cancelled in App Store)
            Task {
                await appStateManager.handleSubscriptionUpdate()
            }
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
