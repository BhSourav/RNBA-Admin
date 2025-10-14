//
//  SettingsTabView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import SwiftUI

@available(iOS 14.0, *)
struct SettingsTabView: View {
    @ObservedObject var authManager: AuthenticationManager
    @State private var showSignOutAlert = false
    
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
                
                // Authentication Section
                Section("Authentication") {
                    HStack {
                        Image(systemName: "faceid")
                            .foregroundColor(.blue)
                        Text("Biometric Auth")
                        Spacer()
                        Text(authManager.isBiometricAuthenticationAvailable() ? "Enabled" : "Disabled")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
                
                // Account Section
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
                } header: {
                    Text("Account")
                } footer: {
                    Text("You will need to authenticate again to access the app.")
                        .font(.caption)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
        }
        .alert("Sign Out", isPresented: $showSignOutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
    }
}
