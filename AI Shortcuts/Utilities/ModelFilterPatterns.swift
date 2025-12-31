//
//  ModelFilterPatterns.swift
//  AI Shortcuts
//
//  Created by Alex Weichart on 30.12.25.
//

import Foundation

/// Centralized patterns for filtering models by capability.
/// These patterns are used to categorize models from the OpenAI API response.
/// Adjust these patterns if new model naming conventions are introduced.
enum ModelFilterPatterns {

    private static let regexCache = NSCache<NSString, NSRegularExpression>()
    
    // MARK: - Transcription (Speech-to-Text)
    
    /// Regex patterns that identify transcription-capable models.
    /// Matches: whisper-1, gpt-4o-transcribe, gpt-4o-mini-transcribe, etc.
    static let transcriptionPatterns: [String] = [
        "whisper",
        "transcribe"
    ]
    
    // MARK: - Text-to-Speech
    
    /// Regex patterns that identify TTS-capable models.
    /// Matches: tts-1, tts-1-hd, etc.
    static let ttsPatterns: [String] = [
        "tts"
    ]
    
    // MARK: - Image Generation
    
    /// Regex patterns that identify image generation models.
    /// Matches: image generation models (e.g., gpt-image-*), plus DALL·E IDs.
    static let imageGenerationPatterns: [String] = [
        "dall-e",
        "^gpt-image"
    ]
    
    // MARK: - Chat Models (Inclusion)
    
    /// Regex patterns that identify chat-capable models.
    /// Uses positive matching for more precise filtering.
    /// Matches: gpt-4o, gpt-4-turbo, gpt-3.5-turbo, o1, o3-mini, o4-..., chatgpt-4o, etc.
    ///
    /// Notes:
    /// - The `o`-family pattern allows IDs like `o1`, `o1-preview`, `o3-mini`, etc.
    static let chatInclusionPatterns: [String] = [
        "^gpt-",
        "^chatgpt-",
        "^o\\d(?:-|$)"
    ]
    
    /// Regex patterns for models that should be excluded even if they match chat patterns.
    /// These are specialized models not suitable for general chat completions.
    static let chatExclusionPatterns: [String] = [
        "embedding",
        "moderation",
        "whisper",
        "transcribe",
        "tts",
        "dall-e",
        "^gpt-image",
        "realtime",
        "audio-preview",
        "sora",
        "computer",
        "search",
        "audio"
    ]
    
    // MARK: - Matching Helpers
    
    /// Checks if a model ID matches any of the given regex patterns.
    /// - Parameters:
    ///   - modelId: The model identifier to check (case-insensitive).
    ///   - patterns: Array of regex patterns.
    /// - Returns: `true` if the model ID matches any regex.
    static func matches(_ modelId: String, patterns: [String]) -> Bool {
        let range = NSRange(modelId.startIndex..<modelId.endIndex, in: modelId)
        return patterns.contains { pattern in
            guard let regex = compiledRegex(for: pattern) else {
                return false
            }
            return regex.firstMatch(in: modelId, options: [], range: range) != nil
        }
    }
    
    /// Checks if a model ID is a chat model using positive inclusion + exclusion.
    /// - Parameter modelId: The model identifier to check.
    /// - Returns: `true` if the model matches chat patterns and doesn't match exclusions.
    static func isChatModel(_ modelId: String) -> Bool {
        matches(modelId, patterns: chatInclusionPatterns) &&
        !matches(modelId, patterns: chatExclusionPatterns)
    }

    /// Returns the highest "versioned" model ID for a given prefix.
    ///
    /// Examples:
    /// - prefix `gpt-` matches `gpt-4o`, `gpt-4.1-mini`, `gpt-5` and selects the highest numeric prefix (e.g. `gpt-5`).
    /// - prefix `gpt-image-` matches `gpt-image-1`, `gpt-image-1.5` and selects `gpt-image-1.5`.
    /// - prefix `whisper-` matches `whisper-1`, `whisper-2` and selects `whisper-2`.
    static func highestVersionModelId(in modelIds: [String], prefix: String) -> String? {
        let normalizedPrefix = prefix.lowercased()
        var best: (id: String, version: Decimal)?

        for modelId in modelIds {
            let normalizedModelId = modelId.lowercased()
            guard normalizedModelId.hasPrefix(normalizedPrefix) else { continue }

            let remainder = String(normalizedModelId.dropFirst(normalizedPrefix.count))
            guard let version = parseLeadingDecimal(from: remainder) else { continue }

            if let currentBest = best {
                if version > currentBest.version {
                    best = (modelId, version)
                }
            } else {
                best = (modelId, version)
            }
        }

        return best?.id
    }

    private static func compiledRegex(for pattern: String) -> NSRegularExpression? {
        let key = pattern as NSString
        if let cached = regexCache.object(forKey: key) {
            return cached
        }

        do {
            let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            regexCache.setObject(regex, forKey: key)
            return regex
        } catch {
            return nil
        }
    }

    private static func parseLeadingDecimal(from string: String) -> Decimal? {
        let scalarView = string.unicodeScalars
        var decimalString = ""
        var hasDigit = false
        var hasDot = false

        for scalar in scalarView {
            if CharacterSet.decimalDigits.contains(scalar) {
                hasDigit = true
                decimalString.unicodeScalars.append(scalar)
                continue
            }
            if scalar == ".", !hasDot {
                hasDot = true
                decimalString.unicodeScalars.append(scalar)
                continue
            }
            break
        }

        guard hasDigit else { return nil }
        return Decimal(string: decimalString)
    }
}
