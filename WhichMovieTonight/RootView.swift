import SwiftUI

struct RootView: View {
    @StateObject private var appStateManager = AppStateManager()

    var body: some View {
        Group {
            switch appStateManager.currentState {
            case .onboarding:
                OnboardingView(appStateManager: appStateManager)
            case .authentication:
                AuthenticationView(appStateManager: appStateManager)
            case .authenticated:
                ContentView()
                    .environmentObject(appStateManager)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: appStateManager.currentState)
    }
}

#Preview {
    RootView()
}
