//
//  AudioSettingsView.swift
//  AI Shortcuts
//
//  Created by Alex Weichart on 30.12.25.
//

import SwiftUI
import OpenAI

struct AudioSettingsView: View {
    @ObservedObject var openAIService: OpenAIService
    
    @Binding var transcriptionModel: String
    @Binding var ttsModel: String
    @Binding var defaultVoice: String
    
    var onSaveTranscription: () -> Void
    var onSaveTTS: () -> Void
    var onSaveVoice: () -> Void
    
    private var isSupported: Bool {
        !openAIService.isUsingCustomEndpoint
    }
    
    private var hasTranscriptionModels: Bool {
        !openAIService.transcriptionModels.isEmpty
    }
    
    private var hasTTSModels: Bool {
        !openAIService.ttsModels.isEmpty
    }
    
    var body: some View {
        Form {
            // MARK: - Unsupported Warning
            if !isSupported {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Feature Not Available")
                                .font(.headline)
                            Text("Audio features require the official OpenAI API. Your current custom endpoint may not support Whisper transcription or TTS.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                }
            }
            
            // MARK: - Error State
            if let error = openAIService.modelsFetchError, isSupported {
                Section {
                    Label {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cannot Load Models")
                                .font(.headline)
                            Text(error)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                    
                    Button("Retry") {
                        openAIService.startFetchModelsIfNeeded(forceRefresh: true)
                    }
                }
            }
            
            // MARK: - Shortcuts Info
            Section {
                HStack {
                    Label("Transcribe Audio", systemImage: "waveform.and.mic")
                    Spacer()
                    if !isSupported {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
                
                HStack {
                    Label("Read Text Aloud", systemImage: "speaker.wave.3")
                    Spacer()
                    if !isSupported {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            } header: {
                Text("Available Shortcuts")
            } footer: {
                Text("Use Whisper for transcription and OpenAI TTS for text-to-speech. Requires the official OpenAI API.")
            }
            
            // MARK: - Transcription Settings
            Section {
                if openAIService.isLoadingModels {
                    HStack {
                        Text("Model")
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                } else if hasTranscriptionModels {
                    Picker("Model", selection: $transcriptionModel) {
                        Text("Default (\(openAIService.inferredDefaultTranscriptionModel))").tag("")
                        if !transcriptionModel.isEmpty,
                           !openAIService.transcriptionModels.contains(where: { $0.id == transcriptionModel }) {
                            Text("Custom (\(transcriptionModel))").tag(transcriptionModel)
                        }
                        ForEach(openAIService.transcriptionModels, id: \.id) { model in
                            Text(model.id).tag(model.id)
                        }
                    }
                    .onChange(of: transcriptionModel) { _, _ in
                        onSaveTranscription()
                    }
                } else {
                    LabeledContent("Model") {
                        Text(transcriptionModel.isEmpty ? openAIService.inferredDefaultTranscriptionModel : transcriptionModel)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Transcription")
            } footer: {
                if hasTranscriptionModels {
                    Text("The model used for audio transcription.")
                } else {
                    Text("Configure API key to load available models.")
                }
            }
            .disabled(!isSupported)
            
            // MARK: - TTS Settings
            Section {
                if openAIService.isLoadingModels {
                    HStack {
                        Text("Model")
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                } else if hasTTSModels {
                    Picker("Model", selection: $ttsModel) {
                        Text("Default (tts-1)").tag("")
                        if !ttsModel.isEmpty,
                           !openAIService.ttsModels.contains(where: { $0.id == ttsModel }) {
                            Text("Custom (\(ttsModel))").tag(ttsModel)
                        }
                        ForEach(openAIService.ttsModels, id: \.id) { model in
                            Text(model.id).tag(model.id)
                        }
                    }
                    .onChange(of: ttsModel) { _, _ in
                        onSaveTTS()
                    }
                } else {
                    LabeledContent("Model") {
                        Text(ttsModel.isEmpty ? "tts-1" : ttsModel)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Picker("Default Voice", selection: $defaultVoice) {
                    if !defaultVoice.isEmpty,
                       !["alloy", "echo", "fable", "onyx", "nova", "shimmer"].contains(defaultVoice) {
                        Text("Custom (\(defaultVoice))").tag(defaultVoice)
                    }
                    Text("Alloy").tag("alloy")
                    Text("Echo").tag("echo")
                    Text("Fable").tag("fable")
                    Text("Onyx").tag("onyx")
                    Text("Nova").tag("nova")
                    Text("Shimmer").tag("shimmer")
                }
                .onChange(of: defaultVoice) { _, _ in
                    onSaveVoice()
                }
            } header: {
                Text("Text-to-Speech")
            } footer: {
                Text("Settings for text-to-speech synthesis.")
            }
            .disabled(!isSupported)
        }
        .formStyle(.grouped)
        .navigationTitle("Audio")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            openAIService.startFetchModelsIfNeeded()
        }
    }
}
