//
//  ContentView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 07.10.25.
//

import SwiftUI

/// The main view of the QR Code Scanner app.
/// 
/// This view provides a complete QR code scanning experience with proper error handling,
/// accessibility support, and follows Apple's Human Interface Guidelines.
@available(iOS 14.0, *)
struct ContentView: View {
    
    // MARK: - State Properties
    
    @StateObject private var authManager = AuthenticationManager()
    @State private var scannedCode = ""
    @State private var isScanning = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    
    // MARK: - Body
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient following Apple's design guidelines
                backgroundGradient
                
                // Main content
                VStack(spacing: 24) {
                    if isScanning {
                        scanningView
                    } else {
                        resultView
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .navigationTitle("QR Code Scanner")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Sign Out") {
                        signOut()
                    }
                    .foregroundColor(.red)
                    .accessibilityLabel("Sign out of the app")
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !isScanning {
                        Button("New Scan") {
                            startNewScan()
                        }
                        .accessibilityLabel("Start new QR code scan")
                    }
                }
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .alert("QR Code Detected", isPresented: $showAlert) {
            Button("OK", role: .cancel) {
                // Alert dismissed, no action needed
            }
        } message: {
            Text(alertMessage)
        }
        .alert("Scanning Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {
                // Error alert dismissed
            }
            Button("Retry") {
                retryScanning()
            }
        } message: {
            Text(errorMessage)
        }
        .onChange(of: scannedCode) { _, newValue in
            handleScannedCode(newValue)
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
    
    /// The scanning interface view.
    private var scanningView: some View {
        VStack(spacing: 20) {
            // Instructions
            VStack(spacing: 8) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)
                
                Text("Point your camera at a QR code")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Position the QR code within the frame to scan it")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Scanner view with overlay
            ZStack {
                QRCodeScannerView(
                    scannedCode: $scannedCode,
                    isScanning: $isScanning,
                    onError: handleScannerError
                )
                .frame(height: 300)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
                .accessibilityLabel("QR code scanner camera view")
                
                // Scanning overlay with corner indicators
                scanningOverlay
            }
            .padding(.horizontal)
            
            // Processing indicator
            if isProcessing {
                HStack(spacing: 8) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("Processing...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Processing QR code")
            }
        }
    }
    
    /// The scanning overlay with corner indicators.
    private var scanningOverlay: some View {
        VStack {
            HStack {
                cornerIndicator
                Spacer()
                cornerIndicator
            }
            Spacer()
            HStack {
                cornerIndicator
                Spacer()
                cornerIndicator
            }
        }
        .padding(24)
        .accessibilityHidden(true)
    }
    
    /// A corner indicator for the scanning frame.
    private var cornerIndicator: some View {
        Rectangle()
            .frame(width: 24, height: 24)
            .foregroundColor(.clear)
            .overlay(
                Rectangle()
                    .stroke(Color.accentColor, lineWidth: 3)
                    .frame(width: 24, height: 24)
            )
    }
    
    /// The result view after successful scanning.
    private var resultView: some View {
        VStack(spacing: 24) {
            // Success indicator
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                    .accessibilityLabel("QR code successfully scanned")
                
                Text("QR Code Scanned!")
                    .font(.title)
                    .fontWeight(.bold)
                    .accessibilityAddTraits(.isHeader)
            }
            
            // Scanned content display
            VStack(alignment: .leading, spacing: 12) {
                Text("Scanned Content")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                
                ScrollView {
                    Text(scannedCode)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .accessibilityLabel("Scanned QR code content: \(scannedCode)")
                }
                .frame(maxHeight: 120)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
            
            // Action buttons
            VStack(spacing: 12) {
                Button("Scan Another QR Code") {
                    startNewScan()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Start scanning another QR code")
                
                Button("Copy to Clipboard") {
                    copyToClipboard()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityLabel("Copy scanned content to clipboard")
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Handles a newly scanned QR code.
    private func handleScannedCode(_ code: String) {
        guard !code.isEmpty else { return }
        
        isProcessing = true
        
        // Simulate processing time for better UX
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isProcessing = false
            alertMessage = "Successfully scanned: \(code)"
            showAlert = true
        }
    }
    
    /// Handles scanner errors.
    private func handleScannerError(_ error: QRScannerError) {
        errorMessage = error.localizedDescription
        showErrorAlert = true
    }
    
    /// Starts a new scan session.
    private func startNewScan() {
        isScanning = true
        scannedCode = ""
        isProcessing = false
    }
    
    /// Retries scanning after an error.
    private func retryScanning() {
        isScanning = true
        isProcessing = false
    }
    
    /// Copies the scanned content to the clipboard.
    private func copyToClipboard() {
        UIPasteboard.general.string = scannedCode
    }
    
    /// Signs out the current user.
    private func signOut() {
        authManager.signOut()
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDisplayName("QR Code Scanner")
    }
}
