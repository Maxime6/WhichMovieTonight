import SwiftUI

struct RootView: View {
    @StateObject private var appStateManager = AppStateManager()

    var body: some View {
        ZStack {
            switch appStateManager.appState {
            case .launch:
                LaunchScreen()
                    .environmentObject(appStateManager)

            case .needsOnboarding:
                OnboardingView()
                    .environmentObject(appStateManager)

            case .needsAuthentication:
                AuthenticationView()
                    .environmentObject(appStateManager)

            case .authenticated:
                ContentView()
                    .environmentObject(appStateManager)
            }
        }
    }
}

#Preview {
    RootView()
}
