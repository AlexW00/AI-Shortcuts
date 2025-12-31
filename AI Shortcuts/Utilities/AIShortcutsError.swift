import Foundation

/// Errors specific to AI Shortcuts that display user-friendly messages in Shortcuts.
enum AIShortcutsError: Error, CustomLocalizedStringResourceConvertible {
    case noAPIKey
    case noResponse
    case noImageGenerated
    case invalidImageData
    case invalidAudioData
    case fileAccessDenied
    case invalidAudioFormat
    case networkError(String)
    case apiError(String)
    case featureNotSupported(feature: String, reason: String)
    
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .noAPIKey:
            return "No API key configured. Please open AI Shortcuts app to set up your API key."
        case .noResponse:
            return "The AI did not return a response. Please try again."
        case .noImageGenerated:
            return "Failed to generate an image. Please try a different prompt."
        case .invalidImageData:
            return "The provided image could not be processed."
        case .invalidAudioData:
            return "The provided audio file could not be processed."
        case .fileAccessDenied:
            return "Cannot access the provided file. Please check permissions."
        case .invalidAudioFormat:
            return "The audio file format is not supported. Please use MP3, M4A, WAV, or WEBM."
        case .networkError(let message):
            return "Network error: \(message)"
        case .apiError(let message):
            return "API error: \(message)"
        case .featureNotSupported(let feature, let reason):
            return "\(feature) is not available: \(reason)"
        }
    }
}
