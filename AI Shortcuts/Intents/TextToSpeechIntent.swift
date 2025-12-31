import AppIntents
import OpenAI
import Foundation

/// Generates spoken audio from text input using Text-to-Speech.
struct TextToSpeechIntent: AppIntent {
    static var title: LocalizedStringResource = "Read Text Aloud"
    static var description = IntentDescription("Generates spoken audio from text input.")
    
    @Parameter(title: "Text", description: "The text to convert to speech.")
    var text: String
    
    @Parameter(title: "Model", description: "Leave empty to use your default model from settings (e.g., tts-1, tts-1-hd).", default: nil)
    var model: String?
    
    @Parameter(title: "Voice", description: "The voice to use for speech.", default: .alloy)
    var voice: VoiceOption
    
    @Parameter(title: "Speed", description: "Speech speed (0.25 to 4.0, default 1.0).", default: 1.0)
    var speed: Double
    
    static var parameterSummary: some ParameterSummary {
        Summary("Read aloud \(\.$text)") {
            \.$model
            \.$voice
            \.$speed
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        // Check if TTS is supported with current endpoint
        try OpenAIService.shared.checkTextToSpeechSupport()
        
        let openAI = try OpenAIService.shared.client
        
        // Clamp speed to valid range
        let clampedSpeed = min(max(speed, 0.25), 4.0)
        
        let modelToUse = model?.nilIfEmpty ?? SettingsStore.shared.ttsModel.nilIfEmpty ?? "tts-1"
        
        let query = AudioSpeechQuery(
            model: modelToUse,
            input: text,
            voice: audioVoice(from: voice),
            responseFormat: .mp3,
            speed: clampedSpeed
        )
        
        do {
            let result = try await openAI.audioCreateSpeech(query: query)
            
            // Save audio data to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("mp3")
            
            try result.audio.write(to: tempURL)
            
            let file = IntentFile(fileURL: tempURL, filename: "speech.mp3")
            return .result(value: file)
            
        } catch let error as AIShortcutsError {
            throw error
        } catch {
            throw AIShortcutsError.apiError(error.localizedDescription)
        }
    }
    
    // MARK: - Helpers
    
    private func audioVoice(from option: VoiceOption) -> AudioSpeechQuery.AudioSpeechVoice {
        switch option {
        case .alloy: return .alloy
        case .echo: return .echo
        case .fable: return .fable
        case .onyx: return .onyx
        case .nova: return .nova
        case .shimmer: return .shimmer
        }
    }
}
