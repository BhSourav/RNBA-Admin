//
//  NewRegistrationView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import SwiftUI

@available(iOS 14.0, *)
struct NewRegistrationView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var registrationData = RegistrationData()
    @State private var showAlert = false
    @State private var alertMessage = ""
    @State private var isSaving = false
    
    private let registrationService = RegistrationService()
    
    var body: some View {
        NavigationView {
            Form {
                // Basic Information
                Section("Basic Information") {
                    TextField("Name", text: $registrationData.name)
                        .textContentType(.name)
                        .accessibilityLabel("Registration name")
                    
                    Stepper("Number of Persons: \(registrationData.numberOfPersons)", value: $registrationData.numberOfPersons, in: 1...10)
                        .accessibilityLabel("Number of persons")
                        .accessibilityValue("\(registrationData.numberOfPersons)")
                }
                
                // Person Details
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
                                        registrationData.persons[index].visitType : .generalVisit 
                                    },
                                    set: { newValue in
                                        if index < registrationData.persons.count {
                                            registrationData.persons[index].visitType = newValue
                                        }
                                    }
                                )) {
                                    ForEach(VisitType.allCases, id: \.self) { type in
                                        Text(type.displayName).tag(type)
                                    }
                                }
                                .pickerStyle(MenuPickerStyle())
                            }
                            
                            // Food Preference (only if visit type is food)
                            if index < registrationData.persons.count && 
                               registrationData.persons[index].visitType == .foodVisit {
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
                                            Text(preference.displayName).tag(preference)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }
                
                // Contact Details
                Section("Contact Details") {
                    TextField("Phone", text: $registrationData.contactDetails.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .accessibilityLabel("Phone number")
                    
                    TextField("Email", text: $registrationData.contactDetails.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                        .accessibilityLabel("Email address")
                    
                    TextField("Mobile (Optional)", text: $registrationData.contactDetails.mobile)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                        .accessibilityLabel("Mobile number")
                    
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
                                Text(type.displayName).tag(type)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                    
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", value: $registrationData.paymentAmount, format: .number)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .keyboardType(.decimalPad)
                            .frame(maxWidth: 150)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Remarks (Optional)")
                        TextField("Payment notes", text: Binding(
                            get: { registrationData.paymentRemarks ?? "" },
                            set: { registrationData.paymentRemarks = $0.isEmpty ? nil : $0 }
                        ), axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(2...4)
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
                        Task {
                            await saveRegistration()
                        }
                    }
                    .disabled(!isFormValid || isSaving)
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
    
    private func saveRegistration() async {
        // Validate form
        guard isFormValid else {
            alertMessage = "Please fill in all required fields"
            showAlert = true
            return
        }
        
        isSaving = true
        
        do {
            let registrationId = try await registrationService.createRegistration(registrationData)
            alertMessage = "Registration saved successfully! Registration ID: \(registrationId)"
            showAlert = true
        } catch {
            alertMessage = "Error saving registration: \(error.localizedDescription)"
            showAlert = true
        }
        
        isSaving = false
    }
}
