//
//  SearchableListTabView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import SwiftUI

@available(iOS 14.0, *)
struct SearchableListTabView: View {
    @State private var searchText = ""
    @State private var visitorDetails: [VisitorDetail] = []
    @State private var isLoading = false
    @State private var loadError: Error?
    
    private let visitorService = VisitorService()
    
    private var filteredVisitorDetails: [VisitorDetail] {
        if searchText.isEmpty {
            return visitorDetails
        } else {
            return visitorDetails.filter { visitorDetail in
                let registrationName = visitorDetail.registration?.name ?? ""
                let visitTypeName = visitorDetail.visitType?.name ?? ""
                let foodTypeName = visitorDetail.foodType?.name ?? ""
                
                return registrationName.localizedCaseInsensitiveContains(searchText) ||
                       visitTypeName.localizedCaseInsensitiveContains(searchText) ||
                       foodTypeName.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // Error State
                if let error = loadError {
                    ErrorStateView(
                        error: error,
                        onRetry: {
                            loadVisitors()
                        }
                    )
                    .padding()
                }
                
                // List
                if isLoading {
                    ProgressView("Loading visitors...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredVisitorDetails.isEmpty {
                    EmptyStateView(
                        icon: "person.2.slash",
                        title: searchText.isEmpty ? "No Visitors Yet" : "No Results Found",
                        message: searchText.isEmpty ? 
                            "Visitors will appear here once registrations are created." :
                            "Try adjusting your search terms.",
                        actionTitle: searchText.isEmpty ? nil : "Clear Search",
                        action: searchText.isEmpty ? nil : { searchText = "" }
                    )
                } else {
                    List(filteredVisitorDetails, id: \.id) { visitorDetail in
                        HStack(spacing: 12) {
                            // Completion toggle checkbox
                            Button(action: {
                                toggleVisitorCompletion(visitorDetail)
                            }) {
                                Image(systemName: visitorDetail.visitor.completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(visitorDetail.visitor.completed ? .green : .gray)
                                    .font(.title2)
                            }
                            .buttonStyle(PlainButtonStyle())
                            .accessibilityLabel(visitorDetail.visitor.completed ? "Mark as incomplete" : "Mark as complete")
                            
                            // Visitor info
                            VStack(alignment: .leading, spacing: 4) {
                                Text(visitorDetail.registration?.name ?? "Unknown")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 8) {
                                    Label(visitorDetail.visitType?.name ?? "N/A", systemImage: "person.fill")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    
                                    if let foodType = visitorDetail.foodType {
                                        Label(foodType.name, systemImage: "fork.knife")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            // Status badge
                            Text(visitorDetail.visitor.completed ? "Completed" : "Pending")
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(visitorDetail.visitor.completed ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                                .foregroundColor(visitorDetail.visitor.completed ? .green : .orange)
                                .cornerRadius(8)
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(PlainListStyle())
                }
            }
            .navigationTitle("Visitors")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                loadVisitors()
            }
        }
        .refreshable {
            await loadVisitors()
        }
    }
    
    
    private func loadVisitors() {
        Task {
            isLoading = true
            loadError = nil
            
            do {
                visitorDetails = try await visitorService.fetchVisitorDetails()
                loadError = nil
            } catch {
                print("Error loading visitors: \(error)")
                loadError = error
            }
            
            isLoading = false
        }
    }
    
    private func toggleVisitorCompletion(_ visitorDetail: VisitorDetail) {
        Task {
            do {
                let newCompletedStatus = !visitorDetail.visitor.completed
                try await visitorService.updateVisitorCompletedStatus(
                    visitorID: visitorDetail.visitor.visitorID,
                    completed: newCompletedStatus
                )
                
                // Update local state
                if let index = visitorDetails.firstIndex(where: { $0.visitor.visitorID == visitorDetail.visitor.visitorID }) {
                    let current = visitorDetails[index]
                    // Recreate a new Visitor with updated completed flag
                    let updatedVisitor = Visitor(
                        visitorID: current.visitor.visitorID,
                        createdAt: current.visitor.createdAt,
                        registrationID: current.visitor.registrationID,
                        visitID: current.visitor.visitID,
                        foodTypeID: current.visitor.foodTypeID,
                        completed: newCompletedStatus
                    )

                    visitorDetails[index] = VisitorDetail(
                        visitor: updatedVisitor,
                        visitType: current.visitType,
                        foodType: current.foodType,
                        registration: current.registration
                    )
                } else {
                    // Fallback: map and replace if index not found for any reason
                    visitorDetails = visitorDetails.map { item in
                        if item.visitor.visitorID == visitorDetail.visitor.visitorID {
                            let current = item
                            let updatedVisitor = Visitor(
                                visitorID: current.visitor.visitorID,
                                createdAt: current.visitor.createdAt,
                                registrationID: current.visitor.registrationID,
                                visitID: current.visitor.visitID,
                                foodTypeID: current.visitor.foodTypeID,
                                completed: newCompletedStatus
                            )
                            return VisitorDetail(
                                visitor: updatedVisitor,
                                visitType: current.visitType,
                                foodType: current.foodType,
                                registration: current.registration
                            )
                        } else {
                            return item
                        }
                    }
                }
            } catch {
                print("Error updating visitor status: \(error)")
            }
        }
    }
}

