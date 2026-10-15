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
/// Tabs, all showing the event selected from the calendar menu:
/// - Overview: live numbers and walk-in registration
/// - Welcome Desk: check in a whole registration on arrival
/// - Food Desk: mark each food ticket as served
/// - Settings: app settings and sign out
///
/// QR scanning is hidden for now (QRCodeScannerView is kept for later).
struct ContentView: View {

    // MARK: - State Properties

    @StateObject private var authManager = AuthenticationManager()
    @State private var store = DeskStore()
    @State private var selectedTab = 0

    // MARK: - Body

    var body: some View {
        TabView(selection: $selectedTab) {
            OverviewTabView()
                .tabItem {
                    Label("Overview", systemImage: "chart.bar.fill")
                }
                .tag(0)

            WelcomeDeskView()
                .tabItem {
                    Label("Welcome", systemImage: "person.crop.circle.badge.checkmark")
                }
                .tag(1)

            FoodDeskView()
                .tabItem {
                    Label("Food", systemImage: "fork.knife")
                }
                .tag(2)

            SettingsTabView(authManager: authManager)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(3)
        }
        .environment(store)
        .deskErrorAlert(store)
        .task { await store.loadEvents() }
        // Reload whenever the selected event changes (and once it's first known).
        .task(id: store.selectedEventID) { await store.refreshVisitors() }
    }
}

// MARK: - Preview

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDisplayName("RNBA Admin")
    }
}
