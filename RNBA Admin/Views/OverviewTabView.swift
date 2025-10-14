//
//  OverviewTabView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import SwiftUI

@available(iOS 14.0, *)
struct OverviewTabView: View {
    @State private var showNewRegistration = false
    @State private var dashboardStats: DashboardStats?
    @State private var isLoading = false
    @State private var loadError: Error?
    
    private let dashboardService = DashboardService()
    
    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .none
        return formatter.string(from: Date())
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Today's Overview")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text(formattedDate)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                    
                    // Error State
                    if let error = loadError {
                        ErrorStateView(
                            error: error,
                            onRetry: {
                                loadDashboardData()
                            }
                        )
                        .padding(.horizontal)
                    }
                    
                    // Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        // 1. Total Registrations (tap to see left to visit)
                        InteractiveStatCard(
                            primaryTitle: "Registrations Today",
                            primaryValue: dashboardStats?.totalRegistrationsToday.description ?? "—",
                            secondaryTitle: "Left to Visit",
                            secondaryValue: dashboardStats?.registrationsLeftToVisit.description ?? "—",
                            icon: "person.text.rectangle.fill",
                            color: .blue
                        )
                        
                        // 2. Total Visitors (tap to see left to visit)
                        InteractiveStatCard(
                            primaryTitle: "Visitors Today",
                            primaryValue: dashboardStats?.totalVisitorsToday.description ?? "—",
                            secondaryTitle: "Left to Visit",
                            secondaryValue: dashboardStats?.visitorsLeftToVisit.description ?? "—",
                            icon: "person.3.fill",
                            color: .green
                        )
                        
                        // 3. Non-Veg Visitors (tap to see left to eat)
                        InteractiveStatCard(
                            primaryTitle: "Non-Veg Visitors",
                            primaryValue: dashboardStats?.nonVegVisitors.description ?? "—",
                            secondaryTitle: "Left to Eat",
                            secondaryValue: dashboardStats?.nonVegLeftToEat.description ?? "—",
                            icon: "fork.knife",
                            color: .red
                        )
                        
                        // 4. Veg Visitors (tap to see left to eat)
                        InteractiveStatCard(
                            primaryTitle: "Veg Visitors",
                            primaryValue: dashboardStats?.vegVisitors.description ?? "—",
                            secondaryTitle: "Left to Eat",
                            secondaryValue: dashboardStats?.vegLeftToEat.description ?? "—",
                            icon: "leaf.fill",
                            color: .green
                        )
                        
                        // 5. Spot Registration - Veg
                        StatCard(
                            title: "Spot Reg - Veg",
                            value: dashboardStats?.spotRegistrationVeg.description ?? "—",
                            icon: "person.badge.plus",
                            color: .mint
                        )
                        
                        // 6. Spot Registration - Non-Veg
                        StatCard(
                            title: "Spot Reg - Non-Veg",
                            value: dashboardStats?.spotRegistrationNonVeg.description ?? "—",
                            icon: "person.badge.plus",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Activity")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .padding(.horizontal)
                            .accessibilityAddTraits(.isHeader)
                        
                        VStack(spacing: 12) {
                            ActivityCard(
                                title: "New Registration",
                                description: "John Doe registered for the event",
                                time: "2 hours ago",
                                icon: "person.badge.plus",
                                color: .blue
                            )
                            
                            ActivityCard(
                                title: "QR Code Scanned",
                                description: "Jane Smith checked in",
                                time: "3 hours ago",
                                icon: "qrcode.viewfinder",
                                color: .green
                            )
                            
                            ActivityCard(
                                title: "Payment Received",
                                description: "Bob Johnson completed payment",
                                time: "5 hours ago",
                                icon: "creditcard.fill",
                                color: .purple
                            )
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showNewRegistration = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                            .accessibilityLabel("Add new registration")
                    }
                }
            }
            .sheet(isPresented: $showNewRegistration) {
                NewRegistrationView()
            }
            .onAppear {
                loadDashboardData()
            }
        }
        .refreshable {
            await loadDashboardData()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadDashboardData() {
        Task {
            isLoading = true
            loadError = nil
            
            do {
                dashboardStats = try await dashboardService.fetchDashboardStats()
                loadError = nil
            } catch {
                print("Error loading dashboard data: \(error)")
                loadError = error
            }
            
            isLoading = false
        }
    }
}
