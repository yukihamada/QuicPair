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
        
        // Test connection to server
        var request = URLRequest(url: url.appendingPathComponent("connect"))
        request.httpMethod = "GET"
        request.timeoutInterval = 5
        
        // Use standard URLSession for HTTP
        let session = URLSession.shared
        
        session.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.connectionError = error.localizedDescription
                    self?.isConnected = false
                } else if let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 {
                    self?.isConnected = true
                    self?.saveConnection(url: url)
                    self?.connectionError = nil
                } else {
                    self?.connectionError = "Failed to connect to server"
                    self?.isConnected = false
                }
            }
        }.resume()
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
    
    var serverBaseURL: URL? {
        return serverURL
    }
}

