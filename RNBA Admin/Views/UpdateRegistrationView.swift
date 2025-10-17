//
//  UpdateRegistrationView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 17.10.25.
//

import SwiftUI
import Supabase

@available(iOS 14.0, *)
struct UpdateRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var showScanner = true
    @State private var scannedCode = ""
    @State private var isScanning = true
    
    @State private var registrationID: Int64?
    @State private var registration: Registration?
    @State private var visitors: [Visitor] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    @State private var showAddVisitor = false
    @State private var visitToDelete: Visitor?
    @State private var showDeleteConfirmation = false
    
    private let registrationService = RegistrationService()
    
    var body: some View {
        NavigationView {
            Group {
                if showScanner {
                    scannerView
                } else if isLoading {
                    loadingView
                } else if let registration = registration {
                    registrationDetailView(registration: registration)
                } else {
                    errorView
                }
            }
            .navigationTitle("Update Registration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                if !showScanner && registration != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showAddVisitor = true
                        }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
            .alert("Delete Visitor", isPresented: $showDeleteConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Delete", role: .destructive) {
                    if let visitor = visitToDelete {
                        deleteVisitor(visitor)
                    }
                }
            } message: {
                Text("Are you sure you want to delete this visitor?")
            }
            .sheet(isPresented: $showAddVisitor) {
                AddVisitorView(registrationID: registrationID ?? 0) {
                    // Reload visitors after adding
                    if let regID = registrationID {
                        loadRegistrationDetails(registrationID: regID)
                    }
                }
            }
        }
    }
    
    // MARK: - Scanner View
    
    private var scannerView: some View {
        VStack(spacing: 20) {
            Text("Scan Registration QR Code")
                .font(.title2)
                .fontWeight(.semibold)
            
            ZStack {
                QRCodeScannerView(
                    scannedCode: $scannedCode,
                    isScanning: $isScanning
                )
                .frame(height: 300)
                .cornerRadius(12)
                
                // Scanner overlay
                VStack {
                    Spacer()
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green, lineWidth: 3)
                        .frame(width: 250, height: 250)
                    Spacer()
                }
            }
            
            Text("Position the QR code within the frame")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Manual entry option
            Button(action: {
                // For testing/demo purposes
                enterManualRegistrationID()
            }) {
                HStack {
                    Image(systemName: "keyboard")
                    Text("Enter Registration ID Manually")
                }
                .font(.subheadline)
                .foregroundColor(.blue)
            }
            .padding()
        }
        .padding()
        .onChange(of: scannedCode) { newValue in
            if !newValue.isEmpty {
                processScannedCode(newValue)
            }
        }
    }
    
    // MARK: - Loading View
    
    private var loadingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            Text("Loading registration details...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Error View
    
    private var errorView: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Registration Not Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text(errorMessage ?? "Could not find registration with the scanned ID")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: {
                showScanner = true
                scannedCode = ""
                isScanning = true
            }) {
                Text("Scan Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.horizontal)
        }
    }
    
    // MARK: - Registration Detail View
    
    private func registrationDetailView(registration: Registration) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Registration Info Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Registration Details")
                        .font(.headline)
                    
                    HStack {
                        Text("ID:")
                            .foregroundColor(.secondary)
                        Text("\(registration.registrationID)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Name:")
                            .foregroundColor(.secondary)
                        Text(registration.name)
                            .fontWeight(.semibold)
                    }
                    
                    if !registration.createdAt.isEmpty {
                        HStack {
                            Text("Created:")
                                .foregroundColor(.secondary)
                            Text(formatDate(registration.createdAt))
                                .fontWeight(.medium)
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Visitors Section
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Visitors")
                            .font(.headline)
                        Spacer()
                        Text("\(visitors.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    if visitors.isEmpty {
                        Text("No visitors yet")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding()
                    } else {
                        ForEach(visitors, id: \.visitorID) { visitor in
                            EditableVisitorRow(visitor: visitor) {
                                visitToDelete = visitor
                                showDeleteConfirmation = true
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            .padding()
        }
    }
    
    // MARK: - Helper Functions
    
    private func processScannedCode(_ code: String) {
        // Try to extract registration ID from scanned code
        // Assuming the QR code contains the registration ID
        if let regID = Int64(code) {
            registrationID = regID
            showScanner = false
            loadRegistrationDetails(registrationID: regID)
        } else {
            errorMessage = "Invalid QR code format"
            showError = true
            scannedCode = ""
        }
    }
    
    private func enterManualRegistrationID() {
        // For testing - you can prompt for manual entry
        // For now, using a test ID
        let testID: Int64 = 1
        registrationID = testID
        showScanner = false
        loadRegistrationDetails(registrationID: testID)
    }
    
    private func loadRegistrationDetails(registrationID: Int64) {
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                // Fetch registration details
                registration = try await fetchRegistration(registrationID: registrationID)
                
                // Fetch visitors for this registration
                visitors = try await fetchVisitors(registrationID: registrationID)
                
                isLoading = false
            } catch {
                isLoading = false
                errorMessage = error.localizedDescription
                registration = nil
            }
        }
    }
    
    private func fetchRegistration(registrationID: Int64) async throws -> Registration {
        // Fetch from Supabase
        let response = try await SupabaseConfig.client
            .from("test_schema.Registration")
            .select("*")
            .eq("RegistrationID", value: String(registrationID))
            .single()
            .execute()
        
        let registration: Registration = try SupabaseConfig.decode(response.data, as: Registration.self)
        return registration
    }
    
    private func fetchVisitors(registrationID: Int64) async throws -> [Visitor] {
        let response = try await SupabaseConfig.client
            .from("test_schema.Visitors")
            .select("*")
            .eq("RegistrationID", value: String(registrationID))
            .execute()
        
        let visitors: [Visitor] = try SupabaseConfig.decode(response.data, as: [Visitor].self)
        return visitors
    }
    
    private func deleteVisitor(_ visitor: Visitor) {
        Task {
            do {
                try await SupabaseConfig.client
                    .from("test_schema.Visitors")
                    .delete()
                    .eq("VisitorID", value: String(visitor.visitorID))
                    .execute()
                
                // Remove from local list
                visitors.removeAll { $0.visitorID == visitor.visitorID }
                
            } catch {
                errorMessage = "Failed to delete visitor: \(error.localizedDescription)"
                showError = true
            }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let isoFormatter = ISO8601DateFormatter()
        if let date = isoFormatter.date(from: dateString) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        }
        return dateString
    }
}

