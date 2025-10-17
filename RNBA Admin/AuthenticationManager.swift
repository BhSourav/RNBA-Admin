//
//  AuthenticationManager.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 07.10.25.
//

import Foundation
import LocalAuthentication
import SwiftUI
import Combine
import Supabase

/// Manages authentication using Face ID, Touch ID, or passcode.
/// 
/// This class provides a secure way to authenticate users using biometric authentication
/// or device passcode as a fallback. It follows Apple's security best practices.
@available(iOS 14.0, *)
class AuthenticationManager: ObservableObject {
    
    // MARK: - Published Properties
    
    /// Whether the user is currently authenticated.
    @Published var isAuthenticated = false
    
    /// Whether authentication is currently in progress.
    @Published var isAuthenticating = false
    
    /// The last authentication error, if any.
    @Published var lastError: AuthenticationError?
    
    /// Current authenticated user email
    @Published var currentUserEmail: String?
    
    // MARK: - Private Properties
    
    private let context = LAContext()
    private let reason = "Authenticate to access the RNBA Admin app"
    private let supabase = SupabaseConfig.client
    private let keychain = KeychainManager.shared
    
    // MARK: - Public Methods
    
    /// Sign in with email and password
    func signInWithEmail(_ email: String, password: String, rememberMe: Bool = false) async -> Bool {
        guard !isAuthenticating else { return false }
        
        await MainActor.run {
            isAuthenticating = true
            lastError = nil
        }
        
        print("🔐 Authentication: Starting sign in for email: \(email)")
        
        do {
            // Authenticate with Supabase
            let response = try await supabase.auth.signIn(email: email, password: password)
            
            // Store credentials if remember me is enabled
            if rememberMe {
                let emailSaved = keychain.saveEmail(email)
                let passwordSaved = keychain.savePassword(password)
                print("💾 Authentication: Credentials saved - Email: \(emailSaved), Password: \(passwordSaved)")
            }
            
            await MainActor.run {
                isAuthenticated = true
                currentUserEmail = email
                isAuthenticating = false
            }
            
            print("✅ Authentication: User signed in successfully")
            return true
            
        } catch {
            await MainActor.run {
                lastError = .authenticationFailed
                isAuthenticated = false
                isAuthenticating = false
            }
            print("❌ Authentication: Sign in failed - \(error.localizedDescription)")
            return false
        }
    }
    
    /// Authenticate using biometric authentication (uses stored credentials)
    func authenticateWithBiometrics() async -> Bool {
        guard !isAuthenticating else { return false }
        
        // Check if biometric is enabled and credentials are stored
        guard keychain.isBiometricEnabled(),
              let email = keychain.getEmail(),
              let password = keychain.getPassword() else {
            await MainActor.run {
                lastError = .biometricNotEnabled
            }
            return false
        }
        
        await MainActor.run {
            isAuthenticating = true
            lastError = nil
        }
        
        do {
            // First, perform biometric authentication
            let biometricSuccess = try await performBiometricAuthentication()
            
            if biometricSuccess {
                // Then, authenticate with Supabase using stored credentials
                let response = try await supabase.auth.signIn(email: email, password: password)
                
                await MainActor.run {
                    isAuthenticated = true
                    currentUserEmail = email
                    isAuthenticating = false
                }
                
                print("✅ Authentication: Biometric sign in successful")
                return true
            } else {
                await MainActor.run {
                    lastError = .authenticationFailed
                    isAuthenticated = false
                    isAuthenticating = false
                }
                return false
            }
            
        } catch {
            await MainActor.run {
                lastError = AuthenticationError.from(error)
                isAuthenticated = false
                isAuthenticating = false
            }
            print("❌ Authentication: Biometric sign in failed - \(error.localizedDescription)")
            return false
        }
    }
    
