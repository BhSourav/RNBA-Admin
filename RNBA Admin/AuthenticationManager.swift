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
    
    // MARK: - Private Properties
    
    private let context = LAContext()
    private let reason = "Authenticate to access the RNBA Admin app"
    
    // MARK: - Public Methods
    
    /// Attempts to authenticate the user using available biometric authentication.
    /// - Returns: `true` if authentication succeeds, `false` otherwise.
    func authenticate() async -> Bool {
        guard !isAuthenticating else { return false }
        
        await MainActor.run {
            isAuthenticating = true
            lastError = nil
        }
        
        do {
            let success = try await authenticateWithBiometrics()
            await MainActor.run {
                isAuthenticated = success
            }
            return success
        } catch {
            await MainActor.run {
                lastError = AuthenticationError.from(error)
                isAuthenticated = false
            }
            return false
        }
    }
    
    /// Signs out the current user.
    func signOut() {
        Task { @MainActor in
            isAuthenticated = false
            lastError = nil
        }
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
    
    /// Performs the actual biometric authentication.
    private func authenticateWithBiometrics() async throws -> Bool {
        return try await withCheckedThrowingContinuation { continuation in
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
    case userCancel
    case systemCancel
    case authenticationFailed
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
        case .userCancel:
            return "Authentication was cancelled by the user."
        case .systemCancel:
            return "Authentication was cancelled by the system."
        case .authenticationFailed:
            return "Authentication failed. Please try again."
        case .unknown:
            return "An unknown authentication error occurred."
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .biometricNotAvailable:
            return "Please use a device that supports biometric authentication."
        case .biometricNotEnrolled:
            return "Go to Settings > Face ID & Passcode (or Touch ID & Passcode) to set up biometric authentication."
        case .biometricLockout:
            return "Enter your device passcode to unlock biometric authentication."
        case .userCancel:
            return "Tap the authentication button to try again."
        case .systemCancel:
            return "Authentication was interrupted. Please try again."
        case .authenticationFailed:
            return "Make sure you're using the correct biometric authentication method."
        case .unknown:
            return "Please try again or restart the app."
        }
    }
}
