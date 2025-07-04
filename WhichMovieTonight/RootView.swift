import FirebaseAuth
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
                AuthenticationView()
                    .environmentObject(appStateManager)

            case .authenticated:
                ContentView()
                    .environmentObject(appStateManager)
                    .environmentObject(userProfileService)
                    .environmentObject(notificationService)
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
