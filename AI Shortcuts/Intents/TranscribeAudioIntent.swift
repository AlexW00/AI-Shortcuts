import AppIntents
import OpenAI
import Foundation
import UniformTypeIdentifiers

/// Converts an audio file into text using Whisper.
struct TranscribeAudioIntent: AppIntent {
    static var title: LocalizedStringResource = "Transcribe Audio"
    static var description = IntentDescription("Converts an audio file into text using AI transcription.")
    
    @Parameter(title: "Audio File", description: "The audio file to transcribe.", supportedContentTypes: [.audio])
    var audioFile: IntentFile
    
    @Parameter(title: "Model", description: "Leave empty to use your default model from settings (e.g., whisper-1).", default: nil)
    var model: String?
    
    @Parameter(title: "Language", description: "The language of the audio (ISO-639-1 code, e.g., 'en'). Leave empty for auto-detection.", default: nil)
    var language: String?
    
    static var parameterSummary: some ParameterSummary {
        Summary("Transcribe \(\.$audioFile)") {
            \.$model
            \.$language
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        // Check if transcription is supported with current endpoint
        try OpenAIService.shared.checkTranscriptionSupport()
        
        let openAI = try OpenAIService.shared.client
        
        // Handle security-scoped resource access
        let needsSecurityScope = audioFile.fileURL?.startAccessingSecurityScopedResource() ?? false
        defer {
            if needsSecurityScope {
                audioFile.fileURL?.stopAccessingSecurityScopedResource()
            }
        }
        
        // Try to get file data - first from IntentFile.data, then try reading from URL
        var audioData = audioFile.data
        if audioData.isEmpty, let fileURL = audioFile.fileURL {
            // Fallback: try reading directly from the URL
            audioData = (try? Data(contentsOf: fileURL)) ?? Data()
        }
        guard !audioData.isEmpty else {
            throw AIShortcutsError.invalidAudioData
        }
        
        // Determine file type from filename
        let fileType = audioFileType(for: audioFile)
        
        // Get language, converting empty string to nil
        let languageCode: String? = language?.nilIfEmpty
        
        let modelToUse = model?.nilIfEmpty ?? OpenAIService.shared.defaultTranscriptionModel
        
        let query = AudioTranscriptionQuery(
            file: audioData,
            fileType: fileType,
            model: modelToUse,
            language: languageCode
        )
        
        do {
            let result = try await openAI.audioTranscriptions(query: query)
            return .result(value: result.text)
            
        } catch let error as AIShortcutsError {
            throw error
        } catch {
            throw AIShortcutsError.apiError(error.localizedDescription)
        }
    }
    
    // MARK: - Helpers
    
    private func audioFileType(for file: IntentFile) -> AudioTranscriptionQuery.FileType {
        let ext = (file.filename as NSString).pathExtension.lowercased()
        
        switch ext {
        case "mp3": return .mp3
        case "mp4": return .mp4
        case "m4a": return .m4a
        case "wav": return .wav
        case "webm": return .webm
        case "mpeg", "mpga": return .mpga
        case "ogg", "oga": return .ogg
        case "flac": return .flac
        default: return .m4a
        }
    }
}
