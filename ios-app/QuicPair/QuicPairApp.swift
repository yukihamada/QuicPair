import SwiftUI

@main
struct QuicPairApp: App {
    @StateObject private var appState = AppState()
    @StateObject private var connectionManager = ConnectionManager()
    @StateObject private var chatService = ChatService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(appState)
                .environmentObject(connectionManager)
                .environmentObject(chatService)
                .onAppear {
                    // Ensure connection is set
                    chatService.setConnectionManager(connectionManager)
                }
        }
    }
}
