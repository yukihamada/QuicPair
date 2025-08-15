import SwiftUI
import CoreImage.CIFilterBuiltins

struct ContentView: View {
    @EnvironmentObject var serverManager: ServerManager
    @State private var showQRCode = true
    @State private var messageText = ""
    
    var body: some View {
        ZStack {
            ChatView()
                .opacity(showQRCode ? 0 : 1)
            
            if showQRCode {
                QRCodeView(showQRCode: $showQRCode)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showQRCode)
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
