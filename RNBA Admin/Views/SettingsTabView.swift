//
//  SettingsTabView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import SwiftUI
import LocalAuthentication

@available(iOS 14.0, *)
struct SettingsTabView: View {
    let authManager: AuthenticationManager
    @State private var showSignOutAlert = false
    @State private var biometricEnabled = false
    
    private let keychain = KeychainManager.shared
    
    var body: some View {
        NavigationView {
            List {
                // App Information Section
                Section("App Information") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Build")
                        Spacer()
                        Text("1")
                            .foregroundColor(.secondary)
                    }
                }
                
                // Database Section
                Section("Database") {
                    HStack {
                        Image(systemName: "server.rack")
                            .foregroundColor(.green)
                        Text("Supabase")
                        Spacer()
                        Text(SupabaseConfig.isConfigured ? "Connected" : "Not Configured")
                            .foregroundColor(SupabaseConfig.isConfigured ? .green : .orange)
                            .font(.caption)
                    }
                }
                
                // User Information Section
                if let email = authManager.currentUserEmail {
                    Section("Account") {
                        HStack {
                            Image(systemName: "person.circle")
                                .foregroundColor(.blue)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Signed in as")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Text(email)
                                    .font(.body)
                            }
                        }
                    }
                }
                
                // Security Section
                Section {
                    if authManager.isBiometricAuthenticationAvailable() {
                        Toggle(isOn: $biometricEnabled) {
                            HStack {
                                Image(systemName: biometricIconName)
                                    .foregroundColor(.blue)
                                Text("Enable \(biometricTypeName)")
                            }
                        }
                        .onChange(of: biometricEnabled) { newValue in
                            if newValue {
                                authManager.enableBiometricAuth()
                            } else {
                                authManager.disableBiometricAuth()
                            }
                        }
                    } else {
                        HStack {
                            Image(systemName: "faceid")
                                .foregroundColor(.gray)
                            Text("Biometric Auth")
                            Spacer()
                            Text("Not Available")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                } header: {
                    Text("Security")
                } footer: {
                    if authManager.isBiometricAuthenticationAvailable() {
                        Text("Use \(biometricTypeName) to quickly sign in to the app. Your credentials are securely stored on this device.")
                            .font(.caption)
                    }
                }
                
                // Sign Out Section
                Section {
                    Button(action: {
                        showSignOutAlert = true
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundColor(.red)
                            Text("Sign Out")
                                .foregroundColor(.red)
                        }
                    }
                } footer: {
                    Text("You will need to authenticate again to access the app.")
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                biometricEnabled = keychain.isBiometricEnabled()
            }
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                Task {
                    await authManager.signOut()
                }
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
    
    // MARK: - Computed Properties
    
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
