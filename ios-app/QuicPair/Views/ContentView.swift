import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var connectionManager: ConnectionManager
    @EnvironmentObject var chatService: ChatService
    
    var body: some View {
        ZStack {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if !connectionManager.isConnected {
                ConnectionView()
            } else {
                ChatView()
            }
        }
        .sheet(isPresented: $appState.showQRScanner) {
            QRScannerView()
        }
        .onChange(of: connectionManager.isConnected) { connected in
            appState.isConnected = connected
        }
    }
}

struct ConnectionView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var connectionManager: ConnectionManager
    @State private var showManualInput = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "bolt.fill")
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                    .padding()
                
                Text("Connect to Mac")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Scan the QR code displayed on your Mac")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                
                VStack(spacing: 16) {
                    Button(action: {
                        appState.showQRScanner = true
                    }) {
                        Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                    
                    Button(action: {
                        showManualInput = true
                    }) {
                        Label("Enter Manually", systemImage: "keyboard")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.secondary.opacity(0.2))
                            .foregroundColor(.primary)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showManualInput) {
            ManualConnectionView()
        }
    }
}
