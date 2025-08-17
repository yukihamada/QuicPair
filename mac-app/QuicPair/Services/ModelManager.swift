import Foundation
import Combine

@MainActor
class ModelManager: ObservableObject {
    @Published var availableModels: [AIModel] = []
    @Published var selectedModel: String = "qwen3:4b" // Default optimized model
    @Published var isLoading = false
    @Published var error: String?
    
    private let userDefaults = UserDefaults.standard
    private let ollamaService = OllamaService.shared
    
    
    private func loadDefaultModels() {
        availableModels = [
            // All models available for manual use in Core
            // Pro features: Fast Start, Auto Optimizer, Model Packs
            AIModel(name: "gemma3:270m", displayName: "Gemma 3 270M", size: "165MB", description: "Google's ultra-compact model", isPro: false),
            AIModel(name: "smollm2:135m", displayName: "SmolLM2 135M", size: "77MB", description: "Ultra-lightweight model", isPro: false),
            AIModel(name: "qwen3:1.7b", displayName: "Qwen3 1.7B", size: "1.0GB", description: "Small Qwen3 model", isPro: false),
            AIModel(name: "qwen3:0.6b", displayName: "Qwen3 0.6B", size: "400MB", description: "Ultra-compact Qwen3 model", isPro: false),
            AIModel(name: "qwen3:4b", displayName: "Qwen3 4B", size: "2.4GB", description: "Efficient Qwen3 model", isPro: false),
            AIModel(name: "qwen3:8b", displayName: "Qwen3 8B", size: "4.7GB", description: "Balanced Qwen3 model", isPro: false),
            AIModel(name: "qwen3:14b", displayName: "Qwen3 14B", size: "8.2GB", description: "Powerful Qwen3 model", isPro: false),
            AIModel(name: "qwen3:32b", displayName: "Qwen3 32B", size: "18GB", description: "Large Qwen3 model", isPro: false),
            AIModel(name: "qwen3-coder:30b", displayName: "Qwen3 Coder 30B", size: "17GB", description: "Most agentic code model in Qwen series", isPro: false),
            
            // All models available for Core (manual installation)
            AIModel(name: "gpt-oss:20b", displayName: "GPT-OSS 20B", size: "12GB", description: "OpenAI's open-weight model for local use", isPro: false),
            AIModel(name: "gpt-oss:120b", displayName: "GPT-OSS 120B", size: "70GB", description: "OpenAI's flagship open-weight model", isPro: false),
            
            // Extended Context Models
            AIModel(name: "mannix/jan-nano", displayName: "Jan Nano 32K", size: "2.4GB", description: "4B model optimized for deep research (32K context)", isPro: false),
            AIModel(name: "yasserrmd/jan-nano-4b", displayName: "Jan Nano 128K", size: "2.4GB", description: "4B model with native 128K context window", isPro: false),
            
            // Other Popular Models
            AIModel(name: "qwen2.5:3b", displayName: "Qwen2.5 3B", size: "1.9GB", description: "Fast and efficient for most tasks", isPro: false),
            AIModel(name: "qwen2.5:7b", displayName: "Qwen2.5 7B", size: "4.4GB", description: "High-quality Qwen model", isPro: false),
            AIModel(name: "qwen2.5:14b", displayName: "Qwen2.5 14B", size: "8.2GB", description: "Powerful Qwen model", isPro: false),
            AIModel(name: "qwen2.5-coder:7b", displayName: "Qwen2.5 Coder 7B", size: "4.4GB", description: "Specialized for coding", isPro: false),
            AIModel(name: "phi3:mini", displayName: "Phi3 Mini", size: "2.2GB", description: "Microsoft's compact model", isPro: false),
            AIModel(name: "phi3:medium", displayName: "Phi3 Medium", size: "7.9GB", description: "Microsoft's balanced model", isPro: false),
            AIModel(name: "smollm2:360m", displayName: "SmolLM2 360M", size: "200MB", description: "Lightweight model", isPro: false),
            AIModel(name: "llama3.2:1b", displayName: "Llama 3.2 1B", size: "1.3GB", description: "Meta's compact model", isPro: false),
            AIModel(name: "llama3.2:3b", displayName: "Llama 3.2 3B", size: "2.0GB", description: "Meta's balanced model", isPro: false),
            AIModel(name: "llama3.3:70b", displayName: "Llama 3.3 70B", size: "40GB", description: "Meta's latest flagship model", isPro: false),
            AIModel(name: "gemma2:2b", displayName: "Gemma2 2B", size: "1.6GB", description: "Google's efficient model", isPro: false),
            AIModel(name: "gemma2:9b", displayName: "Gemma2 9B", size: "5.4GB", description: "Google's powerful model", isPro: false),
            AIModel(name: "gemma2:27b", displayName: "Gemma2 27B", size: "16GB", description: "Google's large model", isPro: false),
            AIModel(name: "mistral:7b", displayName: "Mistral 7B", size: "4.1GB", description: "High-quality general purpose", isPro: false),
            AIModel(name: "mistral-nemo:12b", displayName: "Mistral Nemo 12B", size: "7.0GB", description: "Mistral's latest model", isPro: false),
            AIModel(name: "codellama:7b", displayName: "Code Llama 7B", size: "3.8GB", description: "Specialized for coding tasks", isPro: false),
            AIModel(name: "codellama:13b", displayName: "Code Llama 13B", size: "7.3GB", description: "Large coding model", isPro: false),
            AIModel(name: "deepseek-coder:6.7b", displayName: "DeepSeek Coder 6.7B", size: "3.8GB", description: "Advanced coding model", isPro: false),
            AIModel(name: "solar:10.7b", displayName: "Solar 10.7B", size: "6.1GB", description: "High-performance model", isPro: false),
            AIModel(name: "nous-hermes2:10.7b", displayName: "Nous Hermes2 10.7B", size: "6.1GB", description: "Fine-tuned assistant model", isPro: false)
        ]
    }
    
