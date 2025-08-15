import SwiftUI
import Combine

class AppState: ObservableObject {
    @Published var hasCompletedOnboarding = false
    @Published var isConnected = false
    @Published var showQRScanner = false
    @Published var connectionError: String? = nil
    
    init() {
        hasCompletedOnboarding = UserDefaults.standard.bool(forKey: "hasCompletedOnboarding")
    }
    
    func completeOnboarding() {
        hasCompletedOnboarding = true
        UserDefaults.standard.set(true, forKey: "hasCompletedOnboarding")
    }
    
    func setConnected(_ connected: Bool) {
        isConnected = connected
    }
}
