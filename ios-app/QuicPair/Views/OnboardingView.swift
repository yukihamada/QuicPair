import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var appState: AppState
    @State private var currentPage = 0
    
    var body: some View {
        VStack {
            TabView(selection: $currentPage) {
                OnboardingPageView(
                    imageName: "bolt.fill",
                    title: "Welcome to QuicPair",
                    description: "Ultra-fast AI assistant using local LLM"
                )
                .tag(0)
                
                OnboardingPageView(
                    imageName: "lock.shield.fill",
                    title: "Private & Secure",
                    description: "All data stays on your devices with end-to-end encryption"
                )
                .tag(1)
                
                OnboardingPageView(
                    imageName: "hare.fill",
                    title: "Lightning Fast",
                    description: "Get responses in under 150ms"
                )
                .tag(2)
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            Button(action: {
                if currentPage < 2 {
                    currentPage += 1
                } else {
                    appState.completeOnboarding()
                }
            }) {
                Text(currentPage < 2 ? "Next" : "Get Started")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding()
        }
    }
}

struct OnboardingPageView: View {
    let imageName: String
    let title: String
    let description: String
    
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image(systemName: imageName)
                .font(.system(size: 100))
                .foregroundColor(.accentColor)
            
            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            Text(description)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            
            Spacer()
            Spacer()
        }
    }
}
