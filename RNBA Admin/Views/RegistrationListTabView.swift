//
//  RegistrationListTabView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 15.10.25.
//

import SwiftUI

@available(iOS 14.0, *)
struct RegistrationListTabView: View {
    @State private var searchText = ""
    @State private var registrations: [RegistrationSummary] = []
    @State private var isLoading = false
    @State private var loadError: Error?
    @State private var selectedRegistration: RegistrationSummary?
    @State private var showVisitorPopup = false
    
    private let registrationService = RegistrationService()
    private let eventID: Int32 = 2024 // Default event ID
    
    private var filteredRegistrations: [RegistrationSummary] {
        if searchText.isEmpty {
            return registrations
        } else {
            return registrations.filter { registration in
                registration.name.localizedCaseInsensitiveContains(searchText) ||
                String(registration.registrationID).contains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                    .padding(.top, 8)
                
                // Error State
                if let error = loadError {
                    ErrorStateView(
                        error: error,
                        onRetry: {
                            loadRegistrations()
                        }
                    )
                    .padding()
                }
                
                // List
                if isLoading {
                    ProgressView("Loading registrations...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredRegistrations.isEmpty {
                    EmptyStateView(
                        icon: "person.text.rectangle",
                        title: searchText.isEmpty ? "No Registrations Yet" : "No Results Found",
                        message: searchText.isEmpty ?
                            "Registrations will appear here once created." :
                            "Try adjusting your search terms.",
                        actionTitle: searchText.isEmpty ? nil : "Clear Search",
                        action: searchText.isEmpty ? nil : { searchText = "" }
                    )
                } else {
                    List(filteredRegistrations) { registration in
                        Button(action: {
                            selectedRegistration = registration
                            showVisitorPopup = true
                        }) {
                            HStack(spacing: 16) {
                                // Registration ID badge
                                Text("#\(registration.registrationID)")
                                    .font(.system(.body, design: .monospaced))
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(Color.blue)
                                    .cornerRadius(8)
                                
                                // Registration info
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(registration.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(formatDate(registration.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                // Chevron indicator
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Registrations")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadRegistrations()
            }
            .sheet(isPresented: $showVisitorPopup) {
                if let registration = selectedRegistration {
                    VisitorPopupView(
                        registration: registration,
                        registrationService: registrationService
                    )
                }
            }
        }
        .refreshable {
            await loadRegistrations()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadRegistrations() {
        Task {
            isLoading = true
            loadError = nil
            
            do {
                registrations = try await registrationService.fetchRegistrationsForEvent(eventID: eventID)
                loadError = nil
            } catch {
                print("Error loading registrations: \(error)")
                loadError = error
            }
            
            isLoading = false
        }
    }
    
    private func formatDate(_ isoString: String) -> String {
        let formatter = ISO8601DateFormatter()
        guard let date = formatter.date(from: isoString) else {
            return isoString
        }
        
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}

// MARK: - Visitor Popup View

@available(iOS 14.0, *)
struct VisitorPopupView: View {
    @Environment(\.dismiss) private var dismiss
    let registration: RegistrationSummary
    let registrationService: RegistrationService
    
    @State private var visitors: [VisitorData] = []
    @State private var isLoading = false
    @State private var loadError: Error?
    
    private let visitorDataService = VisitorDataService()
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with registration info
                VStack(spacing: 8) {
                    HStack {
                        Text("Registration #\(registration.registrationID)")
                            .font(.system(.title3, design: .monospaced))
                            .fontWeight(.bold)
                        
                        Spacer()
                    }
                    
                    HStack {
                        Text(registration.name)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                    }
                }
                .padding()
                .background(Color(.systemGroupedBackground))
                
                Divider()
                
                // Error State
                if let error = loadError {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        
                        Text("Error loading visitors")
                            .font(.headline)
                        
                        Text(error.localizedDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Retry") {
                            loadVisitors()
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                // Loading State
                else if isLoading {
                    ProgressView("Loading visitors...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                // Empty State
                else if visitors.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "fork.knife.circle")
                            .font(.system(size: 60))
                            .foregroundColor(.secondary)
                        
                        Text("No Visitors with Food")
                            .font(.title3)
                            .fontWeight(.semibold)
                        
                        Text("This registration has no visitors with food preferences.")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                // Visitor Table
                else {
                    VStack(spacing: 0) {
                        // Table Header
                        HStack(spacing: 0) {
                            Text("Visitor ID")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(width: 100, alignment: .leading)
                            
                            Text("Visit Type")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Food Preference")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("Completed")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.secondary)
                                .frame(width: 100, alignment: .center)
                        }
                        .padding()
                        .background(Color(.systemGray6))
                        
                        Divider()
                        
                        // Table Rows
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(visitors) { visitor in
                                    VisitorRow(
                                        visitor: visitor,
                                        onToggle: { newStatus in
                                            toggleVisitorCompletion(visitor, newStatus: newStatus)
                                        }
                                    )
                                    
                                    Divider()
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Visitors with Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                loadVisitors()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadVisitors() {
        Task {
            isLoading = true
            loadError = nil
            
            do {
                visitors = try await visitorDataService.fetchVisitorData(registrationID: registration.registrationID)
                loadError = nil
            } catch {
                print("Error loading visitors: \(error)")
                loadError = error
            }
            
            isLoading = false
        }
    }
    
    private func toggleVisitorCompletion(_ visitor: VisitorData, newStatus: Bool) {
        Task {
            do {
                try await visitorDataService.updateVisitorCompletion(
                    visitorID: visitor.visitorid,
                    completed: newStatus
                )
                
                // Update local state
                if let index = visitors.firstIndex(where: { $0.visitorid == visitor.visitorid }) {
                    visitors[index] = VisitorData(
                        visitorid: visitor.visitorid,
                        food_preference: visitor.food_preference,
                        visit_type: visitor.visit_type,
                        completed: newStatus
                    )
                }
            } catch {
                print("Error updating visitor status: \(error)")
                // Optionally show an alert to the user
            }
        }
    }
}

// MARK: - Visitor Row Component

@available(iOS 14.0, *)
struct VisitorRow: View {
    let visitor: VisitorData
    let onToggle: (Bool) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Visitor ID
            Text("#\(visitor.visitorid)")
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
                .frame(width: 100, alignment: .leading)
            
            // Visit Type
            HStack(spacing: 6) {
                Image(systemName: "person.fill")
                    .font(.caption)
                    .foregroundColor(.blue)
                
                Text(visitor.visit_type ?? "Unknown")
                    .font(.body)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Food Preference
            HStack(spacing: 6) {
                if let foodPref = visitor.food_preference {
                    Image(systemName: foodPref.contains("Veg") && !foodPref.contains("Non") ? "leaf.fill" : "fork.knife")
                        .font(.caption)
                        .foregroundColor(foodPref.contains("Veg") && !foodPref.contains("Non") ? .green : .red)
                    
                    Text(foodPref)
                        .font(.body)
                } else {
                    Text("None")
                        .font(.body)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Completed Checkbox
            Button(action: {
                onToggle(!visitor.completed)
            }) {
                Image(systemName: visitor.completed ? "checkmark.square.fill" : "square")
                    .font(.title3)
                    .foregroundColor(visitor.completed ? .green : .gray)
            }
            .frame(width: 100, alignment: .center)
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(visitor.completed ? Color.green.opacity(0.05) : Color.clear)
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct RegistrationListTabView_Previews: PreviewProvider {
    static var previews: some View {
        // Enable preview mode for mock data
        SupabaseConfig.forcePreviewMode = true
        
        return RegistrationListTabView()
            .previewDisplayName("Registration List")
    }
}
