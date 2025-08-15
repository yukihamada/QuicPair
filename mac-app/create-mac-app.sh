#!/bin/bash

echo "🖥 Creating QuicPair macOS App"
echo "=============================="

# Create directory structure
mkdir -p QuicPair/{Views,Services,Models}

# Create AppDelegate.swift
cat > QuicPair/AppDelegate.swift << 'EOF'
import Cocoa
import SwiftUI

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var window: NSWindow!
    var statusItem: NSStatusItem!
    let serverManager = ServerManager()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create main window
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 800, height: 600),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        
        window.center()
        window.title = "QuicPair"
        window.setFrameAutosaveName("Main Window")
        
        // Set content view
        let contentView = ContentView()
            .environmentObject(serverManager)
        
        window.contentView = NSHostingView(rootView: contentView)
        window.makeKeyAndOrderFront(nil)
        
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "bolt.fill", accessibilityDescription: "QuicPair")
            button.action = #selector(toggleWindow)
        }
        
        // Start server
        serverManager.startServer()
    }
    
    @objc func toggleWindow() {
        if window.isVisible {
            window.orderOut(nil)
        } else {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }
}
EOF

# Create ContentView.swift
cat > QuicPair/Views/ContentView.swift << 'EOF'
import SwiftUI
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @EnvironmentObject var serverManager: ServerManager
    @State private var showQRCode = true
    @State private var messageText = ""
    
    var body: some View {
        if showQRCode {
            QRCodeView(showQRCode: $showQRCode)
        } else {
            ChatView()
        }
    }
}

struct QRCodeView: View {
    @EnvironmentObject var serverManager: ServerManager
    @Binding var showQRCode: Bool
    @State private var qrImage: NSImage?
    
    var body: some View {
        VStack(spacing: 30) {
            Text("QuicPair Connection")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            if let qrImage = qrImage {
                Image(nsImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 300, height: 300)
                    .padding()
                    .background(Color.white)
                    .cornerRadius(20)
            } else {
                ProgressView()
                    .frame(width: 300, height: 300)
            }
            
            VStack(spacing: 10) {
                Text("Scan with iPhone to connect")
                    .font(.headline)
                
                Text(serverManager.connectionURL)
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 20) {
                Button("Continue to Mac Chat") {
                    showQRCode = false
                }
                .buttonStyle(.borderedProminent)
                
                Button("Copy URL") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(serverManager.connectionURL, forType: .string)
                }
                .buttonStyle(.bordered)
            }
            
            if serverManager.isClientConnected {
                Label("iPhone Connected", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(10)
            }
        }
        .padding(50)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
        .onAppear {
            generateQRCode()
        }
    }
    
    private func generateQRCode() {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(serverManager.connectionURL.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                qrImage = NSImage(cgImage: cgImage, size: NSSize(width: 300, height: 300))
            }
        }
    }
}

struct ChatView: View {
    @EnvironmentObject var serverManager: ServerManager
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @State private var isLoading = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("QuicPair Chat")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let ttft = serverManager.lastTTFT {
                    Label("\(ttft)ms", systemImage: "timer")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            .padding()
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if isLoading {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Thinking...")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding()
                }
                .onChange(of: messages.count) { _ in
                    withAnimation {
                        proxy.scrollTo(messages.last?.id, anchor: .bottom)
                    }
                }
            }
            
            Divider()
            