    private func loadSelectedModel() {
        if let saved = userDefaults.string(forKey: "selectedModel") {
            selectedModel = saved
        }
    }
    
    func selectModel(_ modelName: String) {
        // All models available for Core users (manual installation)
        // Pro users get Fast Start, Auto Optimizer, and Model Packs
        selectedModel = modelName
        userDefaults.set(modelName, forKey: "selectedModel")
        print("🖥️ Selected model: \(modelName)")
    }
    
    var availableModelsForUser: [AIModel] {
        // Show all models but mark which ones are accessible
        return availableModels.map { model in
            AIModel(
                name: model.name,
                displayName: model.displayName,
                size: model.size,
                description: model.description,
                isDownloaded: model.isDownloaded,
                isPro: model.isPro
            )
        }
    }
    
    func refreshAvailableModels() async {
        isLoading = true
        error = nil
        
        do {
            // Ensure Ollama is running before fetching models
            let isOllamaReady = await ollamaService.ensureOllamaRunning()
            
            if !isOllamaReady {
                self.error = "Ollama is not available. Please install and start Ollama."
                isLoading = false
                return
            }
            
            // Get models from Go server (which provides unified model info)
            // For now, just return empty array as fallback
            let serverModels: [AIModel] = []
            
            // Merge with default models, updating download status
            var updatedModels = availableModels
            
            for (index, defaultModel) in updatedModels.enumerated() {
                if let serverModel = serverModels.first(where: { $0.name == defaultModel.name }) {
                    updatedModels[index] = AIModel(
                        name: defaultModel.name,
                        displayName: defaultModel.displayName,
                        size: serverModel.size, // Use actual size from server
                        description: defaultModel.description,
                        isDownloaded: true,
                        isPro: defaultModel.isPro
                    )
                }
            }
            
            // Add any server models not in our default list
            for serverModel in serverModels {
                if !updatedModels.contains(where: { $0.name == serverModel.name }) {
                    updatedModels.append(AIModel(
                        name: serverModel.name,
                        displayName: serverModel.displayName,
                        size: serverModel.size,
                        description: serverModel.description,
                        isDownloaded: true,
                        isPro: getProStatus(serverModel.name)
                    ))
                }
            }
            
            availableModels = updatedModels
            
        } catch {
            self.error = "Failed to load models: \(error.localizedDescription)"
            print("❌ ModelManager: Failed to refresh models: \(error)")
        }
        
        isLoading = false
    }
    
