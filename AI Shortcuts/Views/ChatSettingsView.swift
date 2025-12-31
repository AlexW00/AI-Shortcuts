//
//  ChatSettingsView.swift
//  AI Shortcuts
//
//  Created by Alex Weichart on 30.12.25.
//

import SwiftUI
import OpenAI

struct ChatSettingsView: View {
    @ObservedObject var openAIService: OpenAIService
    
    @Binding var defaultModel: String
    
    var onSaveModel: () -> Void
    
    // Chat is always supported
    private var isSupported: Bool { true }
    
    private var hasModels: Bool {
        !openAIService.chatModels.isEmpty
    }
    
    var body: some View {
        Form {
            // MARK: - Error State
            if let error = openAIService.modelsFetchError {
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
                Label("Ask AI", systemImage: "text.bubble")
            } header: {
                Text("Available Shortcuts")
            } footer: {
                Text("Use these actions in the Shortcuts app to ask questions with AI.")
            }
            
            // MARK: - Model Settings
            Section {
                if openAIService.isLoadingModels {
                    HStack {
                        Text("Default Model")
                        Spacer()
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                } else if hasModels {
                    Picker("Default Model", selection: $defaultModel) {
                        Text("Default (\(openAIService.inferredDefaultChatModel))").tag("")
                        if !defaultModel.isEmpty,
                           !openAIService.chatModels.contains(where: { $0.id == defaultModel }) {
                            Text("Custom (\(defaultModel))").tag(defaultModel)
                        }
                        ForEach(openAIService.chatModels, id: \.id) { model in
                            Text(model.id).tag(model.id)
                        }
                    }
                    .onChange(of: defaultModel) { _, _ in
                        onSaveModel()
                    }
                } else {
                    LabeledContent("Default Model") {
                        Text(defaultModel.isEmpty ? openAIService.inferredDefaultChatModel : defaultModel)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Model")
            } footer: {
                if hasModels {
                    Text("The model to use when not specified in shortcuts.")
                } else {
                    Text("Configure API key to load available models.")
                }
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Chat")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        .onAppear {
            openAIService.startFetchModelsIfNeeded()
        }
    }
}
