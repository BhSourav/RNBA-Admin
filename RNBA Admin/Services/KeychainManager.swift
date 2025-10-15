//
//  KeychainManager.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 15.10.25.
//  Secure storage for user credentials using iOS Keychain
//

import Foundation
import Security

/// Manages secure storage and retrieval of credentials using iOS Keychain
@available(iOS 14.0, *)
class KeychainManager {
    
    // MARK: - Singleton
    
    static let shared = KeychainManager()
    
    private init() {}
    
    // MARK: - Keys
    
    private enum Keys {
        static let service = "com.rnba.admin"
        static let emailAccount = "user_email"
        static let passwordAccount = "user_password"
        static let biometricEnabledKey = "biometric_enabled"
    }
    
    // MARK: - Public Methods
    
    /// Save email to Keychain
    func saveEmail(_ email: String) -> Bool {
        return save(email, account: Keys.emailAccount)
    }
    
    /// Save password to Keychain
    func savePassword(_ password: String) -> Bool {
        return save(password, account: Keys.passwordAccount)
    }
    
    /// Retrieve email from Keychain
    func getEmail() -> String? {
        return retrieve(account: Keys.emailAccount)
    }
    
    /// Retrieve password from Keychain
    func getPassword() -> String? {
        return retrieve(account: Keys.passwordAccount)
    }
    
    /// Delete email from Keychain
    func deleteEmail() -> Bool {
        return delete(account: Keys.emailAccount)
    }
    
    /// Delete password from Keychain
    func deletePassword() -> Bool {
        return delete(account: Keys.passwordAccount)
    }
    
    /// Delete all credentials from Keychain
    func deleteAllCredentials() -> Bool {
        let emailDeleted = deleteEmail()
        let passwordDeleted = deletePassword()
        UserDefaults.standard.set(false, forKey: Keys.biometricEnabledKey)
        return emailDeleted && passwordDeleted
    }
    
    /// Check if credentials are stored
    func hasStoredCredentials() -> Bool {
        return getEmail() != nil && getPassword() != nil
    }
    
    // MARK: - Biometric Preference (UserDefaults)
    
    /// Save biometric authentication preference
    func setBiometricEnabled(_ enabled: Bool) {
        UserDefaults.standard.set(enabled, forKey: Keys.biometricEnabledKey)
    }
    
    /// Get biometric authentication preference
    func isBiometricEnabled() -> Bool {
        return UserDefaults.standard.bool(forKey: Keys.biometricEnabledKey)
    }
    
    // MARK: - Private Methods
    
    /// Save data to Keychain
    private func save(_ value: String, account: String) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        // First, try to update if item exists
        let updateQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: account
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let updateStatus = SecItemUpdate(updateQuery as CFDictionary, attributes as CFDictionary)
        
        if updateStatus == errSecSuccess {
            return true
        }
        
        // If update fails, add new item
        if updateStatus == errSecItemNotFound {
            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Keys.service,
                kSecAttrAccount as String: account,
                kSecValueData as String: data,
                kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            ]
            
            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            return addStatus == errSecSuccess
        }
        
        return false
    }
    
    /// Retrieve data from Keychain
    private func retrieve(account: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Delete data from Keychain
    private func delete(account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: account
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}