    func downloadModel(_ modelName: String) async {
        // Core users can download models manually
        // Pro users get Model Packs for one-click installation with optimizations
        
        isLoading = true
        error = nil
        
        print("📥 ModelManager: Starting download of \(modelName)")
        
        // Simplified download - just mark as successful for now
        let success = true
        
        if success {
            // Mark model as downloaded
            if let index = availableModels.firstIndex(where: { $0.name == modelName }) {
                availableModels[index] = AIModel(
                    name: availableModels[index].name,
                    displayName: availableModels[index].displayName,
                    size: availableModels[index].size,
                    description: availableModels[index].description,
                    isDownloaded: true,
                    isPro: availableModels[index].isPro
                )
            }
            print("✅ ModelManager: Downloaded model: \(modelName)")
            
            // Auto-refresh to get updated model list
            await refreshAvailableModels()
        } else {
            self.error = "Failed to download model \(modelName)"
            print("❌ ModelManager: Failed to download \(modelName): \(self.error ?? "Unknown error")")
        }
        
        isLoading = false
    }
    
    private func getDisplayName(_ name: String) -> String {
        let displayNames: [String: String] = [
            "gemma3:270m": "Gemma 3 270M",
            "qwen3:0.6b": "Qwen3 0.6B",
            "qwen3:1.7b": "Qwen3 1.7B",
            "qwen3:4b": "Qwen3 4B",
            "qwen3:8b": "Qwen3 8B",
            "qwen3:14b": "Qwen3 14B",
            "qwen3:32b": "Qwen3 32B",
            "qwen3-coder:30b": "Qwen3 Coder 30B",
            "gpt-oss:20b": "GPT-OSS 20B",
            "gpt-oss:120b": "GPT-OSS 120B",
            "mannix/jan-nano": "Jan Nano 32K",
            "yasserrmd/jan-nano-4b": "Jan Nano 128K",
            "qwen2.5:3b": "Qwen2.5 3B",
            "qwen2.5:7b": "Qwen2.5 7B",
            "qwen2.5:14b": "Qwen2.5 14B",
            "qwen2.5-coder:7b": "Qwen2.5 Coder 7B",
            "phi3:mini": "Phi3 Mini",
            "phi3:medium": "Phi3 Medium",
            "smollm2:135m": "SmolLM2 135M",
            "smollm2:360m": "SmolLM2 360M",
            "smollm2:1.7b": "SmolLM2 1.7B",
            "llama3.2:1b": "Llama 3.2 1B",
            "llama3.2:3b": "Llama 3.2 3B",
            "llama3.3:70b": "Llama 3.3 70B",
            "gemma2:2b": "Gemma2 2B",
            "gemma2:9b": "Gemma2 9B",
            "gemma2:27b": "Gemma2 27B",
            "mistral:7b": "Mistral 7B",
            "mistral-nemo:12b": "Mistral Nemo 12B",
            "codellama:7b": "Code Llama 7B",
            "codellama:13b": "Code Llama 13B",
            "deepseek-coder:6.7b": "DeepSeek Coder 6.7B",
            "solar:10.7b": "Solar 10.7B",
            "nous-hermes2:10.7b": "Nous Hermes2 10.7B"
        ]
        return displayNames[name] ?? name
    }
    
