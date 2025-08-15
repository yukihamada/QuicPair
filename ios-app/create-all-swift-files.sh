#!/bin/bash

echo "📝 Creating all Swift files..."

# QuicPairApp.swift
cat > QuicPair/QuicPairApp.swift << 'EOF'
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
        }
    }
}
EOF

# AppState.swift
cat > QuicPair/AppState.swift << 'EOF'
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
EOF

# Models/ChatMessage.swift
cat > QuicPair/Models/ChatMessage.swift << 'EOF'
import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}
EOF

# Models/RecentConnection.swift
cat > QuicPair/Models/RecentConnection.swift << 'EOF'
import Foundation

struct RecentConnection: Identifiable, Codable {
    let id = UUID()
    let deviceName: String
    let serverURL: String
    let lastConnected: Date
}
EOF

# Views/ContentView.swift
cat > QuicPair/Views/ContentView.swift << 'EOF'
import SwiftUI

struct ContentView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var connectionManager: ConnectionManager
    @EnvironmentObject var chatService: ChatService
    
    var body: some View {
        ZStack {
            if !appState.hasCompletedOnboarding {
                OnboardingView()
            } else if !appState.isConnected {
                ConnectionView()
            } else {
                ChatView()
            }
        }
        .sheet(isPresented: $appState.showQRScanner) {
            QRScannerView()
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
EOF

# Views/OnboardingView.swift
cat > QuicPair/Views/OnboardingView.swift << 'EOF'
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
EOF

# Views/QRScannerView.swift
cat > QuicPair/Views/QRScannerView.swift << 'EOF'
import SwiftUI
import AVFoundation

struct QRScannerView: View {
    @EnvironmentObject var appState: AppState
    @EnvironmentObject var connectionManager: ConnectionManager
    @Environment(\.dismiss) var dismiss
    @State private var isScanning = false
    
    var body: some View {
        NavigationView {
            ZStack {
                QRScannerViewController(
                    onCodeScanned: { code in
                        handleQRCode(code)
                    }
                )
                
                VStack {
                    Spacer()
                    
                    Text("Point camera at QR code")
                        .font(.headline)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(10)
                        .padding()
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func handleQRCode(_ code: String) {
        guard !isScanning else { return }
        isScanning = true
        
        // Parse QR code and connect
        if let url = URL(string: code) {
            connectionManager.connectToServer(url: url)
            dismiss()
        }
    }
}

struct QRScannerViewController: UIViewControllerRepresentable {
    let onCodeScanned: (String) -> Void
    
    func makeUIViewController(context: Context) -> ScannerViewController {
        let controller = ScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: ScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(onCodeScanned: onCodeScanned)
    }
    
    class Coordinator: NSObject, AVCaptureMetadataOutputObjectsDelegate {
        let onCodeScanned: (String) -> Void
        
        init(onCodeScanned: @escaping (String) -> Void) {
            self.onCodeScanned = onCodeScanned
        }
        
        func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
            guard let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let code = object.stringValue else { return }
            
            DispatchQueue.main.async {
                self.onCodeScanned(code)
            }
        }
    }
}

class ScannerViewController: UIViewController {
    var captureSession = AVCaptureSession()
    var previewLayer: AVCaptureVideoPreviewLayer!
    weak var delegate: AVCaptureMetadataOutputObjectsDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else { return }
        let videoInput: AVCaptureDeviceInput
        
        do {
            videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
        } catch {
            return
        }
        
        if captureSession.canAddInput(videoInput) {
            captureSession.addInput(videoInput)
        } else {
            return
        }
        
        let metadataOutput = AVCaptureMetadataOutput()
        
        if captureSession.canAddOutput(metadataOutput) {
            captureSession.addOutput(metadataOutput)
            metadataOutput.setMetadataObjectsDelegate(delegate, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession.isRunning {
            captureSession.stopRunning()
        }
    }
}
EOF

# Views/ChatView.swift
cat > QuicPair/Views/ChatView.swift << 'EOF'
import SwiftUI

struct ChatView: View {
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var appState: AppState
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 12) {
                            ForEach(chatService.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if chatService.isLoading {
                                HStack {
                                    TypingIndicator()
                                    Spacer()
                                }
                                .padding(.horizontal)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: chatService.messages.count) { _ in
                        withAnimation {
                            proxy.scrollTo(chatService.messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                // Input Area
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(.roundedBorder)
                        .focused($isInputFocused)
                        .onSubmit { sendMessage() }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title2)
                            .foregroundColor(messageText.isEmpty ? .gray : .accentColor)
                    }
                    .disabled(messageText.isEmpty || chatService.isLoading)
                }
                .padding()
                .background(Color(UIColor.systemBackground))
            }
            .navigationTitle("Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { appState.isConnected = false }) {
                        Text("Disconnect")
                            .foregroundColor(.red)
                    }
                }
            }
        }
        .onAppear {
            isInputFocused = true
        }
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let message = messageText
        messageText = ""
        
        Task {
            await chatService.sendMessage(message)
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
                .background(message.isUser ? Color.accentColor : Color(UIColor.secondarySystemBackground))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(20)
            
            if !message.isUser { Spacer() }
        }
    }
}

struct TypingIndicator: View {
    @State private var animationAmount = 0.0
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { index in
                Circle()
                    .fill(Color.gray)
                    .frame(width: 8, height: 8)
                    .scaleEffect(animationAmount)
                    .opacity(animationAmount)
                    .animation(
                        Animation.easeInOut(duration: 0.6)
                            .repeatForever()
                            .delay(Double(index) * 0.2),
                        value: animationAmount
                    )
            }
        }
        .onAppear {
            animationAmount = 1.0
        }
    }
}
EOF

