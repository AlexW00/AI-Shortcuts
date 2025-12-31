//
//  SettingsStore.swift
//  AI Shortcuts
//
//  Created by Alex Weichart on 31.12.25.
//

import Foundation
import Combine

/// Centralized settings storage with iCloud sync via NSUbiquitousKeyValueStore.
/// Falls back to UserDefaults when iCloud is unavailable.
@MainActor
final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()
    
    // MARK: - Published Properties
    
    /// Whether iCloud sync is available and working
    @Published private(set) var iCloudAvailable: Bool = false
    
    /// Last sync date from iCloud
    @Published private(set) var lastSyncDate: Date?
    
    // MARK: - Settings Keys
    
    private enum Keys {
        // Endpoint settings
        static let endpointHost = "endpointHost"
        static let endpointBasePath = "endpointBasePath"
        static let endpointScheme = "endpointScheme"
        static let endpointPort = "endpointPort"
        
        // Model settings
        static let defaultModel = "defaultModel"
        static let imageModel = "imageModel"
        static let transcriptionModel = "transcriptionModel"
        static let ttsModel = "ttsModel"
        static let defaultVoice = "defaultVoice"
        
        // Sync metadata
        static let lastSyncDate = "lastSyncDate"
    }
    
    // MARK: - Storage
    
    private let cloud = NSUbiquitousKeyValueStore.default
    private let local = UserDefaults.standard
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    private init() {
        setupCloudSync()
        checkCloudAvailability()
    }
    
    // MARK: - Cloud Sync Setup
    
    private func setupCloudSync() {
        // Listen for external changes from iCloud
        NotificationCenter.default.publisher(for: NSUbiquitousKeyValueStore.didChangeExternallyNotification, object: cloud)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                self?.handleCloudChange(notification)
            }
            .store(in: &cancellables)
        
        // Start synchronization
        cloud.synchronize()
    }
    
    private func checkCloudAvailability() {
        // Check if iCloud is available by attempting to read
        // NSUbiquitousKeyValueStore works even offline, syncing when available
        iCloudAvailable = FileManager.default.ubiquityIdentityToken != nil
    }
    
    private func handleCloudChange(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let changeReason = userInfo[NSUbiquitousKeyValueStoreChangeReasonKey] as? Int else {
            return
        }
        
        switch changeReason {
        case NSUbiquitousKeyValueStoreServerChange,
             NSUbiquitousKeyValueStoreInitialSyncChange:
            // External changes received - notify observers
            lastSyncDate = Date()
            objectWillChange.send()
            
            // Post notification for other parts of the app
            NotificationCenter.default.post(name: .settingsDidSyncFromCloud, object: nil)
            
        case NSUbiquitousKeyValueStoreQuotaViolationChange:
            // Handle quota exceeded
            print("iCloud KVS quota exceeded")
            
        case NSUbiquitousKeyValueStoreAccountChange:
            // iCloud account changed
            checkCloudAvailability()
            
        default:
            break
        }
    }
    
    // MARK: - Endpoint Settings
    
    var endpointHost: String {
        get { getString(Keys.endpointHost) ?? "" }
        set { setString(newValue.isEmpty ? nil : newValue, forKey: Keys.endpointHost) }
    }
    
    var endpointBasePath: String {
        get { getString(Keys.endpointBasePath) ?? "" }
        set { setString(newValue.isEmpty ? nil : newValue, forKey: Keys.endpointBasePath) }
    }
    
    var endpointScheme: String {
        get { getString(Keys.endpointScheme) ?? "https" }
        set { setString(newValue, forKey: Keys.endpointScheme) }
    }
    
    var endpointPort: Int {
        get { getInt(Keys.endpointPort) }
        set { setInt(newValue > 0 ? newValue : 0, forKey: Keys.endpointPort) }
    }
    
    // MARK: - Model Settings
    
    var defaultModel: String {
        get { getString(Keys.defaultModel) ?? "" }
        set { setString(newValue.isEmpty ? nil : newValue, forKey: Keys.defaultModel) }
    }
    
    var imageModel: String {
        get { getString(Keys.imageModel) ?? "" }
        set { setString(newValue.isEmpty ? nil : newValue, forKey: Keys.imageModel) }
    }
    
    var transcriptionModel: String {
        get { getString(Keys.transcriptionModel) ?? "" }
        set { setString(newValue.isEmpty ? nil : newValue, forKey: Keys.transcriptionModel) }
    }
    
    var ttsModel: String {
        get { getString(Keys.ttsModel) ?? "" }
        set { setString(newValue.isEmpty ? nil : newValue, forKey: Keys.ttsModel) }
    }
    
    var defaultVoice: String {
        get { getString(Keys.defaultVoice) ?? "alloy" }
        set { setString(newValue, forKey: Keys.defaultVoice) }
    }
    
    // MARK: - Sync Control
    
    /// Force sync with iCloud
    func synchronize() {
        cloud.synchronize()
        lastSyncDate = Date()
    }
    
    // MARK: - Private Helpers
    
    private func getString(_ key: String) -> String? {
        // Prefer cloud value, fall back to local
        if let cloudValue = cloud.string(forKey: key) {
            return cloudValue
        }
        return local.string(forKey: key)
    }
    
    private func setString(_ value: String?, forKey key: String) {
        // Write to both cloud and local
        if let value = value {
            cloud.set(value, forKey: key)
            local.set(value, forKey: key)
        } else {
            cloud.removeObject(forKey: key)
            local.removeObject(forKey: key)
        }
        cloud.synchronize()
    }
    
    private func getInt(_ key: String) -> Int {
        // Cloud returns 0 if not found, check if it exists
        if cloud.object(forKey: key) != nil {
            return Int(cloud.longLong(forKey: key))
        }
        return local.integer(forKey: key)
    }
    
    private func setInt(_ value: Int, forKey key: String) {
        if value > 0 {
            cloud.set(Int64(value), forKey: key)
            local.set(value, forKey: key)
        } else {
            cloud.removeObject(forKey: key)
            local.removeObject(forKey: key)
        }
        cloud.synchronize()
    }
}

// MARK: - Notifications

extension Notification.Name {
    /// Posted when settings are synced from iCloud
    static let settingsDidSyncFromCloud = Notification.Name("settingsDidSyncFromCloud")
}
