import Foundation
import Network
import Combine
import Darwin

class ServerManager: ObservableObject {
    static let shared = ServerManager()
    
    @Published var isServerRunning = false
    @Published var isClientConnected = false
    @Published var connectionURL = ""
    @Published var lastTTFT: Int?
    
    private var listener: NWListener?
    private let port: UInt16 = 8888
    
    init() {
        updateConnectionURL()
    }
    
    func startServer() {
        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true
        
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
        connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { [weak self] data, _, isComplete, error in
            guard let self = self, let data = data, !data.isEmpty else { return }
            
            let request = String(data: data, encoding: .utf8) ?? ""
            print("Received request: \(request.prefix(100))...")
            
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
                self.handleChatRequest(data: data, connection: connection)
            } else {
                // Send 404 for unknown paths
                let response = Data("HTTP/1.1 404 Not Found\r\nContent-Length: 0\r\n\r\n".utf8)
                connection.send(content: response, completion: .contentProcessed { _ in
                    connection.cancel()
                })
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
        
        let body: [String: Any] = [
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
            connectionURL = "http://\(ip):\(port)"
        } else {
            connectionURL = "http://localhost:\(port)"
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
