import AppIntents

/// Available voices for Text-to-Speech.
/// Includes OpenAI's built-in voices and a custom option for alternative providers.
enum VoiceOption: String, AppEnum {
    case alloy
    case echo
    case fable
    case onyx
    case nova
    case shimmer
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Voice"
    }
    
    static var caseDisplayRepresentations: [VoiceOption: DisplayRepresentation] {
        [
            .alloy: "Alloy",
            .echo: "Echo",
            .fable: "Fable",
            .onyx: "Onyx",
            .nova: "Nova",
            .shimmer: "Shimmer"
        ]
    }
    
    /// Returns whether this is an OpenAI built-in voice.
    var isOpenAIVoice: Bool {
        true // All current cases are OpenAI voices
    }
}
