import Foundation
import OpenAI
import Combine

/// Centralized service for managing OpenAI API interactions.
@MainActor
final class OpenAIService: ObservableObject {
    static let shared = OpenAIService()

    private static let defaultOpenAIHost = "api.openai.com"

    static let fallbackChatModelId = "gpt-5"
    static let fallbackImageModelId = "gpt-image-1.5"
    static let fallbackTranscriptionModelId = "whisper-1"
    
    @Published private(set) var isConfigured: Bool = false
    @Published private(set) var availableModels: [ModelResult] = []
    @Published private(set) var isLoadingModels: Bool = false
    @Published private(set) var modelsFetchError: String?
    
    // MARK: - Filtered Model Lists
    
    /// Models suitable for audio transcription (speech-to-text).
    /// Only filters when using the official OpenAI endpoint.
    var transcriptionModels: [ModelResult] {
        guard isUsingOfficialOpenAIEndpoint else { return availableModels }
        return availableModels.filter { model in
            ModelFilterPatterns.matches(model.id, patterns: ModelFilterPatterns.transcriptionPatterns)
        }
    }
    
    /// Models suitable for text-to-speech synthesis.
    /// Only filters when using the official OpenAI endpoint.
    var ttsModels: [ModelResult] {
        guard isUsingOfficialOpenAIEndpoint else { return availableModels }
        return availableModels.filter { model in
            ModelFilterPatterns.matches(model.id, patterns: ModelFilterPatterns.ttsPatterns)
        }
    }
    
    /// Models suitable for image generation.
    /// Only filters when using the official OpenAI endpoint.
    var imageModels: [ModelResult] {
        guard isUsingOfficialOpenAIEndpoint else { return availableModels }
        return availableModels.filter { model in
            ModelFilterPatterns.matches(model.id, patterns: ModelFilterPatterns.imageGenerationPatterns)
        }
    }
    
    /// Models suitable for chat completions.
    /// Only filters when using the official OpenAI endpoint.
    var chatModels: [ModelResult] {
        guard isUsingOfficialOpenAIEndpoint else { return availableModels }
        return availableModels.filter { model in
            ModelFilterPatterns.isChatModel(model.id)
        }
    }
    
    /// Cache duration for models (5 minutes)
    private let modelsCacheDuration: TimeInterval = 300
    private var lastModelsFetchTime: Date?

    private var modelsFetchTask: Task<Void, Never>?
    
    private var _client: OpenAI?
    
    private init() {
        refreshClient()
    }
    
    // MARK: - Model Fetching
    
    /// Fetches available models from the API and caches them.
    func fetchModels(forceRefresh: Bool = false) async {
        // Check cache validity
        if !forceRefresh,
           let lastFetch = lastModelsFetchTime,
           Date().timeIntervalSince(lastFetch) < modelsCacheDuration,
           !availableModels.isEmpty {
            return
        }
        
        guard isConfigured else {
            modelsFetchError = "API key not configured"
            return
        }
        
        isLoadingModels = true
        modelsFetchError = nil
        defer { isLoadingModels = false }
        
        do {
            let client = try self.client
            let result = try await client.models()
            availableModels = result.data.sorted { $0.id < $1.id }
            lastModelsFetchTime = Date()
            modelsFetchError = nil
        } catch is CancellationError {
            return
        } catch let urlError as URLError where urlError.code == .cancelled {
            return
        } catch {
            modelsFetchError = "Failed to fetch models: \(error.localizedDescription)"
        }
    }

    /// Starts a models fetch in an unstructured task owned by the service.
    /// This prevents SwiftUI view lifecycle changes from cancelling an in-flight request.
    func startFetchModelsIfNeeded(forceRefresh: Bool = false) {
        if forceRefresh {
            modelsFetchTask?.cancel()
            modelsFetchTask = nil
        }

        guard modelsFetchTask == nil else { return }

        modelsFetchTask = Task { [weak self] in
            guard let self else { return }
            await self.fetchModels(forceRefresh: forceRefresh)
            await MainActor.run {
                self.modelsFetchTask = nil
            }
        }
    }
    
