import AppIntents

/// Available image sizes for image generation.
enum ImageSizeOption: String, AppEnum {
    /// Let the API choose the best size.
    case auto = "auto"
    case square = "1024x1024"
    case portrait = "1024x1536"
    case landscape = "1536x1024"
    
    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        "Image Size"
    }
    
    static var caseDisplayRepresentations: [ImageSizeOption: DisplayRepresentation] {
        [
            .auto: "Auto",
            .square: "Square (1024×1024)",
            .portrait: "Portrait (1024×1536)",
            .landscape: "Landscape (1536×1024)"
        ]
    }
}
