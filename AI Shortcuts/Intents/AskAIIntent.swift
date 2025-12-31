import AppIntents
import OpenAI
import Foundation
import UniformTypeIdentifiers

/// Sends a text prompt to the AI and returns the text response. Optionally attach images for vision.
struct AskAIIntent: AppIntent {
    static var title: LocalizedStringResource = "Ask AI"
    static var description = IntentDescription("Sends a text prompt to the AI and returns the text response. Optionally attach images for vision.")
    
    @Parameter(title: "Prompt", description: "The text prompt to send to the AI.")
    var prompt: String
    
    @Parameter(title: "System Prompt", description: "Optional system prompt to set the AI's behavior.", default: nil)
    var systemPrompt: String?
    
    @Parameter(title: "Model", description: "Leave empty to use your default model from settings (e.g., gpt-5, gpt-5-mini, o1).", default: nil)
    var model: String?
    
    @Parameter(
        title: "Images",
        description: "Optional images for vision analysis (max 20).",
        default: [],
        supportedContentTypes: [.image],
        requestValueDialog: IntentDialog("Select images")
    )
    var images: [IntentFile]
    
    private let maxImageCount = 20
    
    static var parameterSummary: some ParameterSummary {
        Summary("Ask AI: \(\.$prompt)") {
            \.$systemPrompt
            \.$model
            \.$images
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let openAI = try OpenAIService.shared.client
        let modelName = model?.nilIfEmpty ?? OpenAIService.shared.defaultModel
        
        let imagesToProcess = Array(images.prefix(maxImageCount))
        
        var messages: [ChatQuery.ChatCompletionMessageParam] = []
        
        if let systemPrompt = systemPrompt?.nilIfEmpty {
            messages.append(.system(.init(content: .textContent(systemPrompt))))
        }
        
        if imagesToProcess.isEmpty {
            messages.append(.user(.init(content: .string(prompt))))
        } else {
            var contentParts: [ChatQuery.ChatCompletionMessageParam.UserMessageParam.Content.ContentPart] = []
            contentParts.append(.text(.init(text: prompt)))
            
            for image in imagesToProcess {
                let imageData = image.data
                guard !imageData.isEmpty else { continue }
                
                let mimeType = detectImageMimeType(from: imageData, filename: image.filename) ?? "image/jpeg"
                let base64Image = imageData.base64EncodedString()
                
                contentParts.append(.image(.init(
                    imageUrl: .init(
                        url: "data:\(mimeType);base64,\(base64Image)",
                        detail: .auto
                    )
                )))
            }
            
            messages.append(.user(.init(content: .contentParts(contentParts))))
        }
        
        let query = ChatQuery(
            messages: messages,
            model: modelName
        )
        
        do {
            let result = try await openAI.chats(query: query)
            
            guard let content = result.choices.first?.message.content, !content.isEmpty else {
                throw AIShortcutsError.noResponse
            }
            
            return .result(value: content)
        } catch let error as AIShortcutsError {
            throw error
        } catch {
            throw AIShortcutsError.apiError(error.localizedDescription)
        }
    }
    
    // MARK: - Image MIME Type Detection
    
    private func detectImageMimeType(from data: Data, filename: String?) -> String? {
        if let mimeFromBytes = detectMimeTypeFromBytes(data) {
            return mimeFromBytes
        }
        
        if let filename = filename {
            return mimeTypeFromExtension(filename)
        }
        
        return nil
    }
    
    private func detectMimeTypeFromBytes(_ data: Data) -> String? {
        guard data.count >= 12 else { return nil }
        
        let bytes = [UInt8](data.prefix(12))
        
        // PNG: 89 50 4E 47
        if bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E && bytes[3] == 0x47 {
            return "image/png"
        }
        
        // JPEG: FF D8 FF
        if bytes[0] == 0xFF && bytes[1] == 0xD8 && bytes[2] == 0xFF {
            return "image/jpeg"
        }
        
        // GIF: 47 49 46 38
        if bytes[0] == 0x47 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x38 {
            return "image/gif"
        }
        
        // WebP: RIFF....WEBP
        if bytes[0] == 0x52 && bytes[1] == 0x49 && bytes[2] == 0x46 && bytes[3] == 0x46 &&
           bytes[8] == 0x57 && bytes[9] == 0x45 && bytes[10] == 0x42 && bytes[11] == 0x50 {
            return "image/webp"
        }
        
        return nil
    }
    
    private func mimeTypeFromExtension(_ filename: String) -> String? {
        let ext = (filename as NSString).pathExtension.lowercased()
        
        switch ext {
        case "jpg", "jpeg": return "image/jpeg"
        case "png": return "image/png"
        case "gif": return "image/gif"
        case "webp": return "image/webp"
        default: return nil
        }
    }
}
