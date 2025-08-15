import Foundation

class OllamaService: ObservableObject {
    @Published var isRunning = false
    @Published var availableModels: [String] = []
    @Published var currentModel: String?
    @Published var isDownloading = false
    @Published var downloadProgress: Double = 0
    
    private let baseURL = "http://127.0.0.1:11434"
    private var streamTask: URLSessionDataTask?
    
    init() {
        checkStatus()
        loadModels()
    }
    
    func checkStatus() {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isRunning = error == nil && (response as? HTTPURLResponse)?.statusCode == 200
                if self?.isRunning == true {
                    self?.loadModels()
                }
            }
        }.resume()
    }
    
    func loadModels() {
        guard let url = URL(string: "\(baseURL)/api/tags") else { return }
        
        URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let models = json["models"] as? [[String: Any]] else { return }
            
            DispatchQueue.main.async {
                self?.availableModels = models.compactMap { $0["name"] as? String }
                if self?.currentModel == nil {
                    self?.currentModel = self?.availableModels.first ?? "llama3.1:8b"
                }
            }
        }.resume()
    }
    
    func pullModel(_ modelName: String) {
        isDownloading = true
        downloadProgress = 0
        
        guard let url = URL(string: "\(baseURL)/api/pull") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["name": modelName, "stream": true]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let session = URLSession(configuration: .default, delegate: StreamDelegate { [weak self] progress in
            DispatchQueue.main.async {
                self?.downloadProgress = progress
            }
        }, delegateQueue: nil)
        
        session.dataTask(with: request) { [weak self] _, _, error in
            DispatchQueue.main.async {
                self?.isDownloading = false
                if error == nil {
                    self?.loadModels()
                }
            }
        }.resume()
    }
    
    func streamChat(prompt: String, onToken: @escaping (String) -> Void, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: "\(baseURL)/api/chat") else {
            completion(false)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": currentModel ?? "llama3.1:8b",
            "messages": [["role": "user", "content": prompt]],
            "stream": true
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        let session = URLSession(configuration: .default, delegate: nil, delegateQueue: nil)
        streamTask = session.dataTask(with: request)
        
        let delegate = StreamChatDelegate { token in
            onToken(token)
        } completion: { success in
            completion(success)
        }
        
        let streamSession = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)
        streamTask = streamSession.dataTask(with: request)
        streamTask?.resume()
    }
    
    func startOllama() {
        // Check if Ollama is installed
        let checkProcess = Process()
        checkProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        checkProcess.arguments = ["ollama"]
        
        let pipe = Pipe()
        checkProcess.standardOutput = pipe
        
        do {
            try checkProcess.run()
            checkProcess.waitUntilExit()
            
            if checkProcess.terminationStatus == 0,
               let output = String(data: pipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8),
               !output.isEmpty {
                // Ollama is installed, start it
                let ollamaProcess = Process()
                ollamaProcess.executableURL = URL(fileURLWithPath: output.trimmingCharacters(in: .whitespacesAndNewlines))
                ollamaProcess.arguments = ["serve"]
                try ollamaProcess.run()
                
                // Wait a bit and check status
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                    self.checkStatus()
                }
            }
        } catch {
            print("Failed to start Ollama: \(error)")
        }
    }
}

// MARK: - Stream Delegate
private class StreamDelegate: NSObject, URLSessionDataDelegate {
    let progressHandler: (Double) -> Void
    
    init(progressHandler: @escaping (Double) -> Void) {
        self.progressHandler = progressHandler
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        // Parse streaming JSON for progress
        if let _ = String(data: data, encoding: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let status = json["status"] as? [String: Any],
           let total = status["total"] as? Double,
           let completed = status["completed"] as? Double {
            progressHandler(completed / total)
        }
    }
}

// MARK: - Stream Chat Delegate
private class StreamChatDelegate: NSObject, URLSessionDataDelegate {
    let tokenHandler: (String) -> Void
    let completionHandler: (Bool) -> Void
    private var receivedData = Data()
    
    init(tokenHandler: @escaping (String) -> Void, completion: @escaping (Bool) -> Void) {
        self.tokenHandler = tokenHandler
        self.completionHandler = completion
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        receivedData.append(data)
        
        // Process the data line by line
        if let string = String(data: receivedData, encoding: .utf8) {
            let lines = string.components(separatedBy: "\n")
            
            for line in lines where !line.isEmpty {
                if let data = line.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    
                    if let message = json["message"] as? [String: Any],
                       let content = message["content"] as? String {
                        tokenHandler(content)
                    }
                    
                    if let done = json["done"] as? Bool, done {
                        completionHandler(true)
                        return
                    }
                }
            }
            
            // Keep only the last incomplete line
            if let lastNewline = string.lastIndex(of: "\n") {
                let nextIndex = string.index(after: lastNewline)
                receivedData = String(string[nextIndex...]).data(using: .utf8) ?? Data()
            }
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        completionHandler(error == nil)
    }
}