//
//  ContentView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 07.10.25.
//

import SwiftUI

/// The main view of the RNBA Admin app.
/// 
/// This view provides a complete admin experience with proper error handling,
/// accessibility support, and follows Apple's Human Interface Guidelines.
/// QR Code Scanner functionality is disabled for Mac simulation.
@available(iOS 14.0, *)
struct ContentView: View {
    
    // MARK: - State Properties
    
    @StateObject private var authManager = AuthenticationManager()
    
    // MARK: - Body
    
    var body: some View {
        TabView {
            // Overview Tab
            OverviewTabView()
                .tabItem {
                    Image(systemName: "chart.bar.fill")
                    Text("Overview")
                }
            
            // QR Scanner Tab
            QRScannerTabView()
                .tabItem {
                    Image(systemName: "qrcode.viewfinder")
                    Text("Scanner")
                }
            
            // Searchable List Tab
            SearchableListTabView()
                .tabItem {
                    Image(systemName: "list.bullet")
                    Text("List")
                }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Sign Out") {
                    signOut()
                }
                .foregroundColor(.red)
                .accessibilityLabel("Sign out of the app")
            }
        }
    }
    
    // MARK: - Private Methods
    
    /// Signs out the current user.
    private func signOut() {
        authManager.signOut()
    }
}

// MARK: - Overview Tab View

@available(iOS 14.0, *)
struct OverviewTabView: View {
    @State private var showNewRegistration = false
    
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
                    
                    
                    // Stats Cards
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(
                            title: "Total Users",
                            value: "1,234",
                            icon: "person.3.fill",
                            color: .blue
                        )
                        
                        StatCard(
                            title: "Active Sessions",
                            value: "89",
                            icon: "play.circle.fill",
                            color: .green
                        )
                        
                        StatCard(
                            title: "QR Scans Today",
                            value: "456",
                            icon: "qrcode.viewfinder",
                            color: .orange
                        )
                        
                        StatCard(
                            title: "System Status",
                            value: "Online",
                            icon: "checkmark.circle.fill",
                            color: .green
                        )
                    }
                    .padding(.horizontal)
                    
                    // Recent Activity
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Recent Activity")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .accessibilityAddTraits(.isHeader)
                        
                        VStack(spacing: 12) {
                            ActivityRow(
                                icon: "qrcode.viewfinder",
                                title: "QR Code Scanned",
                                subtitle: "User: John Doe",
                                time: "2 minutes ago"
                            )
                            
                            ActivityRow(
                                icon: "person.badge.plus",
                                title: "New User Registered",
                                subtitle: "User: Jane Smith",
                                time: "15 minutes ago"
                            )
                            
                            ActivityRow(
                                icon: "checkmark.circle",
                                title: "System Update",
                                subtitle: "Version 2.1.0 deployed",
                                time: "1 hour ago"
                            )
                        }
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(16)
                    .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                    .padding(.horizontal)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Overview")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showNewRegistration = true
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "person.badge.plus")
                            Text("New Registration")
                        }
                        .font(.subheadline)
                        .fontWeight(.medium)
                    }
                    .accessibilityLabel("Create new registration")
                }
            }
        }
        .sheet(isPresented: $showNewRegistration) {
            NewRegistrationView()
        }
    }
}

// MARK: - QR Scanner Tab View

