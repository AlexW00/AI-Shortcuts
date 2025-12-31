import AppIntents
import OpenAI
import Foundation

/// Creates an image based on a text prompt.
struct GenerateImageIntent: AppIntent {
    static var title: LocalizedStringResource = "Generate Image"
    static var description = IntentDescription("Creates an image based on a text prompt.")
    
    @Parameter(title: "Prompt", description: "A description of the image to generate.")
    var prompt: String
    
    @Parameter(title: "Model", description: "Leave empty to use your default model from settings (e.g., gpt-image-1.5, dall-e-3).", default: nil)
    var model: String?
    
    @Parameter(title: "Size", description: "The size of the generated image. Use Auto to let the API choose.", default: .auto)
    var size: ImageSizeOption
    
    static var parameterSummary: some ParameterSummary {
        Summary("Generate image of \(\.$prompt)") {
            \.$model
            \.$size
        }
    }
    
    @MainActor
    func perform() async throws -> some IntentResult & ReturnsValue<IntentFile> {
        // Check if image generation is supported with current endpoint
        try OpenAIService.shared.checkImageGenerationSupport()
        
        let openAI = try OpenAIService.shared.client

        let modelToUse = model?.nilIfEmpty ?? OpenAIService.shared.defaultImageModel
        
        let query = ImagesQuery(
            prompt: prompt,
            model: modelToUse,
            n: 1,
            size: ImagesQuery.Size(rawValue: size.rawValue)
        )
        
        do {
            let result = try await openAI.images(query: query)
            
            guard let imageResult = result.data.first else {
                throw AIShortcutsError.noImageGenerated
            }
            
            let imageData: Data
            
            if let urlString = imageResult.url, let url = URL(string: urlString) {
                // Download image from URL
                let (data, _) = try await URLSession.shared.data(from: url)
                imageData = data
            } else if let b64Json = imageResult.b64Json {
                // Decode Base64 image
                guard let data = Data(base64Encoded: b64Json) else {
                    throw AIShortcutsError.invalidImageData
                }
                imageData = data
            } else {
                throw AIShortcutsError.noImageGenerated
            }
            
            // Save to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .appendingPathExtension("png")
            
            try imageData.write(to: tempURL)
            
            let file = IntentFile(fileURL: tempURL, filename: "generated_image.png")
            return .result(value: file)
            
        } catch let error as AIShortcutsError {
            throw error
        } catch {
            throw AIShortcutsError.apiError(error.localizedDescription)
        }
    }
}