            // Input
            HStack(spacing: 12) {
                TextField("Type a message...", text: $messageText)
                    .textFieldStyle(.plain)
                    .font(.body)
                    .onSubmit {
                        sendMessage()
                    }
                
                Button(action: sendMessage) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(messageText.isEmpty || isLoading)
            }
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 400)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let userMessage = ChatMessage(content: messageText, isUser: true)
        messages.append(userMessage)
        
        let prompt = messageText
        messageText = ""
        isLoading = true
        
        Task {
            let startTime = Date()
            
            do {
                let response = try await serverManager.generateResponse(for: prompt)
                
                await MainActor.run {
                    let ttft = Int(Date().timeIntervalSince(startTime) * 1000)
                    serverManager.lastTTFT = ttft
                    
                    let aiMessage = ChatMessage(content: response, isUser: false)
                    messages.append(aiMessage)
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    let errorMessage = ChatMessage(content: "Error: \(error.localizedDescription)", isUser: false)
                    messages.append(errorMessage)
                    isLoading = false
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser { Spacer() }
            
            Text(message.content)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(message.isUser ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(16)
                .contextMenu {
                    Button("Copy") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(message.content, forType: .string)
                    }
                }
            
            if !message.isUser { Spacer() }
        }
    }
}
EOF

# Create ServerManager.swift
cat > QuicPair/Services/ServerManager.swift << 'EOF'
import Foundation
import Network
import Combine

class ServerManager: ObservableObject {
    @Published var isServerRunning = false
    @Published var isClientConnected = false
    @Published var connectionURL = ""
    @Published var lastTTFT: Int?
    
    private var listener: NWListener?
    private let port: UInt16 = 8443
    
    init() {
        updateConnectionURL()
    }
    
    func startServer() {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
        // Configure TLS for HTTPS
        let tlsOptions = NWProtocolTLS.Options()
        sec_protocol_options_set_verify_block(tlsOptions.securityProtocolOptions, { _, _, completion in
            completion(true)
        }, .main)
        
        parameters.defaultProtocolStack.applicationProtocols.insert(tlsOptions, at: 0)
        
        listener = try? NWListener(using: parameters, on: NWEndpoint.Port(integerLiteral: port))
        
        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleConnection(connection)
        }
        
        listener?.start(queue: .main)
        isServerRunning = true
        
        print("Server started on port \(port)")
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: .main)
        
        // Simple HTTP response for QR code data
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, isComplete, error in
            if let data = data, !data.isEmpty {
                let request = String(data: data, encoding: .utf8) ?? ""
                
                if request.contains("GET /connect") {
                    self.isClientConnected = true
                    let response = self.createHTTPResponse(body: """
                    {
                        "status": "connected",
                        "serverName": "QuicPair Mac",
                        "version": "1.0"
                    }
                    """)
                    connection.send(content: response, completion: .contentProcessed { _ in
                        connection.cancel()
                    })
                } else if request.contains("POST /chat") {
                    // Handle chat requests from iPhone
                    // Extract JSON body and process
                    self.handleChatRequest(data: data, connection: connection)
                }
            }
        }
    }
    
    private func handleChatRequest(data: Data, connection: NWConnection) {
        // Parse HTTP request to get body
        if let requestString = String(data: data, encoding: .utf8),
           let bodyRange = requestString.range(of: "\r\n\r\n") {
            let bodyStart = requestString.index(bodyRange.upperBound, offsetBy: 0)
            let bodyString = String(requestString[bodyStart...])
            
            if let bodyData = bodyString.data(using: .utf8),
               let json = try? JSONSerialization.jsonObject(with: bodyData) as? [String: Any],
               let prompt = json["prompt"] as? String {
                
                Task {
                    do {
                        let response = try await generateResponse(for: prompt)
                        let jsonResponse = try JSONSerialization.data(withJSONObject: ["response": response])
                        
                        let httpResponse = createHTTPResponse(body: String(data: jsonResponse, encoding: .utf8) ?? "{}")
                        connection.send(content: httpResponse, completion: .contentProcessed { _ in
                            connection.cancel()
                        })
                    } catch {
                        let errorResponse = createHTTPResponse(body: "{\"error\": \"\(error.localizedDescription)\"}")
                        connection.send(content: errorResponse, completion: .contentProcessed { _ in
                            connection.cancel()
                        })
                    }
                }
            }
        }
    }
    
    private func createHTTPResponse(body: String) -> Data {
        let headers = """
        HTTP/1.1 200 OK\r
        Content-Type: application/json\r
        Content-Length: \(body.utf8.count)\r
        Access-Control-Allow-Origin: *\r
        \r\n
        """
        return (headers + body).data(using: .utf8)!
    }
    
    func generateResponse(for prompt: String) async throws -> String {
        // Use Ollama API
        let url = URL(string: "http://localhost:11434/api/generate")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "model": "llama3.2:3b",
            "prompt": prompt,
            "stream": false
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let response = json["response"] as? String {
            return response
        }
        
        throw NSError(domain: "ServerManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to generate response"])
    }
    
    private func updateConnectionURL() {
        if let ip = getLocalIPAddress() {
            connectionURL = "https://\(ip):\(port)"
        } else {
            connectionURL = "https://localhost:\(port)"
        }
    }
    
    private func getLocalIPAddress() -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }
        
        for ifptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ifptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family
            
            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if name == "en0" {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                               &hostname, socklen_t(hostname.count),
                               nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        
        freeifaddrs(ifaddr)
        return address
    }
}
EOF