@available(iOS 14.0, *)
struct QRScannerTabView: View {
    @State private var scannedCode = ""
    @State private var isScanning = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var showErrorAlert = false
    @State private var errorMessage = ""
    @State private var isProcessing = false
    @State private var mockQRCode = "https://example.com/mock-qr-code"
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemGray6)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
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
            .navigationTitle("QR Scanner")
            .navigationBarTitleDisplayMode(.large)
        .alert("QR Code Detected", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
        .alert("Scanning Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
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
    }
    
    private var scanningView: some View {
        VStack(spacing: 20) {
            // Instructions
            VStack(spacing: 8) {
                Image(systemName: "qrcode.viewfinder")
                    .font(.system(size: 40))
                    .foregroundColor(.accentColor)
                    .accessibilityHidden(true)
                
                Text("QR Code Scanner (Simulation Mode)")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)
                
                Text("Running in simulation mode for Mac compatibility")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal)
            
            // Mock scanner view
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemGray5))
                    .frame(height: 300)
                    .overlay(
                        VStack(spacing: 16) {
                            Image(systemName: "camera.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.secondary)
                            
                            Text("Camera View (Simulated)")
                                .font(.headline)
                                .foregroundColor(.secondary)
                            
                            Text("QR Code Scanner disabled for Mac")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.accentColor, lineWidth: 2)
                )
                    .accessibilityLabel("Mock QR code scanner camera view")
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
            
            // Mock scan button
            Button("Simulate QR Code Scan") {
                simulateQRScan()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .accessibilityLabel("Simulate QR code scan for testing")
        }
    }
    
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
                
                Text("(Simulated for Mac)")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
                Button("Simulate Another Scan") {
                    startNewScan()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .accessibilityLabel("Start simulating another QR code scan")
                
                Button("Copy to Clipboard") {
                    copyToClipboard()
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
                .accessibilityLabel("Copy scanned content to clipboard")
            }
        }
    }
    
    private func handleScannedCode(_ code: String) {
        guard !code.isEmpty else { return }
        
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            isProcessing = false
            alertMessage = "Successfully scanned: \(code)"
            showAlert = true
        }
    }
    
    private func simulateQRScan() {
        isProcessing = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            scannedCode = mockQRCode
            isScanning = false
            isProcessing = false
            alertMessage = "Simulated QR code scan: \(mockQRCode)"
            showAlert = true
        }
    }
    
    private func startNewScan() {
        isScanning = true
        scannedCode = ""
        isProcessing = false
    }
    
    private func retryScanning() {
        isScanning = true
        isProcessing = false
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = scannedCode
    }
}

// MARK: - Searchable List Tab View

@available(iOS 14.0, *)
struct SearchableListTabView: View {
    @State private var searchText = ""
    @State private var selectedItems: Set<String> = []
    
    // Mock data
    private let items = [
        "John Doe",
        "Jane Smith",
        "Mike Johnson",
        "Sarah Wilson",
        "David Brown",
        "Lisa Davis",
        "Tom Anderson",
        "Emma Taylor",
        "Chris Miller",
        "Amy Garcia"
    ]
    
    private var filteredItems: [String] {
        if searchText.isEmpty {
            return items
        } else {
            return items.filter { $0.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar
                SearchBar(text: $searchText)
                    .padding(.horizontal)
                
                // List
                List(filteredItems, id: \.self) { item in
                    HStack {
                        // Checkbox
                        Button(action: {
                            toggleSelection(for: item)
                        }) {
                            Image(systemName: selectedItems.contains(item) ? "checkmark.square.fill" : "square")
                                .foregroundColor(selectedItems.contains(item) ? .accentColor : .secondary)
                                .font(.title2)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .accessibilityLabel(selectedItems.contains(item) ? "Deselect \(item)" : "Select \(item)")
                        
                        // Name
                        Text(item)
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        Spacer()
                    }
                    .padding(.vertical, 4)
                }
                .listStyle(PlainListStyle())
                
                // Selection summary
                if !selectedItems.isEmpty {
                    VStack {
                        Divider()
                        HStack {
                            Text("\(selectedItems.count) item(s) selected")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                            
                            Button("Clear Selection") {
                                selectedItems.removeAll()
                            }
                            .font(.caption)
                            .foregroundColor(.accentColor)
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 8)
                    }
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("Searchable List")
            .navigationBarTitleDisplayMode(.large)
        }
    }
    
    private func toggleSelection(for item: String) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }
}

// MARK: - Supporting Views

@available(iOS 14.0, *)
struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 30))
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }
}

@available(iOS 14.0, *)
struct ActivityRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let time: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(time)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

@available(iOS 14.0, *)
struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Search items...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

// MARK: - Data Models

@available(iOS 14.0, *)
struct RegistrationData {
    var name: String = ""
    var numberOfPersons: Int = 1
    var persons: [PersonData] = [PersonData()]
    var contactDetails: ContactDetails = ContactDetails()
    var paymentType: PaymentType = .cash
}

@available(iOS 14.0, *)
struct PersonData {
    var visitType: VisitType = .general
    var foodPreference: FoodPreference = .none
}

@available(iOS 14.0, *)
struct ContactDetails {
    var phone: String = ""
    var email: String = ""
    var mobile: String = ""
    var address: String = ""
}

@available(iOS 14.0, *)
enum VisitType: String, CaseIterable {
    case general = "General Visit"
    case food = "Food Visit"
    case meeting = "Meeting"
    case event = "Event"
    case other = "Other"
}

@available(iOS 14.0, *)
enum FoodPreference: String, CaseIterable {
    case none = "No Preference"
    case vegetarian = "Vegetarian"
    case vegan = "Vegan"
    case nonVegetarian = "Non-Vegetarian"
    case halal = "Halal"
    case kosher = "Kosher"
}

