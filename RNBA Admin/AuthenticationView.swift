//
//  AuthenticationView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 07.10.25.
//

import SwiftUI
import LocalAuthentication

/// The main authentication view that serves as the welcome page.
/// 
/// This view provides a secure sign-in experience using Face ID, Touch ID, or passcode.
/// It follows Apple's Human Interface Guidelines for authentication interfaces.
@available(iOS 14.0, *)
struct AuthenticationView: View {
    
    // MARK: - Properties
    
    @StateObject private var authManager = AuthenticationManager()
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var showSettingsAlert = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                backgroundGradient
                
                VStack(spacing: 32) {
                    // App branding
                    appBranding
                    
                    // Authentication interface
                    authenticationInterface
                    
                    // Additional options
                    additionalOptions
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 32)
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Authentication Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                // Error alert dismissed
            }
            if authManager.getBiometricType() != nil {
                Button("Try Again") {
                    Task {
                        await authenticate()
                    }
                }
            }
        } message: {
            Text(errorMessage)
        }
        .alert("Setup Required", isPresented: $showSettingsAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Open Settings") {
                openSettings()
            }
        } message: {
            Text("Please set up Face ID or Touch ID in Settings to use biometric authentication.")
        }
    }
    
    // MARK: - View Components
    
    /// The background gradient following Apple's design system.
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemBackground),
                Color(.systemGray6)
            ]),
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
    
    /// The app branding section.
    private var appBranding: some View {
        VStack(spacing: 16) {
            // App icon
            Image(systemName: "qrcode.viewfinder")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)
                .accessibilityHidden(true)
            
            // App title
            Text("RNBA Admin")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .accessibilityAddTraits(.isHeader)
            
            // App description
            Text("Secure QR Code Scanner")
                .font(.title3)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }
    
    /// The main authentication interface.
    private var authenticationInterface: some View {
        VStack(spacing: 24) {
            // Welcome message
            VStack(spacing: 8) {
                Text("Welcome Back")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Sign in to access the QR code scanner")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Authentication button
            authenticationButton
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    /// The authentication button with biometric support.
    private var authenticationButton: some View {
        VStack(spacing: 16) {
            // Biometric authentication button
            if authManager.isBiometricAuthenticationAvailable() {
                Button(action: {
                    Task {
                        await authenticate()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: biometricIconName)
                            .font(.title2)
                        
                        Text(biometricButtonText)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor)
                    )
                }
                .disabled(authManager.isAuthenticating)
                .accessibilityLabel("Sign in with \(biometricTypeName)")
            } else {
                // Fallback for devices without biometric authentication
                Button(action: {
                    Task {
                        await authenticate()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: "key.fill")
                            .font(.title2)
                        
                        Text("Sign In with Passcode")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentColor)
                    )
                }
                .disabled(authManager.isAuthenticating)
                .accessibilityLabel("Sign in with device passcode")
            }
            
            // Processing indicator
            if authManager.isAuthenticating {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Authenticating...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Authentication in progress")
            }
        }
    }
    
    /// Additional options and information.
    private var additionalOptions: some View {
        VStack(spacing: 16) {
            // Security information
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Your data is protected with end-to-end encryption")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .accessibilityLabel("Security: Your data is protected with end-to-end encryption")
            
            // Setup biometric authentication if not available
            if !authManager.isBiometricAuthenticationAvailable() {
                Button("Set up Face ID or Touch ID") {
                    showSettingsAlert = true
                }
                .font(.caption)
                .foregroundColor(.accentColor)
                .accessibilityLabel("Set up biometric authentication")
            }
        }
    }
    
    // MARK: - Computed Properties
    
    /// The icon name for the biometric authentication button.
    private var biometricIconName: String {
        switch authManager.getBiometricType() {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "key.fill"
        }
    }
    
    /// The button text for biometric authentication.
    private var biometricButtonText: String {
        switch authManager.getBiometricType() {
        case .faceID:
            return "Sign in with Face ID"
        case .touchID:
            return "Sign in with Touch ID"
        default:
            return "Sign in with Passcode"
        }
    }
    
    /// The human-readable name of the biometric type.
    private var biometricTypeName: String {
        switch authManager.getBiometricType() {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Passcode"
        }
    }
    
    // MARK: - Private Methods
    
    /// Attempts to authenticate the user.
    private func authenticate() async {
        let success = await authManager.authenticate()
        
        if !success, let error = authManager.lastError {
            errorMessage = error.localizedDescription
            showErrorAlert = true
        }
    }
    
    /// Opens the device settings.
    private func openSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct AuthenticationView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticationView()
            .previewDisplayName("Authentication View")
    }
}
