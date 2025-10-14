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
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Text("Data Overview")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .accessibilityAddTraits(.isHeader)
                        
                        Text("RNBA Admin Dashboard")
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
                        StatCard(
                            title: "Total Registrations",
                            value: dashboardStats?.totalRegistrations.description ?? "Loading...",
                            icon: "person.text.rectangle.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Total Visitors",
                            value: dashboardStats?.totalVisitors.description ?? "Loading...",
                            icon: "person.3.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Completed",
                            value: dashboardStats?.completedVisitors.description ?? "Loading...",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "Pending",
                            value: dashboardStats?.pendingVisitors.description ?? "Loading...",
                            icon: "clock.fill",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "Total Payments",
                            value: dashboardStats?.totalPayments.description ?? "Loading...",
                            icon: "creditcard.fill",
                            color: .purple
                        )
                        
                        StatCard(
                            title: "System Status",
                            value: dashboardStats?.systemStatus ?? "Loading...",
                            icon: "server.rack",
                            color: .green
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
