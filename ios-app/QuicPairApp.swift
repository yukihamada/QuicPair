import SwiftUI
import AVFoundation
import WebRTC

@main
struct QuicPairApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @StateObject private var connectionManager = ConnectionManager()
    @State private var showingScanner = false
    @State private var showingChat = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 10) {
                    Image(systemName: "bolt.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.blue)
                    
                    Text("QuicPair")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Ultra-fast P2P LLM")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 50)
                
                // Status
                VStack(spacing: 5) {
                    Label(connectionManager.isConnected ? "Connected" : "Not Connected", 
                          systemImage: connectionManager.isConnected ? "checkmark.circle.fill" : "xmark.circle")
                        .foregroundColor(connectionManager.isConnected ? .green : .gray)
                    
                    if let serverInfo = connectionManager.serverInfo {
                        Text(serverInfo)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                
                Spacer()
                
                // Actions
                if connectionManager.isConnected {
                    Button(action: {
                        showingChat = true
                    }) {
                        Label("Start Chat", systemImage: "message.fill")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    Button(action: {
                        connectionManager.disconnect()
                    }) {
                        Label("Disconnect", systemImage: "xmark.circle")
                            .foregroundColor(.red)
                    }
                } else {
                    Button(action: {
                        showingScanner = true
                    }) {
                        Label("Scan QR Code", systemImage: "qrcode.viewfinder")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                // Recent connections
                if !connectionManager.recentConnections.isEmpty {
                    VStack(alignment: .leading) {
                        Text("Recent Connections")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(connectionManager.recentConnections, id: \.self) { server in
                            Button(action: {
                                connectionManager.connectToServer(server)
                            }) {
                                HStack {
                                    Image(systemName: "clock")
                                    Text(server)
                                    Spacer()
                                }
                                .padding()
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(8)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationBarHidden(true)
        }
        .sheet(isPresented: $showingScanner) {
            QRScannerView(connectionManager: connectionManager)
        }
        .sheet(isPresented: $showingChat) {
            ChatView(connectionManager: connectionManager)
        }
    }
}

// QR Scanner View
struct QRScannerView: View {
    @ObservedObject var connectionManager: ConnectionManager
    @Environment(\.presentationMode) var presentationMode
    @State private var isScanning = true
    
    var body: some View {
        NavigationView {
            ZStack {
                QRCodeScanner { code in
                    if isScanning {
                        isScanning = false
                        handleScannedCode(code)
                    }
                }
                
                VStack {
                    Spacer()
                    
                    Text("Point camera at QuicPair QR code")
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(10)
                        .padding(.bottom, 50)
                }
            }
            .navigationTitle("Scan QR Code")
            .navigationBarItems(trailing: Button("Cancel") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    func handleScannedCode(_ code: String) {
        // Parse QR code JSON
        guard let data = code.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let server = json["server"] as? String,
              let publicKey = json["publicKey"] as? String else {
            print("Invalid QR code")
            return
        }
        
        // Connect to server
        connectionManager.connectWithQRData(server: server, publicKey: publicKey)
        
        // Dismiss scanner
        presentationMode.wrappedValue.dismiss()
    }
}

// QR Code Scanner using AVFoundation
struct QRCodeScanner: UIViewControllerRepresentable {
    var didFindCode: (String) -> Void
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let controller = QRScannerViewController()
        controller.delegate = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(didFindCode: didFindCode)
    }
    
    class Coordinator: NSObject, QRScannerDelegate {
        var didFindCode: (String) -> Void
        
        init(didFindCode: @escaping (String) -> Void) {
            self.didFindCode = didFindCode
        }
        
        func didFind(code: String) {
            didFindCode(code)
        }
    }
}

protocol QRScannerDelegate: AnyObject {
    func didFind(code: String)
}

class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    weak var delegate: QRScannerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        captureSession = AVCaptureSession()
        
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
            
            metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
            metadataOutput.metadataObjectTypes = [.qr]
        } else {
            return
        }
        
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = view.layer.bounds
        previewLayer.videoGravity = .resizeAspectFill
        view.layer.addSublayer(previewLayer)
        
        captureSession.startRunning()
    }
    
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        captureSession.stopRunning()
        
        if let metadataObject = metadataObjects.first {
            guard let readableObject = metadataObject as? AVMetadataMachineReadableCodeObject else { return }
            guard let stringValue = readableObject.stringValue else { return }
            
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            delegate?.didFind(code: stringValue)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if captureSession?.isRunning == false {
            captureSession.startRunning()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        if captureSession?.isRunning == true {
            captureSession.stopRunning()
        }
    }
}

// Chat View
struct ChatView: View {
    @ObservedObject var connectionManager: ConnectionManager
    @State private var messageText = ""
    @State private var messages: [ChatMessage] = []
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            VStack {
                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(messages) { message in
                                MessageBubble(message: message)
                            }
                            .onChange(of: messages.count) { _ in
                                withAnimation {
                                    proxy.scrollTo(messages.last?.id, anchor: .bottom)
                                }
                            }
                        }
                        .padding()
                    }
                }
                
                // Input
                HStack {
                    TextField("Type a message...", text: $messageText)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            sendMessage()
                        }
                    
                    Button(action: sendMessage) {
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.title)
                            .foregroundColor(.blue)
                    }
                    .disabled(messageText.isEmpty)
                }
                .padding()
            }
            .navigationTitle("Chat")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
            .onAppear {
                setupMessageHandler()
            }
        }
    }
    
    func sendMessage() {
        guard !messageText.isEmpty else { return }
        
        let userMessage = ChatMessage(text: messageText, isUser: true)
        messages.append(userMessage)
        
        connectionManager.sendMessage(messageText)
        messageText = ""
    }
    
    func setupMessageHandler() {
        connectionManager.onMessageReceived = { content in
            DispatchQueue.main.async {
                if let lastMessage = messages.last, !lastMessage.isUser {
                    // Append to existing AI message
                    messages[messages.count - 1].text += content
                } else {
                    // Create new AI message
                    messages.append(ChatMessage(text: content, isUser: false))
                }
            }
        }
    }
}

struct MessageBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
            }
            
            Text(message.text)
                .padding()
                .background(message.isUser ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.isUser ? .white : .primary)
                .cornerRadius(15)
            
            if !message.isUser {
                Spacer()
            }
        }
    }
}

