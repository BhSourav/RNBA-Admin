//
//  RegistrationService.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import Foundation
import Supabase

/// Service for handling registration-related database operations
@available(iOS 14.0, *)
class RegistrationService {
    
    private let supabase = SupabaseConfig.client
    
    // MARK: - Create Operations
    
    /// Creates a new registration with contact, visitors, and payment
    func createRegistration(_ registrationData: RegistrationData) async throws -> Int64 {
        // Return mock ID for preview mode
        if SupabaseConfig.isPreviewMode {
            return Int64.random(in: 1...1000)
        }
        
        do {
            // 1. Create Contact first
            let contactPayload = CreateContactRequest(
                telephone: registrationData.contactDetails.phone,
                mobile: registrationData.contactDetails.mobile.isEmpty ? nil : registrationData.contactDetails.mobile,
                email: registrationData.contactDetails.email,
                address: registrationData.contactDetails.address
            )
            
            let contactResponse = try await supabase
                .from("test_schema.Contact")
                .insert([contactPayload])
                .select()
                .execute()
            
            let contacts: [Contact] = try SupabaseConfig.decode(contactResponse.data, as: [Contact].self)
            guard let contact = contacts.first else {
                throw DataServiceError.registrationCreationFailed
            }
            
            // 2. Create Registration
            struct RegistrationPayload: Encodable {
                let Name: String
                let Contact: Int64
                let Event: Int32
            }
            
            let registrationPayload = RegistrationPayload(
                Name: registrationData.name,
                Contact: contact.contactID,
                Event: 2024 // Default event ID, you may want to make this configurable
            )
            
            let registrationResponse = try await supabase
                .from("test_schema.Registration")
                .insert([registrationPayload])
                .select()
                .execute()
            
            let registrations: [Registration] = try SupabaseConfig.decode(registrationResponse.data, as: [Registration].self)
            guard let registration = registrations.first else {
                throw DataServiceError.registrationCreationFailed
            }
            
            // 3. Create Visitors for each person
            try await createVisitors(for: registration.registrationID, persons: registrationData.persons)
            
            // 4. Create Payment if specified
            if registrationData.paymentAmount > 0 {
                try await createPayment(
                    for: registration.registrationID,
                    paymentType: registrationData.paymentType,
                    amount: registrationData.paymentAmount,
                    remarks: registrationData.paymentRemarks
                )
            }
            
            return registration.registrationID
            
        } catch {
            throw error
        }
    }
    
    // MARK: - Read Operations
    
    /// Fetches all registrations with details
    func fetchRegistrations() async throws -> [RegistrationDetail] {
        // Return mock data for preview mode
        if SupabaseConfig.isPreviewMode {
            print("📱 RegistrationService: Using mock data for preview mode")
            return []
        }
        
        do {
            let response = try await supabase
                .from("test_schema.Registration")
                .select("""
                    *,
                    test_schema.Contact!inner(*),
                    test_schema.Event!inner(*)
                """)
                .order("created_at", ascending: false)
                .execute()
            
            // Note: You'll need to parse this manually or create a combined model
            return []
            
        } catch {
            throw error
        }
    }
    
    // MARK: - Helper Methods
    
    private func createVisitors(for registrationID: Int64, persons: [PersonData]) async throws {
        struct VisitorPayload: Encodable {
            let RegistrationID: Int64
            let VisitID: Int64
            let FoodTypeID: Int16?
            let Completed: Bool
        }
        
        for person in persons {
            let visitorPayload = VisitorPayload(
                RegistrationID: registrationID,
                VisitID: person.visitType.visitID,
                FoodTypeID: person.foodPreference.foodTypeID,
                Completed: false
            )
            
            try await supabase
                .from("test_schema.Visitors")
                .insert([visitorPayload])
                .execute()
        }
    }
    
    private func createPayment(for registrationID: Int64, paymentType: PaymentType, amount: Decimal, remarks: String?) async throws {
        struct PaymentPayload: Encodable {
            let PaymentTypeID: Int64
            let RegistrationID: Int64
            let Amount: Decimal
            let Rema: String?
            
            enum CodingKeys: String, CodingKey {
                case PaymentTypeID
                case RegistrationID
                case Amount
                case Rema = "Rema..."
            }
        }
        
        let paymentPayload = PaymentPayload(
            PaymentTypeID: paymentType.paymentTypeID,
            RegistrationID: registrationID,
            Amount: amount,
            Rema: remarks
        )
        
        try await supabase
            .from("test_schema.Payment")
            .insert([paymentPayload])
            .execute()
    }
}