@available(iOS 14.0, *)
enum PaymentType: String, CaseIterable {
    case cash = "Cash"
    case card = "Card"
    case online = "Online"
    case cheque = "Cheque"
    case other = "Other"
}

// MARK: - New Registration View

@available(iOS 14.0, *)
struct NewRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var registrationData = RegistrationData()
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information Section
                Section("Basic Information") {
                    HStack {
                        Text("Name")
                        Spacer()
                        TextField("Enter full name", text: $registrationData.name)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .frame(maxWidth: 200)
                    }
                    
                    Stepper("Number of Persons: \(registrationData.numberOfPersons)", 
                           value: $registrationData.numberOfPersons, 
                           in: 1...10)
                }
                
                // Persons Details Section
                Section("Person Details") {
                    ForEach(0..<registrationData.numberOfPersons, id: \.self) { index in
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Person \(index + 1)")
                                .font(.headline)
                                .foregroundColor(.primary)
                            
                            // Visit Type
                            HStack {
                                Text("Visit Type")
                                Spacer()
                                Picker("Visit Type", selection: Binding(
                                    get: { 
                                        index < registrationData.persons.count ? 
                                        registrationData.persons[index].visitType : .general 
                                    },
                                    set: { newValue in
                                        if index < registrationData.persons.count {
                                            registrationData.persons[index].visitType = newValue
                                        }
                                    }
                                )) {
                                    ForEach(VisitType.allCases, id: \.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            // Food Preference (only if visit type is food)
                            if index < registrationData.persons.count && 
                               registrationData.persons[index].visitType == .food {
                                HStack {
                                    Text("Food Preference")
                                    Spacer()
                                    Picker("Food Preference", selection: Binding(
                                        get: { 
                                            index < registrationData.persons.count ? 
                                            registrationData.persons[index].foodPreference : .none 
                                        },
                                        set: { newValue in
                                            if index < registrationData.persons.count {
                                                registrationData.persons[index].foodPreference = newValue
                                            }
                                        }
                                    )) {
                                        ForEach(FoodPreference.allCases, id: \.self) { preference in
                                            Text(preference.rawValue).tag(preference)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Contact Details Section
                Section("Contact Details") {
                    HStack {
                        Text("Phone")
                        Spacer()
                        TextField("Phone number", text: $registrationData.contactDetails.phone)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                    
                    HStack {
                        Text("Email")
                        Spacer()
                        TextField("Email address", text: $registrationData.contactDetails.email)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.emailAddress)
                            .autocapitalization(.none)
                    }
                    
                    HStack {
                        Text("Mobile")
                        Spacer()
                        TextField("Mobile number", text: $registrationData.contactDetails.mobile)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.phonePad)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Address")
                        TextField("Full address", text: $registrationData.contactDetails.address, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                    }
                }
                
                // Payment Section
                Section("Payment") {
                    HStack {
                        Text("Payment Type")
                        Spacer()
                        Picker("Payment Type", selection: $registrationData.paymentType) {
                            ForEach(PaymentType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }
            }
            .navigationTitle("New Registration")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveRegistration()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
        .alert("Registration", isPresented: $showAlert) {
            Button("OK") {
                if alertMessage.contains("successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            setupPersonsArray()
        }
        .onChange(of: registrationData.numberOfPersons) { _, newValue in
            updatePersonsArray(newCount: newValue)
        }
    }
    
    private var isFormValid: Bool {
        !registrationData.name.isEmpty &&
        !registrationData.contactDetails.phone.isEmpty &&
        !registrationData.contactDetails.email.isEmpty &&
        !registrationData.contactDetails.address.isEmpty
    }
    
    private func setupPersonsArray() {
        while registrationData.persons.count < registrationData.numberOfPersons {
            registrationData.persons.append(PersonData())
        }
    }
    
    private func updatePersonsArray(newCount: Int) {
        if newCount > registrationData.persons.count {
            // Add new persons
            for _ in registrationData.persons.count..<newCount {
                registrationData.persons.append(PersonData())
            }
        } else if newCount < registrationData.persons.count {
            // Remove excess persons
            registrationData.persons = Array(registrationData.persons.prefix(newCount))
        }
    }
    
    private func saveRegistration() {
        // Validate form
        guard isFormValid else {
            alertMessage = "Please fill in all required fields"
            showAlert = true
            return
        }
        
        // Simulate saving
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            alertMessage = "Registration saved successfully!"
            showAlert = true
        }
    }
}

// MARK: - Preview

@available(iOS 14.0, *)
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .previewDisplayName("RNBA Admin")
    }
}
