//
//  ContentView.swift
//  AI Shortcuts
//
//  Created by Alex Weichart on 30.12.25.
//

import SwiftUI
import Combine

struct ContentView: View {
    @StateObject private var openAIService = OpenAIService.shared
    @StateObject private var settingsStore = SettingsStore.shared

    @State private var didRunStartupTasks: Bool = false
    
    // General settings
    @State private var apiKey: String = ""
    @State private var endpointHost: String = ""
    @State private var endpointBasePath: String = ""
    @State private var endpointPort: String = ""
    @State private var endpointScheme: String = "https"
    
    // Chat settings
    @State private var defaultModel: String = ""
    
    // Image settings
    @State private var imageModel: String = ""
    
    // Audio settings
    @State private var transcriptionModel: String = ""
    @State private var ttsModel: String = ""
    @State private var defaultVoice: String = "alloy"
    
    // UI state
    @State private var selectedCategory: SettingsCategory? = .general
    
    // iCloud sync observer
    @State private var cloudSyncCancellable: AnyCancellable?
    
    var body: some View {
        NavigationSplitView {
            List(SettingsCategory.allCases, selection: $selectedCategory) { category in
                NavigationLink(value: category) {
                    Label {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(category.rawValue)
                            Text(category.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } icon: {
                        Image(systemName: category.icon)
                    }
                }
            }
            .navigationTitle("AI Shortcuts")
            #if os(macOS)
            .navigationSplitViewColumnWidth(min: 200, ideal: 220)
            #endif
        } detail: {
            if let category = selectedCategory {
                detailView(for: category)
            } else {
                Text("Select a category")
                    .foregroundStyle(.secondary)
            }
        }
        .task {
            guard !didRunStartupTasks else { return }
            didRunStartupTasks = true

            loadSettings()
            
            // Listen for iCloud sync changes
            cloudSyncCancellable = NotificationCenter.default
                .publisher(for: .settingsDidSyncFromCloud)
                .receive(on: DispatchQueue.main)
                .sink { _ in
                    loadSettings()
                    openAIService.refreshClient()
                }

            if openAIService.isConfigured {
                openAIService.startFetchModelsIfNeeded()
                await openAIService.verifyConnection()
            }
        }
    }
    
    // MARK: - Detail Views
    
    @ViewBuilder
    private func detailView(for category: SettingsCategory) -> some View {
        switch category {
        case .general:
            GeneralSettingsView(
                openAIService: openAIService,
                apiKey: $apiKey,
                endpointHost: $endpointHost,
                endpointBasePath: $endpointBasePath,
                endpointPort: $endpointPort,
                endpointScheme: $endpointScheme,
                onSaveAPIKey: saveAPIKey,
                onSaveEndpoint: saveEndpointSettings
            )
        case .chat:
            ChatSettingsView(
                openAIService: openAIService,
                defaultModel: $defaultModel,
                onSaveModel: saveChatModel
            )
        case .image:
            ImageSettingsView(
                openAIService: openAIService,
                imageModel: $imageModel,
                onSaveModel: saveImageModel
            )
        case .audio:
            AudioSettingsView(
                openAIService: openAIService,
                transcriptionModel: $transcriptionModel,
                ttsModel: $ttsModel,
                defaultVoice: $defaultVoice,
                onSaveTranscription: saveTranscriptionModel,
                onSaveTTS: saveTTSModel,
                onSaveVoice: saveVoice
            )
        }
    }
    
    // MARK: - Load Settings
    
    private func loadSettings() {
        let settings = settingsStore
        
        // General
        apiKey = KeychainService.shared.apiKey ?? ""
        endpointHost = settings.endpointHost
        endpointBasePath = settings.endpointBasePath
        endpointScheme = settings.endpointScheme
        
        let storedPort = settings.endpointPort
        endpointPort = storedPort > 0 ? String(storedPort) : ""
        
        // Chat
        defaultModel = settings.defaultModel
        
        // Image
        imageModel = settings.imageModel
        
        // Audio
        transcriptionModel = settings.transcriptionModel
        ttsModel = settings.ttsModel
        defaultVoice = settings.defaultVoice
    }
    
    // MARK: - Save Actions (General)
    
    private func saveAPIKey() {
        KeychainService.shared.apiKey = apiKey.isEmpty ? nil : apiKey
        openAIService.refreshClient()
        
        // Verify connection after saving API key
        if openAIService.isConfigured {
            openAIService.startFetchModelsIfNeeded(forceRefresh: true)
            Task {
                await openAIService.verifyConnection()
            }
        }
    }
    
    private func saveEndpointSettings() {
        let settings = settingsStore
        settings.endpointHost = endpointHost
        settings.endpointBasePath = endpointBasePath
        settings.endpointScheme = endpointScheme
        
        if let port = Int(endpointPort), port > 0 {
            settings.endpointPort = port
        } else {
            settings.endpointPort = 0
        }
        
        openAIService.refreshClient()
        
        // Verify connection after changing endpoint settings
        if openAIService.isConfigured {
            openAIService.startFetchModelsIfNeeded(forceRefresh: true)
            Task {
                await openAIService.verifyConnection()
            }
        }
    }
    
    // MARK: - Save Actions (Chat)
    
    private func saveChatModel() {
        settingsStore.defaultModel = defaultModel
    }
    
    // MARK: - Save Actions (Image)
    
    private func saveImageModel() {
        settingsStore.imageModel = imageModel
    }
    
    // MARK: - Save Actions (Audio)
    
    private func saveTranscriptionModel() {
        settingsStore.transcriptionModel = transcriptionModel
    }
    
    private func saveTTSModel() {
        settingsStore.ttsModel = ttsModel
    }
    
    private func saveVoice() {
        settingsStore.defaultVoice = defaultVoice
    }
}

#Preview {
    ContentView()
}
