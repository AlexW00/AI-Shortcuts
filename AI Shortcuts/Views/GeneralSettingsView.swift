//
//  GeneralSettingsView.swift
//  AI Shortcuts
//
//  Created by Alex Weichart on 30.12.25.
//

import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var openAIService: OpenAIService
    @ObservedObject var settingsStore: SettingsStore = .shared
    
    @Binding var apiKey: String
    @Binding var endpointHost: String
    @Binding var endpointBasePath: String
    @Binding var endpointPort: String
    @Binding var endpointScheme: String
    
    @State private var showingAPIKey = false
    @State private var isSyncingNow = false
    @FocusState private var focusedField: FocusField?

    private enum FocusField: Hashable {
        case apiKey
        case host
        case basePath
        case port
    }

    private let defaultHost = "api.openai.com"
    private let defaultBasePath = "/v1"

    private var defaultPortForScheme: String {
        endpointScheme.lowercased() == "http" ? "80" : "443"
    }

    private var hasEndpointOverrides: Bool {
        !endpointHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !endpointBasePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        !endpointPort.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ||
        endpointScheme.lowercased() != "https"
    }

    private func normalizeHost(_ rawValue: String) -> String {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "" }

        // If the user pasted a full URL, keep only the host.
        if let url = URL(string: value), let host = url.host {
            return host == defaultHost ? "" : host
        }

        // Trim any accidental trailing slash.
        let trimmed = value.hasSuffix("/") ? String(value.drop(while: { $0 == "/" })) : value
        return trimmed == defaultHost ? "" : trimmed
    }

    private func normalizeBasePath(_ rawValue: String) -> String {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "" }

        var normalized = value
        if !normalized.hasPrefix("/") {
            normalized = "/" + normalized
        }
        return normalized == defaultBasePath ? "" : normalized
    }

    private func normalizePort(_ rawValue: String) -> String {
        let value = rawValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return "" }
        guard let intValue = Int(value), intValue > 0 else { return "" }
        return String(intValue) == defaultPortForScheme ? "" : String(intValue)
    }

    private var hostBinding: Binding<String> {
        Binding(
            get: { endpointHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultHost : endpointHost },
            set: { endpointHost = normalizeHost($0) }
        )
    }

    private var basePathBinding: Binding<String> {
        Binding(
            get: { endpointBasePath.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultBasePath : endpointBasePath },
            set: { endpointBasePath = normalizeBasePath($0) }
        )
    }

    private var portBinding: Binding<String> {
        Binding(
            get: { endpointPort.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? defaultPortForScheme : endpointPort },
            set: { endpointPort = normalizePort($0) }
        )
    }
    
    var onSaveAPIKey: () -> Void
    var onSaveEndpoint: () -> Void
    
    var body: some View {
        Form {
            // MARK: - API Key
            Section {
                HStack {
                    Group {
                        if showingAPIKey {
                            TextField("Enter your API key", text: $apiKey)
                                .onSubmit { onSaveAPIKey() }
                                .focused($focusedField, equals: .apiKey)
                        } else {
                            SecureField("Enter your API key", text: $apiKey)
                                .onSubmit { onSaveAPIKey() }
                                .focused($focusedField, equals: .apiKey)
                        }
                    }
                    .autocorrectionDisabled()
                    #if os(iOS)
                    .textInputAutocapitalization(.never)
                    #endif
                    
                    Button {
                        showingAPIKey.toggle()
                    } label: {
                        Image(systemName: showingAPIKey ? "eye.slash" : "eye")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } header: {
                Text("API Key")
            } footer: {
                Text("Your OpenAI API key. Stored securely in Keychain and synced via iCloud Keychain.")
            }

            // MARK: - Endpoint Settings
            Section {
                LabeledContent("Host") {
                    TextField("", text: hostBinding)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .onSubmit { onSaveEndpoint() }
                        .focused($focusedField, equals: .host)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }
                
                LabeledContent("Base Path") {
                    TextField("", text: basePathBinding)
                        .multilineTextAlignment(.trailing)
                        .autocorrectionDisabled()
                        .onSubmit { onSaveEndpoint() }
                        .focused($focusedField, equals: .basePath)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        #endif
                }
                
                LabeledContent("Scheme") {
                    Picker("", selection: $endpointScheme) {
                        Text("https").tag("https")
                        Text("http").tag("http")
                    }
                    .pickerStyle(.menu)
                    .labelsHidden()
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .fixedSize(horizontal: true, vertical: false)
                    .onChange(of: endpointScheme) { _, _ in
                        onSaveEndpoint()
                    }
                }
                
                LabeledContent("Port") {
                    TextField("", text: portBinding)
                        .multilineTextAlignment(.trailing)
                        .onSubmit { onSaveEndpoint() }
                        .focused($focusedField, equals: .port)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                        .frame(maxWidth: 100)
                }
                
                if hasEndpointOverrides {
                    Button("Reset to Default") {
                        endpointHost = ""
                        endpointBasePath = ""
                        endpointPort = ""
                        endpointScheme = "https"
                        onSaveEndpoint()
                    }
                    .foregroundStyle(.red)
                }
            } header: {
                Text("Endpoint Settings")
            } footer: {
                Text("Configure custom API endpoints. Leave empty to use OpenAI's default (api.openai.com).")
            }

            // MARK: - API Status
            Section("Status") {
                LabeledContent("API") {
                    HStack(spacing: 6) {
                        if !openAIService.isConfigured {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.red)
                            Text("Not Configured")
                                .foregroundStyle(.red)
                        } else {
                            switch openAIService.connectionStatus {
                            case .unknown:
                                Image(systemName: "questionmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                Text("Not Verified")
                                    .foregroundStyle(.secondary)
                            case .verifying:
                                ProgressView()
                                    .scaleEffect(0.7)
                                Text("Verifying...")
                                    .foregroundStyle(.secondary)
                            case .success:
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Connected")
                            case .failure(let error):
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.red)
                                Text(error)
                                    .font(.caption)
                                    .foregroundStyle(.red)
                                    .lineLimit(2)
                            }
                        }
                    }
                }

                LabeledContent("Endpoint") {
                    Text(openAIService.effectiveEndpointDescription)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }

                if openAIService.isConfigured && !openAIService.isVerifyingConnection {
                    Button("Verify Connection") {
                        Task {
                            await openAIService.verifyConnection()
                        }
                    }
                }
            }
            
            // MARK: - iCloud Sync Status
            Section {
                LabeledContent("iCloud Sync") {
                    HStack(spacing: 6) {
                        if settingsStore.iCloudAvailable {
                            Image(systemName: "checkmark.icloud.fill")
                                .foregroundStyle(.green)
                            Text("Enabled")
                        } else {
                            Image(systemName: "xmark.icloud")
                                .foregroundStyle(.secondary)
                            Text("Unavailable")
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                HStack(spacing: 8) {
                    Button(isSyncingNow ? "Syncing…" : "Sync Now") {
                        Task { @MainActor in
                            guard !isSyncingNow else { return }
                            isSyncingNow = true
                            defer { isSyncingNow = false }
                            settingsStore.synchronize()
                            try? await Task.sleep(nanoseconds: 700_000_000)
                        }
                    }
                    .disabled(isSyncingNow || !settingsStore.iCloudAvailable)

                    if isSyncingNow {
                        ProgressView()
                    }
                }
            } header: {
                Text("Sync")
            } footer: {
                Text("Settings sync across devices via iCloud. API key syncs via iCloud Keychain when enabled in System Settings.")
            }
        }
        .onChange(of: focusedField) { oldValue, newValue in
            if oldValue == .apiKey, newValue != .apiKey {
                onSaveAPIKey()
            }

            let wasEndpointField = oldValue == .host || oldValue == .basePath || oldValue == .port
            let isEndpointField = newValue == .host || newValue == .basePath || newValue == .port
            if wasEndpointField, !isEndpointField {
                onSaveEndpoint()
            }
        }
        // Immediately invalidate the displayed connection state while the user is editing.
        // This prevents a stale "Connected" from sticking around until the field is saved.
        .onChange(of: apiKey) { _, _ in
            openAIService.markConnectionNeedsVerification()
        }
        .onChange(of: endpointHost) { _, _ in
            openAIService.markConnectionNeedsVerification()
        }
        .onChange(of: endpointBasePath) { _, _ in
            openAIService.markConnectionNeedsVerification()
        }
        .onChange(of: endpointPort) { _, _ in
            openAIService.markConnectionNeedsVerification()
        }
        .onChange(of: endpointScheme) { _, _ in
            openAIService.markConnectionNeedsVerification()
        }
        .formStyle(.grouped)
        .navigationTitle("General")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}