    /// Signs out the current user
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            await MainActor.run {
                isAuthenticated = false
                currentUserEmail = nil
                lastError = nil
            }
            print("✅ Authentication: User signed out successfully")
        } catch {
            print("❌ Authentication: Sign out failed - \(error.localizedDescription)")
        }
    }
    
    /// Test Supabase connectivity and configuration
    func testSupabaseConnection() async -> Bool {
        // Test basic connectivity
        let connectivityTest = await SupabaseConfig.testConnectivity()
        if !connectivityTest {
            return false
        }
        
        // Test Supabase Auth (simple session check)
        do {
            // Try to get the current session (should work even if not authenticated)
            let _ = try await supabase.auth.session
            return true
        } catch let error as NSError {
            // Check if this is the expected "Auth session missing" error (code 9)
            // This is normal when not logged in - it means Supabase is working
            if error.code == 9 && error.domain == "Auth.AuthError" && 
               error.localizedDescription.contains("Auth session missing") {
                return true
            }
            return false
        }
    }
    
    /// Enable biometric authentication for the current user
    func enableBiometricAuth() {
        keychain.setBiometricEnabled(true)
        print("✅ Authentication: Biometric authentication enabled")
    }
    
    /// Disable biometric authentication
    func disableBiometricAuth() {
        keychain.setBiometricEnabled(false)
        _ = keychain.deleteAllCredentials()
        print("✅ Authentication: Biometric authentication disabled")
    }
    
    /// Checks if biometric authentication is available on the device.
    /// - Returns: `true` if biometric authentication is available, `false` otherwise.
    func isBiometricAuthenticationAvailable() -> Bool {
        var error: NSError?
        let canEvaluate = context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error)
        return canEvaluate
    }
    
    /// Gets the type of biometric authentication available on the device.
    /// - Returns: The biometric type available, or `nil` if none is available.
    func getBiometricType() -> LABiometryType? {
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return nil
        }
        return context.biometryType
    }
    
    // MARK: - Private Methods
    
    /// Performs the actual biometric authentication
    private func performBiometricAuthentication() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
            let context = LAContext()
            context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            ) { success, error in
                if success {
                    continuation.resume(returning: true)
                } else {
                    continuation.resume(throwing: error ?? AuthenticationError.unknown)
                }
            }
        }
    }
}

// MARK: - Authentication Error

/// Errors that can occur during authentication.
enum AuthenticationError: LocalizedError, Equatable {
    case biometricNotAvailable
    case biometricNotEnrolled
    case biometricLockout
    case biometricNotEnabled
    case userCancel
    case systemCancel
    case authenticationFailed
    case invalidCredentials
    case networkError
    case unknown
    
    /// Creates an `AuthenticationError` from a system error.
    /// - Parameter error: The system error to convert.
    /// - Returns: The corresponding `AuthenticationError`.
    static func from(_ error: Error) -> AuthenticationError {
        guard let laError = error as? LAError else {
            return .unknown
        }
        
        switch laError.code {
        case .biometryNotAvailable:
            return .biometricNotAvailable
        case .biometryNotEnrolled:
            return .biometricNotEnrolled
        case .biometryLockout:
            return .biometricLockout
        case .userCancel:
            return .userCancel
        case .systemCancel:
            return .systemCancel
        case .authenticationFailed:
            return .authenticationFailed
        default:
            return .unknown
        }
    }
    
    var errorDescription: String? {
        switch self {
        case .biometricNotAvailable:
            return "Biometric authentication is not available on this device."
        case .biometricNotEnrolled:
            return "No biometric data is enrolled. Please set up Face ID or Touch ID in Settings."
        case .biometricLockout:
            return "Biometric authentication is locked. Please use your passcode to unlock."
        case .biometricNotEnabled:
            return "Biometric authentication is not enabled. Please sign in with email and password first."
        case .userCancel:
            return "Authentication was cancelled by the user."
        case .systemCancel:
            return "Authentication was cancelled by the system."
        case .authenticationFailed:
            return "Authentication failed. Please check your credentials and try again."
        case .invalidCredentials:
            return "Invalid email or password. Please try again."
        case .networkError:
            return "Network error. Please check your connection and try again."
        case .unknown:
            return "An unknown authentication error occurred."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .biometricNotAvailable:
            return "Please use email and password to sign in."
        case .biometricNotEnrolled:
            return "Go to Settings > Face ID & Passcode (or Touch ID & Passcode) to set up biometric authentication."
        case .biometricLockout:
            return "Enter your device passcode to unlock biometric authentication."
        case .biometricNotEnabled:
            return "Sign in with email and password, then enable biometric authentication in settings."
        case .userCancel:
            return "Tap the authentication button to try again."
        case .systemCancel:
            return "Authentication was interrupted. Please try again."
        case .authenticationFailed:
            return "Please check your email and password, then try again."
        case .invalidCredentials:
            return "Verify your email and password are correct."
        case .networkError:
            return "Check your internet connection and try again."
        case .unknown:
            return "Please try again or restart the app."
        }
    }
}
