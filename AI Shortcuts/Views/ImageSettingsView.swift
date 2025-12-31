//
//  ImageSettingsView.swift
//  AI Shortcuts
//
//  Created by Alex Weichart on 30.12.25.
//

import SwiftUI
import OpenAI

struct ImageSettingsView: View {
    @ObservedObject var openAIService: OpenAIService
    
    @Binding var imageModel: String
    
    var onSaveModel: () -> Void
    
    private var isSupported: Bool {
        !openAIService.isUsingCustomEndpoint
    }
    
    private var hasModels: Bool {
        !openAIService.imageModels.isEmpty
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
                            Text("Image generation requires the official OpenAI API. Your current custom endpoint may not support the Images API.")
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
                    Label("Generate Image", systemImage: "photo.badge.plus")
                    Spacer()
                    if !isSupported {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.red)
                    }
                }
            } header: {
                Text("Available Shortcuts")
            } footer: {
                Text("Generate images using your selected image model. Requires the official OpenAI API.")
            }
            
            // MARK: - Model Settings
            Section {
                if openAIService.isLoadingModels {
                    HStack {
                        Text("Image Model")
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                } else if hasModels {
                    Picker("Image Model", selection: $imageModel) {
                        Text("Default (\(openAIService.inferredDefaultImageModel))").tag("")
                        if !imageModel.isEmpty,
                           !openAIService.imageModels.contains(where: { $0.id == imageModel }) {
                            Text("Custom (\(imageModel))").tag(imageModel)
                        }
                        ForEach(openAIService.imageModels, id: \.id) { model in
                            Text(model.id).tag(model.id)
                        }
                    }
                    .onChange(of: imageModel) { _, _ in
                        onSaveModel()
                    }
                } else {
                    LabeledContent("Image Model") {
                        Text(imageModel.isEmpty ? openAIService.inferredDefaultImageModel : imageModel)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Model")
            } footer: {
                if hasModels {
                    Text("The model used for image generation.")
                } else {
                    Text("Configure API key to load available models.")
                }
            }
            .disabled(!isSupported)
        }
        .formStyle(.grouped)
        .navigationTitle("Image")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            openAIService.startFetchModelsIfNeeded()
        }
    }
}