    /// Clears the cached models.
    func clearModelsCache() {
        availableModels = []
        lastModelsFetchTime = nil

        // Clean up previously persisted model caches (introduced in a prior version)
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "cachedChatModels")
        defaults.removeObject(forKey: "cachedImageModels")
        defaults.removeObject(forKey: "cachedTTSModels")
        defaults.removeObject(forKey: "cachedTranscriptionModels")
    }
    
    /// Returns the configured OpenAI client, or throws if not configured.
    var client: OpenAI {
        get throws {
            guard let client = _client else {
                throw AIShortcutsError.noAPIKey
            }
            return client
        }
    }
    
    /// Refreshes the OpenAI client with current settings.
    func refreshClient() {
        modelsFetchTask?.cancel()
        modelsFetchTask = nil
        connectionStatus = .unknown
        isVerifyingConnection = false

        guard let apiKey = KeychainService.shared.apiKey, !apiKey.isEmpty else {
            _client = nil
            isConfigured = false
            return
        }
        
        let settings = SettingsStore.shared

        let scheme = settings.endpointScheme.isEmpty ? "https" : settings.endpointScheme
        let hasNonDefaultEndpointConfiguration =
            !settings.endpointHost.isEmpty ||
            !settings.endpointBasePath.isEmpty ||
            settings.endpointPort > 0 ||
            scheme.lowercased() != "https"

        if hasNonDefaultEndpointConfiguration {
            // Custom endpoint configuration (includes overrides for the default OpenAI host).
            let endpointHost = settings.endpointHost.isEmpty ? Self.defaultOpenAIHost : settings.endpointHost
            let basePath = settings.endpointBasePath.isEmpty ? "/v1" : settings.endpointBasePath
            let storedPort = settings.endpointPort
            let port = storedPort > 0 ? storedPort : (scheme.lowercased() == "https" ? 443 : 80)
            
            // Use relaxed parsing for non-OpenAI providers
            let configuration = OpenAI.Configuration(
                token: apiKey,
                host: endpointHost,
                port: port,
                scheme: scheme,
                basePath: basePath,
                timeoutInterval: 120,
                parsingOptions: .relaxed
            )
            _client = OpenAI(configuration: configuration)
        } else {
            // Default OpenAI endpoint
            _client = OpenAI(apiToken: apiKey)
        }
        
        isConfigured = true
        
        // Clear cached models when client changes
        clearModelsCache()
    }
    
    // MARK: - Endpoint Detection

    private var isUsingOfficialOpenAIEndpoint: Bool {
        let settings = SettingsStore.shared
        let scheme = settings.endpointScheme.isEmpty ? "https" : settings.endpointScheme

        return settings.endpointHost.isEmpty &&
            settings.endpointBasePath.isEmpty &&
            settings.endpointPort == 0 &&
            scheme.lowercased() == "https"
    }
    
    /// Whether a custom endpoint is configured (non-OpenAI provider).
    var isUsingCustomEndpoint: Bool {
        !SettingsStore.shared.endpointHost.isEmpty
    }
    
    /// The current custom endpoint host, if set.
    var customEndpoint: String? {
        let host = SettingsStore.shared.endpointHost
        return host.isEmpty ? nil : host
    }

    /// A user-facing description of the effective API base URL.
    var effectiveEndpointDescription: String {
        let settings = SettingsStore.shared

        if isUsingOfficialOpenAIEndpoint {
            return "https://\(Self.defaultOpenAIHost)/v1"
        }

        let scheme = settings.endpointScheme.isEmpty ? "https" : settings.endpointScheme
        let host = settings.endpointHost.isEmpty ? Self.defaultOpenAIHost : settings.endpointHost
        let basePath = settings.endpointBasePath.isEmpty ? "/v1" : settings.endpointBasePath
        let storedPort = settings.endpointPort
        let port = storedPort > 0 ? storedPort : (scheme.lowercased() == "https" ? 443 : 80)

        // Always include port for custom endpoints to reduce ambiguity.
        return "\(scheme)://\(host):\(port)\(basePath)"
    }

    /// Marks the current connection status as needing verification.
    ///
    /// This is used by the settings UI so "Connected" doesn't remain visible while the user is
    /// actively editing endpoint fields that haven't been verified yet.
    func markConnectionNeedsVerification() {
        guard isConfigured else {
            connectionStatus = .unknown
            return
        }

        // Don't fight an in-flight verification task; it will set the final state.
        guard !isVerifyingConnection else { return }
        connectionStatus = .unknown
    }
    
    // MARK: - Feature Support
    
    /// Checks if image generation is likely supported.
    /// Only OpenAI's endpoint reliably supports the Images API.
    func checkImageGenerationSupport() throws {
        if isUsingCustomEndpoint {
            throw AIShortcutsError.featureNotSupported(
                feature: "Image Generation",
                reason: "Image generation requires the official OpenAI API. Custom endpoints like OpenRouter typically don't support the Images API. Please use the default OpenAI endpoint or check if your provider supports /v1/images/generations."
            )
        }
    }
    
    /// Checks if text-to-speech is likely supported.
    /// Only OpenAI's endpoint reliably supports this.
    func checkTextToSpeechSupport() throws {
        if isUsingCustomEndpoint {
            throw AIShortcutsError.featureNotSupported(
                feature: "Text-to-Speech",
                reason: "TTS requires the official OpenAI API. Custom endpoints typically don't support the /v1/audio/speech endpoint. Please use the default OpenAI endpoint or check if your provider supports this feature."
            )
        }
    }
    
    /// Checks if audio transcription (Whisper) is likely supported.
    /// Only OpenAI's endpoint reliably supports this.
    func checkTranscriptionSupport() throws {
        if isUsingCustomEndpoint {
            throw AIShortcutsError.featureNotSupported(
                feature: "Audio Transcription",
                reason: "Whisper transcription requires the official OpenAI API. Custom endpoints typically don't support the /v1/audio/transcriptions endpoint. Please use the default OpenAI endpoint or check if your provider supports this feature."
            )
        }
    }
    
    // MARK: - Connection Verification
    
    /// Connection verification state
    @Published private(set) var connectionStatus: ConnectionStatus = .unknown
    @Published private(set) var isVerifyingConnection: Bool = false
    
    enum ConnectionStatus: Equatable {
        case unknown
        case verifying
        case success
        case failure(String)
        
        var isSuccess: Bool {
            if case .success = self { return true }
            return false
        }
    }
    
    /// Verifies the connection to the API endpoint by fetching models.
    func verifyConnection() async {
        guard isConfigured else {
            connectionStatus = .failure("API key not configured")
            return
        }
        
        isVerifyingConnection = true
        connectionStatus = .verifying
        
        do {
            let client = try self.client
            _ = try await client.models()
            connectionStatus = .success
            // Also refresh the models cache while we're at it
            await fetchModels(forceRefresh: true)
        } catch {
            connectionStatus = .failure(error.localizedDescription)
        }
        
        isVerifyingConnection = false
    }
    
    // MARK: - Settings Helpers
    
    /// The default model to use when none is specified.
    var defaultModel: String {
        let model = SettingsStore.shared.defaultModel
        return model.isEmpty ? inferredDefaultChatModel : model
    }

    /// The default image generation model to use when none is specified.
    var defaultImageModel: String {
        let model = SettingsStore.shared.imageModel
        return model.isEmpty ? inferredDefaultImageModel : model
    }

    /// The default audio transcription model to use when none is specified.
    var defaultTranscriptionModel: String {
        let model = SettingsStore.shared.transcriptionModel
        return model.isEmpty ? inferredDefaultTranscriptionModel : model
    }

    var inferredDefaultChatModel: String {
        let ids = chatModels.map(\.id)
        if let best = ModelFilterPatterns.highestVersionModelId(in: ids, prefix: "gpt-") {
            return best
        }
        return chatModels.first?.id ?? Self.fallbackChatModelId
    }

    var inferredDefaultImageModel: String {
        let ids = imageModels.map(\.id)
        if let best = ModelFilterPatterns.highestVersionModelId(in: ids, prefix: "gpt-image-") {
            return best
        }
        return imageModels.first?.id ?? Self.fallbackImageModelId
    }

    var inferredDefaultTranscriptionModel: String {
        let ids = transcriptionModels.map(\.id)
        if let best = ModelFilterPatterns.highestVersionModelId(in: ids, prefix: "whisper-") {
            return best
        }
        return transcriptionModels.first?.id ?? Self.fallbackTranscriptionModelId
    }
}
