import Foundation
import Security

/// A service for securely storing and retrieving sensitive data using the Keychain.
/// Supports iCloud Keychain sync for seamless multi-device experience.
final class KeychainService {
    static let shared = KeychainService()
    
    private let serviceName = "com.weichart.AI-Shortcuts"
    
    private init() {}
    
    // MARK: - API Key
    
    private let apiKeyAccount = "openai-api-key"
    
    var apiKey: String? {
        get { retrieve(account: apiKeyAccount) }
        set {
            if let newValue {
                save(newValue, account: apiKeyAccount)
            } else {
                delete(account: apiKeyAccount)
            }
        }
    }
    
    /// Whether iCloud Keychain sync is available
    var iCloudKeychainAvailable: Bool {
        FileManager.default.ubiquityIdentityToken != nil
    }
    
    // MARK: - Synced Keychain Methods
    
    private func save(_ value: String, account: String) {
        guard let data = value.data(using: .utf8) else { return }
        
        // Delete existing item first (both synced and local)
        delete(account: account)
        
        // Save with iCloud sync enabled
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            kSecAttrSynchronizable as String: true  // Enable iCloud Keychain sync
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            // Fallback: try saving without sync if iCloud Keychain is disabled
            let localQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
                kSecAttrSynchronizable as String: false
            ]
            SecItemAdd(localQuery as CFDictionary, nil)
        }
    }
    
    private func retrieve(account: String) -> String? {
        // First try synced keychain
        let syncedQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: true,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        var status = SecItemCopyMatching(syncedQuery as CFDictionary, &result)
        
        if status == errSecSuccess,
           let data = result as? Data,
           let string = String(data: data, encoding: .utf8) {
            return string
        }
        
        // Fallback to local keychain (e.g. when iCloud Keychain sync is disabled)
        let localQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        result = nil
        status = SecItemCopyMatching(localQuery as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return string
    }
    
    private func delete(account: String) {
        // Delete from synced keychain
        let syncedQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: true
        ]
        SecItemDelete(syncedQuery as CFDictionary)
        
        // Also delete from local keychain
        deleteLocal(account: account)
    }
    
    // MARK: - Local Keychain Methods
    
    private func deleteLocal(account: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false
        ]
        SecItemDelete(query as CFDictionary)
    }
}
