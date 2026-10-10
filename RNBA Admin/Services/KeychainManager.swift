//
//  KeychainManager.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 15.10.25.
//  Secure storage for user credentials using iOS Keychain
//

import Foundation
import Security
import LocalAuthentication

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
        return save(email, account: Keys.emailAccount, requireBiometry: false)
    }
    
    /// Save password to Keychain. The item's access control itself requires a successful
    /// biometric (Face ID / Touch ID) evaluation to decrypt - this is enforced by the
    /// Keychain/Secure Enclave, not just an app-level check before reading it.
    func savePassword(_ password: String) -> Bool {
        return save(password, account: Keys.passwordAccount, requireBiometry: true)
    }
    
    /// Retrieve email from Keychain
    func getEmail() -> String? {
        return retrieve(account: Keys.emailAccount, context: nil)
    }
    
    /// Retrieve password from Keychain. Since the item is protected with a biometry-bound
    /// access control, this call triggers the system Face ID / Touch ID prompt unless
    /// `context` is an already-authenticated `LAContext`, in which case that result is reused.
    func getPassword(context: LAContext? = nil) -> String? {
        return retrieve(account: Keys.passwordAccount, context: context)
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
    
    /// Check if credentials are stored. Checks existence only (does not decrypt the
    /// password value), so this never triggers a biometric prompt.
    func hasStoredCredentials() -> Bool {
        return getEmail() != nil && accountExists(Keys.passwordAccount)
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
    
    /// Save data to Keychain. Existing items are removed first rather than updated in place,
    /// since changing a stored item's access control via `SecItemUpdate` is unreliable.
    private func save(_ value: String, account: String, requireBiometry: Bool) -> Bool {
        guard let data = value.data(using: .utf8) else {
            return false
        }
        
        _ = delete(account: account)
        
        var addQuery: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data
        ]
        
        if requireBiometry {
            guard let accessControl = SecAccessControlCreateWithFlags(
                nil,
                kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
                .biometryCurrentSet,
                nil
            ) else {
                return false
            }
            addQuery[kSecAttrAccessControl as String] = accessControl
        } else {
            addQuery[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        }
        
        let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
        return addStatus == errSecSuccess
    }
    
    /// Retrieve data from Keychain. If the item is biometry-protected, this prompts for
    /// Face ID / Touch ID (via `context` if supplied, otherwise a context Security creates internally).
    private func retrieve(account: String, context: LAContext?) -> String? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        if let context = context {
            query[kSecUseAuthenticationContext as String] = context
        }
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    /// Checks whether an item exists without reading its (possibly biometry-protected) value.
    private func accountExists(_ account: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Keys.service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: false,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
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