// MARK: - Editable Visitor Row

@available(iOS 14.0, *)
struct EditableVisitorRow: View {
    let visitor: Visitor
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Visitor ID: \(visitor.visitorID)")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    Label("Visit: \(visitor.visitID)", systemImage: "person.fill")
                    if let foodTypeID = visitor.foodTypeID {
                        Label("Food: \(foodTypeID)", systemImage: "fork.knife")
                    }
                }
                .font(.caption)
                .foregroundColor(.secondary)
                
                if visitor.completed {
                    Label("Completed", systemImage: "checkmark.circle.fill")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "trash")
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
    }
}

// MARK: - Add Visitor View

@available(iOS 14.0, *)
struct AddVisitorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let registrationID: Int64
    let onComplete: () -> Void
    
    @State private var selectedVisitType: Int64 = 1
    @State private var selectedFoodType: Int16?
    @State private var isSubmitting = false
    @State private var errorMessage: String?
    @State private var showError = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Visitor Details") {
                    Picker("Visit Type", selection: $selectedVisitType) {
                        Text("Type 1").tag(Int64(1))
                        Text("Type 2").tag(Int64(2))
                        Text("Type 3").tag(Int64(3))
                    }
                    
                    Picker("Food Preference", selection: $selectedFoodType) {
                        Text("None").tag(nil as Int16?)
                        Text("Vegetarian").tag(Int16(1) as Int16?)
                        Text("Non-Vegetarian").tag(Int16(2) as Int16?)
                    }
                }
                
                Section {
                    Button(action: addVisitor) {
                        if isSubmitting {
                            HStack {
                                Spacer()
                                ProgressView()
                                Text("Adding...")
                                Spacer()
                            }
                        } else {
                            Text("Add Visitor")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .disabled(isSubmitting)
                }
            }
            .navigationTitle("Add Visitor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .alert("Error", isPresented: $showError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An error occurred")
            }
        }
    }
    
    private func addVisitor() {
        Task {
            isSubmitting = true
            
            do {
                struct VisitorPayload: Encodable {
                    let RegistrationID: Int64
                    let VisitID: Int64
                    let FoodTypeID: Int16?
                    let Completed: Bool
                }
                
                let payload = VisitorPayload(
                    RegistrationID: registrationID,
                    VisitID: selectedVisitType,
                    FoodTypeID: selectedFoodType,
                    Completed: false
                )
                
                try await SupabaseConfig.client
                    .from("test_schema.Visitors")
                    .insert([payload])
                    .execute()
                
                isSubmitting = false
                onComplete()
                dismiss()
                
            } catch {
                isSubmitting = false
                errorMessage = "Failed to add visitor: \(error.localizedDescription)"
                showError = true
            }
        }
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct UpdateRegistrationView_Previews: PreviewProvider {
    static var previews: some View {
        UpdateRegistrationView()
    }
}
