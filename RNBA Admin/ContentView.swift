//
//  ContentView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 07.10.25.
//  Refactored on 14.10.25 for better modularity
//

import SwiftUI

/// The main view of the RNBA Admin app.
/// 
/// This view provides a tab-based interface with four main sections:
/// - Overview: Dashboard with statistics
/// - Scanner: QR code scanning functionality
/// - List: Searchable visitor list
/// - Settings: App settings and sign out
@available(iOS 14.0, *)
struct ContentView: View {
    
    // MARK: - State Properties
    
    @StateObject private var authManager = AuthenticationManager()
    @State private var selectedTab = 0
    
    // MARK: - Body
    
    var body: some View {
        TabView(selection: $selectedTab) {
            // Overview Tab
            OverviewTabView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Overview")
                }
                .tag(0)
            
            // QR Scanner Tab
            QRScannerTabView()
                .tabItem {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scanner")
                }
                .tag(1)
            
            // Registration List Tab
            RegistrationListTabView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("List")
                }
                .tag(2)
            
            // Settings Tab
            SettingsTabView(authManager: authManager)
                .tabItem {
                    Image(systemName: "gear")
                    Text("Settings")
                }
                .tag(3)
        }
    }
}

// MARK: - QR Scanner Tab View (Placeholder)

@available(iOS 14.0, *)
struct QRScannerTabView: View {
    @State private var scannedCode = ""
    @State private var isScanning = true
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Spacer()
                
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 80))
                    .foregroundColor(.blue)
                
                Text("QR Scanner")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("QR scanning functionality")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                if !scannedCode.isEmpty {
                    Text("Last scanned: \(scannedCode)")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding()
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .navigationTitle("Scanner")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        // Enable preview mode for mock data
        SupabaseConfig.forcePreviewMode = true
        
        return ContentView()
            .previewDisplayName("RNBA Admin")
    }
}
