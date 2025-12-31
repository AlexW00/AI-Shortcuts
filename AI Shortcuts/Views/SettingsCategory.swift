//
//  SettingsCategory.swift
//  AI Shortcuts
//
//  Created by Alex Weichart on 30.12.25.
//

import Foundation

/// Categories for settings sidebar navigation.
enum SettingsCategory: String, CaseIterable, Identifiable {
    case general = "General"
    case chat = "Chat"
    case image = "Image"
    case audio = "Audio"
    
    var id: String { rawValue }
    
    var icon: String {
        switch self {
        case .general: return "gear"
        case .chat: return "text.bubble"
        case .image: return "photo"
        case .audio: return "waveform"
        }
    }
    
    var description: String {
        switch self {
        case .general: return "API key and endpoint configuration"
        case .chat: return "Ask AI"
        case .image: return "Generate Image"
        case .audio: return "Transcribe Audio and Text-to-Speech"
        }
    }
}
