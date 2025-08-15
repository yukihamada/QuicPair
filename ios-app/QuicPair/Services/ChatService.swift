import Foundation
import Combine

@MainActor
class ChatService: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var lastTTFT: Int?
    
    private var connectionManager: ConnectionManager?
    
    func setConnectionManager(_ manager: ConnectionManager) {
        self.connectionManager = manager
    }
    
    func sendMessage(_ text: String) async {
        // Add user message
        messages.append(ChatMessage(content: text, isUser: true))
        
        // Start loading
        isLoading = true
        let startTime = Date()
        
        do {
            // Send to Mac server
            if let serverURL = connectionManager?.serverBaseURL {
                let response = try await sendToServer(prompt: text, serverURL: serverURL)
                
                // Calculate TTFT
                lastTTFT = Int(Date().timeIntervalSince(startTime) * 1000)
                
                // Add AI response
                messages.append(ChatMessage(content: response, isUser: false))
            } else {
                throw NSError(domain: "ChatService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Not connected to server"])
            }
        } catch {
            // Add error message
            messages.append(ChatMessage(content: "Error: \(error.localizedDescription)", isUser: false))
        }
        
        isLoading = false
    }
    
    private func sendToServer(prompt: String, serverURL: URL) async throws -> String {
        var request = URLRequest(url: serverURL.appendingPathComponent("chat"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body = ["prompt": prompt]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        // Use standard URLSession for HTTP
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw NSError(domain: "ChatService", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid response from server"])
        }
        
        if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
           let responseText = json["response"] as? String {
            return responseText
        }
        
        throw NSError(domain: "ChatService", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invalid response format"])
    }
}