# Views/ManualConnectionView.swift
cat > QuicPair/Views/ManualConnectionView.swift << 'EOF'
import SwiftUI

struct ManualConnectionView: View {
    @EnvironmentObject var connectionManager: ConnectionManager
    @Environment(\.dismiss) var dismiss
    @State private var serverAddress = ""
    @State private var port = "8443"
    
    var body: some View {
        NavigationView {
            Form {
                Section("Server Details") {
                    TextField("Server Address", text: $serverAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    
                    TextField("Port", text: $port)
                        .keyboardType(.numberPad)
                }
                
                Section {
                    Button(action: connect) {
                        Text("Connect")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(serverAddress.isEmpty)
                }
            }
            .navigationTitle("Manual Connection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func connect() {
        guard let url = URL(string: "https://\(serverAddress):\(port)") else { return }
        connectionManager.connectToServer(url: url)
        dismiss()
    }
}
EOF

# Views/TTFTChartView.swift
cat > QuicPair/Views/TTFTChartView.swift << 'EOF'
import SwiftUI

struct TTFTChartView: View {
    let measurements: [Double]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("TTFT Performance")
                .font(.headline)
            
            GeometryReader { geometry in
                Path { path in
                    guard measurements.count > 1 else { return }
                    
                    let maxValue = measurements.max() ?? 1
                    let xStep = geometry.size.width / CGFloat(measurements.count - 1)
                    let yScale = geometry.size.height / CGFloat(maxValue)
                    
                    path.move(to: CGPoint(x: 0, y: geometry.size.height - (measurements[0] * yScale)))
                    
                    for index in 1..<measurements.count {
                        let x = CGFloat(index) * xStep
                        let y = geometry.size.height - (measurements[index] * yScale)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(Color.accentColor, lineWidth: 2)
            }
            .frame(height: 100)
            
            HStack {
                Text("Avg: \(Int(measurements.reduce(0, +) / Double(measurements.count)))ms")
                    .font(.caption)
                Spacer()
                Text("Last: \(Int(measurements.last ?? 0))ms")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding()
        .background(Color.secondary.opacity(0.1))
        .cornerRadius(10)
    }
}
EOF

# Services/ConnectionManager.swift
cat > QuicPair/Services/ConnectionManager.swift << 'EOF'
import Foundation
import Combine

class ConnectionManager: ObservableObject {
    @Published var isConnected = false
    @Published var recentConnections: [RecentConnection] = []
    @Published var connectionError: String?
    
    private var serverURL: URL?
    
    init() {
        loadRecentConnections()
    }
    
    func connectToServer(url: URL) {
        serverURL = url
        
        // Simulate connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.isConnected = true
            self.saveConnection(url: url)
        }
    }
    
    func connect(to connection: RecentConnection) {
        if let url = URL(string: connection.serverURL) {
            connectToServer(url: url)
        }
    }
    
    func disconnect() {
        isConnected = false
        serverURL = nil
    }
    
    private func saveConnection(url: URL) {
        let connection = RecentConnection(
            deviceName: "Mac Studio",
            serverURL: url.absoluteString,
            lastConnected: Date()
        )
        
        recentConnections.insert(connection, at: 0)
        if recentConnections.count > 5 {
            recentConnections.removeLast()
        }
        
        saveRecentConnections()
    }
    
    private func loadRecentConnections() {
        if let data = UserDefaults.standard.data(forKey: "recentConnections"),
           let connections = try? JSONDecoder().decode([RecentConnection].self, from: data) {
            recentConnections = connections
        }
    }
    
    private func saveRecentConnections() {
        if let data = try? JSONEncoder().encode(recentConnections) {
            UserDefaults.standard.set(data, forKey: "recentConnections")
        }
    }
}
EOF

# Services/ChatService.swift
cat > QuicPair/Services/ChatService.swift << 'EOF'
import Foundation
import Combine

@MainActor
class ChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var lastTTFT: Int?
    
    func sendMessage(_ text: String) async {
        // Add user message
        messages.append(ChatMessage(content: text, isUser: true))
        
        // Start loading
        isLoading = true
        let startTime = Date()
        
        // Simulate API call
        try? await Task.sleep(nanoseconds: 150_000_000) // 150ms
        
        // Calculate TTFT
        lastTTFT = Int(Date().timeIntervalSince(startTime) * 1000)
        
        // Add AI response
        let response = "This is a simulated response to: \(text)"
        messages.append(ChatMessage(content: response, isUser: false))
        
        isLoading = false
    }
}
EOF

# Services/NoiseManager.swift
cat > QuicPair/Services/NoiseManager.swift << 'EOF'
import Foundation
import CryptoKit

class NoiseManager: ObservableObject {
    private var privateKey: Curve25519.KeyAgreement.PrivateKey?
    
    init() {
        loadOrGenerateKey()
    }
    
    private func loadOrGenerateKey() {
        if let keyData = KeychainHelper.load(key: "noisePrivateKey") {
            privateKey = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: keyData)
        }
        
        if privateKey == nil {
            privateKey = Curve25519.KeyAgreement.PrivateKey()
            if let keyData = privateKey?.rawRepresentation {
                KeychainHelper.save(key: "noisePrivateKey", data: keyData)
            }
        }
    }
    
    var publicKey: Data? {
        privateKey?.publicKey.rawRepresentation
    }
}

struct KeychainHelper {
    static func save(key: String, data: Data) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        SecItemDelete(query as CFDictionary)
        SecItemAdd(query as CFDictionary, nil)
    }
    
    static func load(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true
        ]
        
        var result: AnyObject?
        SecItemCopyMatching(query as CFDictionary, &result)
        return result as? Data
    }
}
EOF

echo "✅ All Swift files created!"