# Create ChatMessage.swift
cat > QuicPair/Models/ChatMessage.swift << 'EOF'
import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}
EOF

# Create Info.plist
cat > QuicPair/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>$(DEVELOPMENT_LANGUAGE)</string>
    <key>CFBundleExecutable</key>
    <string>$(EXECUTABLE_NAME)</string>
    <key>CFBundleIconFile</key>
    <string></string>
    <key>CFBundleIdentifier</key>
    <string>$(PRODUCT_BUNDLE_IDENTIFIER)</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$(PRODUCT_NAME)</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>$(MACOSX_DEPLOYMENT_TARGET)</string>
    <key>NSMainNibFile</key>
    <string>MainMenu</string>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
</plist>
EOF

# Create project.yml for xcodegen
cat > project.yml << 'EOF'
name: QuicPair
options:
  bundleIdPrefix: com.hamada
  deploymentTarget:
    macOS: 13.0
targets:
  QuicPair:
    type: application
    platform: macOS
    sources:
      - path: QuicPair
    settings:
      base:
        PRODUCT_BUNDLE_IDENTIFIER: com.hamada.QuicPair.mac
        PRODUCT_NAME: QuicPair
        DEVELOPMENT_TEAM: T47FJ2TW22
        CODE_SIGN_STYLE: Automatic
        INFOPLIST_FILE: QuicPair/Info.plist
        MACOSX_DEPLOYMENT_TARGET: 13.0
        SWIFT_VERSION: 5.0
        GENERATE_INFOPLIST_FILE: NO
        COMBINE_HIDPI_IMAGES: YES
        CODE_SIGN_ENTITLEMENTS: QuicPair/QuicPair.entitlements
EOF

# Create entitlements
cat > QuicPair/QuicPair.entitlements << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>com.apple.security.app-sandbox</key>
    <true/>
    <key>com.apple.security.network.client</key>
    <true/>
    <key>com.apple.security.network.server</key>
    <true/>
    <key>com.apple.security.files.user-selected.read-write</key>
    <true/>
</dict>
</plist>
EOF

# Generate project
echo "🔨 Generating Xcode project..."
xcodegen

echo "✅ macOS app created!"
echo ""
echo "📝 Installing Ollama (if not already installed)..."
if ! command -v ollama &> /dev/null; then
    echo "Installing Ollama..."
    curl -fsSL https://ollama.ai/install.sh | sh
fi

echo ""
echo "📦 Pulling llama3.2:3b model..."
ollama pull llama3.2:3b

echo ""
echo "🚀 Opening Xcode..."
open QuicPair.xcodeproj

echo ""
echo "✅ Complete! The app will:"
echo "1. Show QR code on launch"
echo "2. iPhone can scan to connect and use Mac's LLM"
echo "3. Click 'Continue to Mac Chat' to use chat on Mac"
echo "4. Both devices can use the same Ollama model"
echo ""
echo "Press Cmd+R to run!"