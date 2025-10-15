//
//  MainAppView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 07.10.25.
//

import SwiftUI

/// The main app view that manages the authentication flow and content display.
/// 
/// This view serves as the root coordinator for the app, determining whether to show
/// the authentication screen or the main app content based on the user's authentication status.
@available(iOS 14.0, *)
struct MainAppView: View {
    
    // MARK: - Properties
    
    @StateObject private var authManager = AuthenticationManager()
    @State private var isAppReady = false
    
    // MARK: - Body
    
    var body: some View {
        Group {
            if isAppReady {
                if authManager.isAuthenticated {
                    // Main app content
                    ContentView()
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .leading)
                        ))
                } else {
                    // Login screen
                    LoginView(authManager: authManager)
                        .transition(.asymmetric(
                            insertion: .move(edge: .leading),
                            removal: .move(edge: .trailing)
                        ))
                }
            } else {
                // Loading screen
                loadingView
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .onAppear {
            setupApp()
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            // Re-authenticate when app comes to foreground
            reauthenticateIfNeeded()
        }
    }
    
    // MARK: - View Components
    
    /// The loading screen shown while the app initializes.
    private var loadingView: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            // Loading content
            VStack(spacing: 24) {
                // App icon
                Image(systemName: "person.crop.circle.badge.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)
                
                // App title
                Text("RNBA Admin")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                    .accessibilityAddTraits(.isHeader)
                
                // Loading indicator
                ProgressView()
                    .scaleEffect(1.2)
                    .accessibilityLabel("Loading app")
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Sets up the app and determines initial authentication state.
    private func setupApp() {
        // Simulate app initialization
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isAppReady = true
        }
    }
    
    /// Re-authenticates the user if needed when the app comes to foreground.
    private func reauthenticateIfNeeded() {
        // For security, we might want to re-authenticate after a certain time
        // For now, we'll keep the current authentication state
        // In a production app, you might want to implement session timeout logic here
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct MainAppView_Previews: PreviewProvider {
    static var previews: some View {
        MainAppView()
            .previewDisplayName("Main App View")
    }
}
