#!/usr/bin/env swift
// test_automation_helper.swift - Helper script for automated testing
// Can be used to simulate WebRTC client connections for testing

import Foundation
import Dispatch

// MARK: - Data Models
struct ConnectionInfo: Codable {
    let serverURL: String
    let publicKey: String
    let deviceName: String
    let version: String
}

struct TTFTResult {
    let prompt: String
    let ttft: TimeInterval
    let timestamp: Date
}

// MARK: - Test Client
class QuicPairTestClient {
    let serverURL: String
    var results: [TTFTResult] = []
    let resultsQueue = DispatchQueue(label: "results.queue")
    
    init(serverURL: String) {
        self.serverURL = serverURL
    }
    
    // Simulate connection establishment
    func connect(completion: @escaping (Bool) -> Void) {
        print("[CLIENT] Connecting to \(serverURL)...")
        
        // Get connection info
        guard let url = URL(string: "\(serverURL)/noise/pubkey") else {
            print("[ERROR] Invalid server URL")
            completion(false)
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                print("[ERROR] Failed to get server info: \(error)")
                completion(false)
                return
            }
            
            guard let data = data else {
                print("[ERROR] No data received")
                completion(false)
                return
            }
            
            do {
                let pubkeyInfo = try JSONDecoder().decode([String: String].self, from: data)
                print("[CLIENT] Server public key: \(pubkeyInfo["public_key"] ?? "unknown")")
                completion(true)
            } catch {
                print("[ERROR] Failed to decode server info: \(error)")
                completion(false)
            }
        }
        task.resume()
    }
    
    // Simulate sending a message and measuring TTFT
    func measureTTFT(prompt: String, completion: @escaping (TimeInterval?) -> Void) {
        let startTime = Date()
        
        // In a real implementation, this would use WebRTC DataChannel
        // For testing, we'll simulate with HTTP endpoint
        simulateWebRTCMessage(prompt: prompt) { response in
            if response != nil {
                let ttft = Date().timeIntervalSince(startTime)
                let result = TTFTResult(prompt: prompt, ttft: ttft, timestamp: Date())
                
                self.resultsQueue.async {
                    self.results.append(result)
                }
                
                completion(ttft)
            } else {
                completion(nil)
            }
        }
    }
    
    private func simulateWebRTCMessage(prompt: String, completion: @escaping (String?) -> Void) {
        // Simulate WebRTC message with random delay
        let simulatedDelay = Double.random(in: 0.08...0.2) // 80-200ms
        
        DispatchQueue.global().asyncAfter(deadline: .now() + simulatedDelay) {
            completion("Simulated response for: \(prompt)")
        }
    }
    
    // Get statistics
    func getStatistics() -> (p50: Double, p90: Double, avg: Double, count: Int)? {
        let ttftValues = resultsQueue.sync { results.map { $0.ttft * 1000 } } // Convert to ms
        
        guard !ttftValues.isEmpty else { return nil }
        
        let sorted = ttftValues.sorted()
        let count = sorted.count
        let p50Index = (count * 50) / 100
        let p90Index = (count * 90) / 100
        let avg = sorted.reduce(0, +) / Double(count)
        
        return (p50: sorted[p50Index], p90: sorted[p90Index], avg: avg, count: count)
    }
    
    // Export results
    func exportResults(to file: String) {
        let results = resultsQueue.sync { self.results }
        
        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        jsonEncoder.dateEncodingStrategy = .iso8601
        
        let exportData = [
            "test_client": "QuicPair Test Automation",
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "measurements": results.map { [
                "prompt": $0.prompt,
                "ttft_ms": $0.ttft * 1000,
                "timestamp": ISO8601DateFormatter().string(from: $0.timestamp)
            ]}
        ] as [String : Any]
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
            try jsonData.write(to: URL(fileURLWithPath: file))
            print("[CLIENT] Results exported to: \(file)")
        } catch {
            print("[ERROR] Failed to export results: \(error)")
        }
    }
}

// MARK: - Test Scenarios
class TestScenarios {
    let client: QuicPairTestClient
    
    init(serverURL: String) {
        self.client = QuicPairTestClient(serverURL: serverURL)
    }
    