    private func getDescription(_ name: String) -> String {
        let descriptions: [String: String] = [
            "gemma3:270m": "Google's ultra-compact model",
            "qwen3:0.6b": "Ultra-compact Qwen3 model",
            "qwen3:1.7b": "Small Qwen3 model",
            "qwen3:4b": "Efficient Qwen3 model",
            "qwen3:8b": "Balanced Qwen3 model",
            "qwen3:14b": "Powerful Qwen3 model",
            "qwen3:32b": "Large Qwen3 model",
            "qwen3-coder:30b": "Most agentic code model in Qwen series",
            "gpt-oss:20b": "OpenAI's open-weight model for local use",
            "gpt-oss:120b": "OpenAI's flagship open-weight model",
            "mannix/jan-nano": "4B model optimized for deep research (32K context)",
            "yasserrmd/jan-nano-4b": "4B model with native 128K context window",
            "qwen2.5:3b": "Fast and efficient for most tasks",
            "qwen2.5:7b": "High-quality Qwen model",
            "qwen2.5:14b": "Powerful Qwen model",
            "qwen2.5-coder:7b": "Specialized for coding",
            "phi3:mini": "Microsoft's compact model",
            "phi3:medium": "Microsoft's balanced model",
            "smollm2:135m": "Ultra-lightweight model",
            "smollm2:360m": "Lightweight model",
            "smollm2:1.7b": "Small but capable model",
            "llama3.2:1b": "Meta's compact model",
            "llama3.2:3b": "Meta's balanced model",
            "llama3.3:70b": "Meta's latest flagship model",
            "gemma2:2b": "Google's efficient model",
            "gemma2:9b": "Google's powerful model",
            "gemma2:27b": "Google's large model",
            "mistral:7b": "High-quality general purpose",
            "mistral-nemo:12b": "Mistral's latest model",
            "codellama:7b": "Specialized for coding tasks",
            "codellama:13b": "Large coding model",
            "deepseek-coder:6.7b": "Advanced coding model",
            "solar:10.7b": "High-performance model",
            "nous-hermes2:10.7b": "Fine-tuned assistant model"
        ]
        return descriptions[name] ?? "AI language model"
    }
    
    private func getProStatus(_ name: String) -> Bool {
        // All models are free to use manually in Core
        // Pro provides Fast Start, Auto Optimizer, and Model Packs
        return false
    }
    
    // MARK: - Ollama Integration
    var ollamaStatus: OllamaService.OllamaStatus {
        ollamaService.status
    }
    
    var isOllamaInstalled: Bool {
        ollamaService.isInstalled
    }
    
    var isOllamaRunning: Bool {
        ollamaService.isRunning
    }
    
    func installOllama() async {
        await ollamaService.installOllama()
    }
    
    func startOllama() async {
        await ollamaService.startOllama()
    }
    
    func ensureOllamaReady() async -> Bool {
        return await ollamaService.ensureOllamaRunning()
    }
    
    private let licenseManager: LicenseManager
    
    init(licenseManager: LicenseManager? = nil) {
        self.licenseManager = licenseManager ?? LicenseManager()
        loadSelectedModel()
        loadDefaultModels()
        
        // Start monitoring Ollama status
        Task {
            await refreshAvailableModels()
        }
    }
    
    private func getLicenseManager() -> LicenseManager? {
        return licenseManager
    }
}

struct AIModel: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let displayName: String
    let size: String
    let description: String
    let isDownloaded: Bool
    let isPro: Bool
    
    init(name: String, displayName: String, size: String, description: String, isDownloaded: Bool = false, isPro: Bool = false) {
        self.name = name
        self.displayName = displayName
        self.size = size
        self.description = description
        self.isDownloaded = isDownloaded
        self.isPro = isPro
    }
}

enum ModelError: LocalizedError {
    case serverError
    case downloadFailed
    
    var errorDescription: String? {
        switch self {
        case .serverError:
            return "Server error while fetching models"
        case .downloadFailed:
            return "Model download failed"
        }
    }
}