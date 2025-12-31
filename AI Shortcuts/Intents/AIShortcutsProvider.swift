import AppIntents

/// Registers all AI Shortcuts with the system.
struct AIShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        return [
            // Ask AI
            AppShortcut(
                intent: AskAIIntent(),
                phrases: [
                    "Ask \(.applicationName)",
                    "Chat with \(.applicationName)",
                    "Ask \(.applicationName) a question",
                    "Analyze an image with \(.applicationName)",
                    "Describe an image with \(.applicationName)",
                    "What's in this image with \(.applicationName)"
                ],
                shortTitle: "Ask AI",
                systemImageName: "text.bubble"
            ),
            
            // Generate Image
            AppShortcut(
                intent: GenerateImageIntent(),
                phrases: [
                    "Generate an image with \(.applicationName)",
                    "Create an image with \(.applicationName)",
                    "Draw with \(.applicationName)"
                ],
                shortTitle: "Generate Image",
                systemImageName: "photo.badge.plus"
            ),
            
            // Transcribe Audio
            AppShortcut(
                intent: TranscribeAudioIntent(),
                phrases: [
                    "Transcribe audio with \(.applicationName)",
                    "Convert audio to text with \(.applicationName)"
                ],
                shortTitle: "Transcribe Audio",
                systemImageName: "waveform.and.mic"
            ),
            
            // Text to Speech
            AppShortcut(
                intent: TextToSpeechIntent(),
                phrases: [
                    "Read aloud with \(.applicationName)",
                    "Say with \(.applicationName)",
                    "Speak with \(.applicationName)"
                ],
                shortTitle: "Read Text Aloud",
                systemImageName: "speaker.wave.3"
            )
        ]
    }
}
