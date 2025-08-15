import SwiftUI
import CoreImage.CIFilterBuiltins

@main
struct QuicPairApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var serverProcess: Process?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Create menu bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "⚡"
        statusItem?.button?.target = self
        statusItem?.button?.action = #selector(showWindow)
        
        // Start server
        startServer()
    }
    
    @objc func showWindow() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.windows.first?.makeKeyAndOrderFront(nil)
    }
    
    func startServer() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/bash")
        task.arguments = ["-c", "\(NSHomeDirectory())/.quicpair/start-quicpair.sh"]
        
        do {
            try task.run()
            serverProcess = task
        } catch {
            print("Failed to start server: \(error)")
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        serverProcess?.terminate()
    }
}

struct ContentView: View {
    @State private var serverInfo: ServerInfo?
    @State private var isLoading = true
    @State private var showingChat = false
    
    var body: some View {
        VStack(spacing: 20) {
            // Header
            HStack {
                Image(systemName: "bolt.fill")
                    .font(.largeTitle)
                    .foregroundColor(.accentColor)
                Text("QuicPair")
                    .font(.largeTitle)
                    .fontWeight(.bold)
            }
            .padding(.top)
            
            if isLoading {
                ProgressView("Starting server...")
                    .padding()
            } else if let info = serverInfo {
                // QR Code
                VStack {
                    Text("Scan with iPhone")
                        .font(.headline)
                    
                    if let qrImage = generateQRCode(from: info.connectionString) {
                        Image(nsImage: qrImage)
                            .resizable()
                            .interpolation(.none)
                            .scaledToFit()
                            .frame(width: 200, height: 200)
                            .padding()
                            .background(Color.white)
                            .cornerRadius(10)
                    }
                    
                    // Connection info
                    VStack(alignment: .leading, spacing: 5) {
                        Label(info.server, systemImage: "network")
                        Label("Model: \(info.model)", systemImage: "cpu")
                        Label("TTFT: <150ms", systemImage: "timer")
                    }
                    .font(.caption)
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                }
                
                // Actions
                HStack {
                    Button("Show Chat") {
                        showingChat = true
                    }
                    
                    Button("Copy Info") {
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(info.connectionString, forType: .string)
                    }
                }
                .padding(.bottom)
            }
        }
        .frame(width: 400, height: 500)
        .padding()
        .onAppear {
            // Load server info after delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                loadServerInfo()
            }
        }
        .sheet(isPresented: $showingChat) {
            ChatView()
        }
    }
    
    func loadServerInfo() {
        // Get server info
        if let url = URL(string: "http://localhost:8443/noise/pubkey") {
            URLSession.shared.dataTask(with: url) { data, _, _ in
                if let data = data,
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let publicKey = json["public_key"] as? String {
                    
                    // Get local IP
                    let localIP = getLocalIP() ?? "localhost"
                    
                    DispatchQueue.main.async {
                        self.serverInfo = ServerInfo(
                            server: "\(localIP):8443",
                            publicKey: publicKey,
                            model: "qwen2.5:3b / smollm2:135m"
                        )
                        self.isLoading = false
                    }
                }
            }.resume()
        }
    }
    
    func generateQRCode(from string: String) -> NSImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"
        
        if let outputImage = filter.outputImage {
            let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return NSImage(cgImage: cgImage, size: NSSize(width: 200, height: 200))
            }
        }
        
        return nil
    }
    
    func getLocalIP() -> String? {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/sbin/ifconfig")
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            
            // Parse IP address
            let lines = output.components(separatedBy: "\n")
            for line in lines {
                if line.contains("inet ") && !line.contains("127.0.0.1") {
                    let components = line.components(separatedBy: " ")
                    for (index, component) in components.enumerated() {
                        if component == "inet" && index + 1 < components.count {
                            return components[index + 1]
                        }
                    }
                }
            }
        } catch {
            print("Failed to get IP: \(error)")
        }
        
        return nil
    }
}

struct ServerInfo {
    let server: String
    let publicKey: String
    let model: String
    
    var connectionString: String {
        return "{\"server\":\"\(server)\",\"publicKey\":\"\(publicKey)\",\"protocol\":\"Noise_IK\"}"
    }
}

struct ChatView: View {
    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false
    
    var body: some View {
        VStack {
            // Chat messages
            ScrollView {
                VStack(alignment: .leading, spacing: 10) {
                    ForEach(messages) { message in
                        HStack {
                            if message.isUser {
                                Spacer()
                                Text(message.text)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            } else {
                                Text(message.text)
                                    .padding()
                                    .background(Color.gray.opacity(0.2))
                                    .cornerRadius(10)
                                Spacer()
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            
            // Input
            HStack {
                TextField("Type a message...", text: $inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onSubmit {
                        sendMessage()
                    }
                
                Button("Send") {
                    sendMessage()
                }
                .disabled(inputText.isEmpty || isLoading)
            }
            .padding()
        }
        .frame(width: 600, height: 400)
        .navigationTitle("QuicPair Chat")
    }
    
    func sendMessage() {
        guard !inputText.isEmpty else { return }
        
        // Add user message
        messages.append(ChatMessage(text: inputText, isUser: true))
        let prompt = inputText
        inputText = ""
        isLoading = true
        
        // Add placeholder for response
        messages.append(ChatMessage(text: "...", isUser: false))
        
        // Send to local Ollama
        Task {
            await streamChat(prompt: prompt)
        }
    }
    
    func streamChat(prompt: String) async {
        let url = URL(string: "http://localhost:11434/api/chat")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let model = prompt.count < 20 ? "smollm2:135m" : "qwen2.5:3b"
        
        let body: [String: Any] = [
            "model": model,
            "messages": [["role": "user", "content": prompt]],
            "stream": true
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (bytes, _) = try await URLSession.shared.bytes(for: request)
            
            var responseText = ""
            let responseIndex = messages.count - 1
            
            for try await line in bytes.lines {
                if let data = line.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let message = json["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    responseText += content
                    
                    await MainActor.run {
                        messages[responseIndex] = ChatMessage(text: responseText, isUser: false)
                    }
                }
            }
            
            await MainActor.run {
                isLoading = false
            }
        } catch {
            await MainActor.run {
                messages[messages.count - 1] = ChatMessage(text: "Error: \(error.localizedDescription)", isUser: false)
                isLoading = false
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
}