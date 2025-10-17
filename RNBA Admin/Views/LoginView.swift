//
//  LoginView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 15.10.25.
//

import SwiftUI
import LocalAuthentication

/// Login view with email/password authentication and optional biometric support
@available(iOS 14.0, *)
struct LoginView: View {
    
    // MARK: - Properties
    
    @ObservedObject var authManager: AuthenticationManager
    
    @State private var email = ""
    @State private var password = ""
    @State private var rememberMe = false
    @State private var showPassword = false
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showBiometricSetup = false
    
    private let keychain = KeychainManager.shared
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                backgroundGradient
                
                ScrollView {
                    VStack(spacing: 32) {
                        Spacer()
                            .frame(height: 40)
                        
                        // App branding
                        appBranding
                        
                        // Login form
                        loginForm
                        
                        Spacer()
                    }
                    .padding(.horizontal, 24)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("Authentication Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showBiometricSetup) {
            BiometricSetupView(authManager: authManager)
        }
        .onAppear {
            // Pre-fill email if stored
            if let storedEmail = keychain.getEmail() {
                email = storedEmail
            }
            
            // Auto-trigger biometric authentication if enabled
            if keychain.isBiometricEnabled() && authManager.isBiometricAuthenticationAvailable() {
                Task {
                    await authenticateWithBiometrics()
                }
            }
        }
    }
    
    // MARK: - View Components
    
    /// Background gradient
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
    
    /// App branding section
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
            
            // App description
            Text("Admin Dashboard Login")
                .font(.title3)
                .foregroundColor(.secondary)
        }
    }
    
    /// Login form
    private var loginForm: some View {
        VStack(spacing: 24) {
            // Email field
            VStack(alignment: .leading, spacing: 8) {
                Text("Email")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "envelope")
                        .foregroundColor(.secondary)
                    
                    TextField("Enter your email", text: $email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .disabled(authManager.isAuthenticating)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            
            // Password field
            VStack(alignment: .leading, spacing: 8) {
                Text("Password")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                
                HStack {
                    Image(systemName: "lock")
                        .foregroundColor(.secondary)
                    
                    if showPassword {
                        TextField("Enter your password", text: $password)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .disabled(authManager.isAuthenticating)
                    } else {
                        SecureField("Enter your password", text: $password)
                            .textContentType(.password)
                            .autocapitalization(.none)
                            .disabled(authManager.isAuthenticating)
                    }
                    
                    Button(action: {
                        showPassword.toggle()
                    }) {
                        Image(systemName: showPassword ? "eye.slash" : "eye")
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(.systemGray4), lineWidth: 1)
                )
            }
            
            // Remember me checkbox
            Toggle("Remember me on this device", isOn: $rememberMe)
                .font(.subheadline)
                .disabled(authManager.isAuthenticating)
            
            // Sign in button
            Button(action: {
                Task {
                    await signIn()
                }
            }) {
                HStack(spacing: 8) {
                    if authManager.isAuthenticating {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        Text("Signing in...")
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Sign In")
                    }
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isFormValid ? Color.accentColor : Color.gray)
                )
            }
            .disabled(!isFormValid || authManager.isAuthenticating)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !email.isEmpty && email.contains("@") && password.count >= 6
    }
    
    private var biometricIconName: String {
        switch authManager.getBiometricType() {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.fill"
        }
    }
    
    private var biometricButtonText: String {
        switch authManager.getBiometricType() {
        case .faceID:
            return "Sign in with Face ID"
        case .touchID:
            return "Sign in with Touch ID"
        default:
            return "Sign in with Biometric"
        }
    }
    
    // MARK: - Private Methods
    
    private func signIn() async {
        let success = await authManager.signInWithEmail(email, password: password, rememberMe: rememberMe)
        
        if success {
            // Check if biometric is available and not yet enabled
            if authManager.isBiometricAuthenticationAvailable() && 
               !keychain.isBiometricEnabled() &&
               rememberMe {
                await MainActor.run {
                    showBiometricSetup = true
                }
            }
        } else if let error = authManager.lastError {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
    
    private func authenticateWithBiometrics() async {
        let success = await authManager.authenticateWithBiometrics()
        
        if !success, let error = authManager.lastError {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Biometric Setup View

@available(iOS 14.0, *)
struct BiometricSetupView: View {
    @Environment(\.dismiss) private var dismiss
    let authManager: AuthenticationManager
    
    var body: some View {
        NavigationView {
            VStack(spacing: 32) {
                Spacer()
                
                // Icon
                Image(systemName: biometricIconName)
                    .font(.system(size: 80))
                    .foregroundColor(.accentColor)
                
                // Title
                Text("Enable \(biometricTypeName)?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                
                // Description
                Text("Sign in faster next time using \(biometricTypeName). Your credentials will be securely stored on this device.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 16) {
                    // Enable button
                    Button(action: {
                        authManager.enableBiometricAuth()
                        dismiss()
                    }) {
                        Text("Enable \(biometricTypeName)")
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.accentColor)
                            )
                    }
                    
                    // Skip button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Not Now")
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private var biometricIconName: String {
        switch authManager.getBiometricType() {
        case .faceID:
            return "faceid"
        case .touchID:
            return "touchid"
        default:
            return "lock.shield"
        }
    }
    
    private var biometricTypeName: String {
        switch authManager.getBiometricType() {
        case .faceID:
            return "Face ID"
        case .touchID:
            return "Touch ID"
        default:
            return "Biometric"
        }
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct LoginView_Previews: PreviewProvider {
    static var previews: some View {
        LoginView(authManager: AuthenticationManager())
            .previewDisplayName("Login View")
    }
}