struct ChatMessage: Identifiable {
    let id = UUID()
    var text: String
    let isUser: Bool
}

// Connection Manager (simplified WebRTC)
class ConnectionManager: ObservableObject {
    @Published var isConnected = false
    @Published var serverInfo: String?
    @Published var recentConnections: [String] = []
    
    var onMessageReceived: ((String) -> Void)?
    
    private var peerConnection: RTCPeerConnection?
    private var dataChannel: RTCDataChannel?
    private var serverURL: String?
    private var serverPublicKey: String?
    
    init() {
        // Load recent connections
        if let saved = UserDefaults.standard.array(forKey: "recentConnections") as? [String] {
            recentConnections = saved
        }
    }
    
    func connectWithQRData(server: String, publicKey: String) {
        self.serverURL = "http://\(server)"
        self.serverPublicKey = publicKey
        self.serverInfo = server
        
        // Save to recent
        if !recentConnections.contains(server) {
            recentConnections.insert(server, at: 0)
            if recentConnections.count > 5 {
                recentConnections.removeLast()
            }
            UserDefaults.standard.set(recentConnections, forKey: "recentConnections")
        }
        
        // Start WebRTC connection
        createPeerConnection()
    }
    
    func connectToServer(_ server: String) {
        // Reconnect to recent server
        connectWithQRData(server: server, publicKey: "")
    }
    
    func disconnect() {
        dataChannel?.close()
        peerConnection?.close()
        peerConnection = nil
        dataChannel = nil
        isConnected = false
        serverInfo = nil
    }
    
    func sendMessage(_ text: String) {
        let message = ["op": "chat", "prompt": text, "model": ""]
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: data, encoding: .utf8) {
            dataChannel?.sendData(RTCDataBuffer(data: jsonString.data(using: .utf8)!, isBinary: false))
        }
    }
    
    private func createPeerConnection() {
        let config = RTCConfiguration()
        config.iceServers = [RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])]
        
        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        
        guard let factory = RTCPeerConnectionFactory() else { return }
        
        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: nil)
        
        // Create data channel
        let dataChannelConfig = RTCDataChannelConfiguration()
        dataChannelConfig.isOrdered = true
        
        dataChannel = peerConnection?.dataChannel(forLabel: "llm", configuration: dataChannelConfig)
        setupDataChannel()
        
        // Create offer
        peerConnection?.offer(for: constraints) { sdp, error in
            guard let sdp = sdp else { return }
            
            self.peerConnection?.setLocalDescription(sdp) { error in
                // Send offer to server
                self.sendOfferToServer(sdp: sdp.sdp)
            }
        }
    }
    
    private func setupDataChannel() {
        dataChannel?.delegate = self
    }
    
    private func sendOfferToServer(sdp: String) {
        guard let serverURL = serverURL,
              let url = URL(string: "\(serverURL)/signaling/offer") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["sdp": sdp]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let answerSDP = json["sdp"] as? String else { return }
            
            // Set remote description
            let answer = RTCSessionDescription(type: .answer, sdp: answerSDP)
            self.peerConnection?.setRemoteDescription(answer) { error in
                if error == nil {
                    DispatchQueue.main.async {
                        self.isConnected = true
                    }
                }
            }
        }.resume()
    }
}

// RTCDataChannelDelegate
extension ConnectionManager: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        print("Data channel state: \(dataChannel.readyState)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        guard let data = String(data: buffer.data, encoding: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data.data(using: .utf8)!) as? [String: Any] else { return }
        
        if let op = json["op"] as? String {
            switch op {
            case "delta":
                if let content = json["content"] as? String {
                    onMessageReceived?(content)
                }
            case "noise_pubkey":
                // Handle Noise handshake
                sendNoiseInit()
            case "done":
                // Message complete
                break
            default:
                break
            }
        }
    }
    
    private func sendNoiseInit() {
        // Simplified - just acknowledge
        let message = ["op": "noise_init", "noise_init": Data().base64EncodedString()]
        if let data = try? JSONSerialization.data(withJSONObject: message),
           let jsonString = String(data: data, encoding: .utf8) {
            dataChannel?.sendData(RTCDataBuffer(data: jsonString.data(using: .utf8)!, isBinary: false))
        }
    }
}