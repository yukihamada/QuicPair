import Cocoa
import SwiftUI

@main
struct QuicPairApp: App {
    @StateObject private var serverManager = ServerManager()
    
    init() {
        print("QuicPair: App initializing...")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(serverManager)
                .onAppear {
                    print("QuicPair: ContentView appeared")
                    serverManager.startServer()
                }
        }
        .windowStyle(.titleBar)
        .windowToolbarStyle(.unified)
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button("About QuicPair") {
                    NSApp.orderFrontStandardAboutPanel(options: [
                        .applicationName: "QuicPair",
                        .applicationVersion: "1.0"
                    ])
                }
            }
        }
    }
}