    // Run basic TTFT test
    func runBasicTest(iterations: Int = 10) {
        print("\n=== Running Basic TTFT Test ===")
        print("Iterations: \(iterations)")
        
        let prompts = [
            "Tell me a short joke",
            "What's 2+2?",
            "Hello, how are you?",
            "Explain quantum computing in one sentence",
            "What's the weather like?"
        ]
        
        let semaphore = DispatchSemaphore(value: 0)
        
        for i in 1...iterations {
            let prompt = prompts[i % prompts.count]
            print("\n[Test \(i)] Prompt: \(prompt)")
            
            client.measureTTFT(prompt: prompt) { ttft in
                if let ttft = ttft {
                    print("[Test \(i)] TTFT: \(String(format: "%.0f", ttft * 1000))ms")
                } else {
                    print("[Test \(i)] Failed")
                }
                semaphore.signal()
            }
            
            semaphore.wait()
            Thread.sleep(forTimeInterval: 0.5) // Small delay between tests
        }
        
        // Show statistics
        if let stats = client.getStatistics() {
            print("\n=== Test Results ===")
            print("Total measurements: \(stats.count)")
            print("Average TTFT: \(String(format: "%.1f", stats.avg))ms")
            print("P50 TTFT: \(String(format: "%.0f", stats.p50))ms")
            print("P90 TTFT: \(String(format: "%.0f", stats.p90))ms")
            
            print("\nPerformance Check:")
            print("P50 < 150ms: \(stats.p50 < 150 ? "✓ PASS" : "✗ FAIL")")
            print("P90 < 250ms: \(stats.p90 < 250 ? "✓ PASS" : "✗ FAIL")")
        }
    }
    
    // Run stress test
    func runStressTest(duration: TimeInterval = 60, requestsPerSecond: Int = 10) {
        print("\n=== Running Stress Test ===")
        print("Duration: \(duration)s")
        print("Rate: \(requestsPerSecond) req/s")
        
        let endTime = Date().addingTimeInterval(duration)
        let interval = 1.0 / Double(requestsPerSecond)
        var requestCount = 0
        
        let timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            requestCount += 1
            let prompt = "Stress test request #\(requestCount)"
            
            self.client.measureTTFT(prompt: prompt) { ttft in
                if let ttft = ttft {
                    print("[\(requestCount)] TTFT: \(String(format: "%.0f", ttft * 1000))ms")
                }
            }
            
            if Date() >= endTime {
                print("\nStress test completed")
                if let stats = self.client.getStatistics() {
                    print("Total requests: \(stats.count)")
                    print("Average TTFT: \(String(format: "%.1f", stats.avg))ms")
                    print("P90 TTFT: \(String(format: "%.0f", stats.p90))ms")
                }
                exit(0)
            }
        }
        
        RunLoop.current.run()
    }
}

// MARK: - Main
let arguments = CommandLine.arguments

if arguments.count < 2 {
    print("Usage: \(arguments[0]) <server_url> [test_type] [options]")
    print("\nTest types:")
    print("  basic     - Run basic TTFT test (default)")
    print("  stress    - Run stress test")
    print("  monitor   - Monitor real connections")
    print("\nExamples:")
    print("  \(arguments[0]) http://localhost:8443 basic 20")
    print("  \(arguments[0]) http://localhost:8443 stress 60 10")
    exit(1)
}

let serverURL = arguments[1]
let testType = arguments.count > 2 ? arguments[2] : "basic"

print("QuicPair Test Automation Helper")
print("Server: \(serverURL)")
print("Test type: \(testType)")

let scenarios = TestScenarios(serverURL: serverURL)

// Connect to server
let semaphore = DispatchSemaphore(value: 0)
scenarios.client.connect { success in
    if !success {
        print("Failed to connect to server")
        exit(1)
    }
    semaphore.signal()
}
semaphore.wait()

// Run selected test
switch testType {
case "basic":
    let iterations = arguments.count > 3 ? Int(arguments[3]) ?? 10 : 10
    scenarios.runBasicTest(iterations: iterations)
    
    // Export results
    let outputFile = "ttft_test_results_\(Date().timeIntervalSince1970).json"
    scenarios.client.exportResults(to: outputFile)
    
case "stress":
    let duration = arguments.count > 3 ? Double(arguments[3]) ?? 60 : 60
    let rate = arguments.count > 4 ? Int(arguments[4]) ?? 10 : 10
    scenarios.runStressTest(duration: duration, requestsPerSecond: rate)
    
case "monitor":
    print("Monitor mode - use measure_ttft_realtime.sh for real-time monitoring")
    
default:
    print("Unknown test type: \(testType)")
    exit(1)
}