//
//  RegistrationService.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import Foundation
import Supabase

/// Service for handling registration operations
@available(iOS 14.0, *)
class RegistrationService {
    
    private let supabase = SupabaseConfig.client
    private let dataManager = DataManager()
    
    // Cache durations
    private let registrationCacheDuration: TimeInterval = 1800 // 30 minutes
    private let visitorCacheDuration: TimeInterval = 3600 // 1 hour
    
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
    
    /// Fetches all registrations for a specific event
    func fetchRegistrationsForEvent(eventID: Int32) async throws -> [RegistrationSummary] {
        let cacheKey = DataManager.CacheKey.registrations
        
        // Return mock data for preview mode
        if SupabaseConfig.isPreviewMode {
            print("📱 RegistrationService: Using mock data for preview mode")
            return createMockRegistrations()
        }
        
        // Try cache first
        if let cachedRegistrations: [RegistrationSummary] = dataManager.get(forKey: cacheKey, maxAge: registrationCacheDuration) {
            print("📋 RegistrationService: Using cached registrations")
            return cachedRegistrations
        }
        
        print("📋 RegistrationService: Fetching fresh registrations from API")
        
        do {
            let response = try await supabase
                .from("test_schema.Registration")
                .select("RegistrationID, Name, created_at")
                .eq("Event", value: String(eventID))
                .order("created_at", ascending: false)
                .execute()
            
            let registrations: [RegistrationSummary] = try SupabaseConfig.decode(response.data, as: [RegistrationSummary].self)
            
            // Cache the result
            try dataManager.set(registrations, forKey: cacheKey, expiresIn: registrationCacheDuration)
            
            return registrations
            
        } catch {
            // Try to return cached data even if expired as fallback
            if let cachedRegistrations: [RegistrationSummary] = dataManager.get(forKey: cacheKey) {
                print("📋 RegistrationService: Using expired cache as fallback due to API error")
                return cachedRegistrations
            }
            throw error
        }
    }
    
    /// Fetches visitors with food for a specific registration
    func fetchVisitorsWithFood(registrationID: Int64) async throws -> [VisitorWithFood] {
        let cacheKey = DataManager.CacheKey.visitors(registrationID: registrationID)
        
        // Return mock data for preview mode
        if SupabaseConfig.isPreviewMode {
            print("📱 RegistrationService: Using mock visitors for preview mode")
            return createMockVisitorsWithFood(for: registrationID)
        }
        
        // Try cache first
        if let cachedVisitors: [VisitorWithFood] = dataManager.get(forKey: cacheKey, maxAge: visitorCacheDuration) {
            print("👥 RegistrationService: Using cached visitors for registration \(registrationID)")
            return cachedVisitors
        }
        
        print("👥 RegistrationService: Fetching fresh visitors for registration \(registrationID) from API")
        
        do {
            // First, get all visitors for this registration
            let visitorResponse = try await supabase
                .from("test_schema.Visitors")
                .select("*")
                .eq("RegistrationID", value: String(registrationID))
                .execute()
            
            let visitors: [Visitor] = try SupabaseConfig.decode(visitorResponse.data, as: [Visitor].self)
            
            // Get visit types to check withFood flag
            let visitTypeResponse = try await supabase
                .from("test_schema.Visit_Type")
                .select("*")
                .execute()
            
            let visitTypes: [VisitTypeModel] = try SupabaseConfig.decode(visitTypeResponse.data, as: [VisitTypeModel].self)
            
            // Get food types
            let foodTypeResponse = try await supabase
                .from("test_schema.Food_Type")
                .select("*")
                .execute()
            
            let foodTypes: [FoodTypeModel] = try SupabaseConfig.decode(foodTypeResponse.data, as: [FoodTypeModel].self)
            
            // Filter visitors where visitType has withFood = true
            let visitorsWithFood = visitors.compactMap { visitor -> VisitorWithFood? in
                guard let visitType = visitTypes.first(where: { $0.visitID == visitor.visitID }),
                      visitType.withFood else {
                    return nil
                }
                
                let foodType = visitor.foodTypeID != nil ? foodTypes.first(where: { $0.foodTypeID == visitor.foodTypeID }) : nil
                
                return VisitorWithFood(
                    visitorID: visitor.visitorID,
                    foodTypeName: foodType?.name ?? "Not specified",
                    completed: visitor.completed
                )
            }
            
            // Cache the result
            try dataManager.set(visitorsWithFood, forKey: cacheKey, expiresIn: visitorCacheDuration)
            
            return visitorsWithFood
            
        } catch {
            // Try to return cached data even if expired as fallback
            if let cachedVisitors: [VisitorWithFood] = dataManager.get(forKey: cacheKey) {
                print("👥 RegistrationService: Using expired cache as fallback for visitors")
                return cachedVisitors
            }
            throw error
        }
    }
    
    // MARK: - Mock Data
    
    private func createMockRegistrations() -> [RegistrationSummary] {
        return [
            RegistrationSummary(registrationID: 1, name: "John Doe", createdAt: "2024-10-15T10:00:00Z"),
            RegistrationSummary(registrationID: 2, name: "Jane Smith", createdAt: "2024-10-15T11:30:00Z"),
            RegistrationSummary(registrationID: 3, name: "Bob Johnson", createdAt: "2024-10-15T12:15:00Z"),
            RegistrationSummary(registrationID: 4, name: "Alice Williams", createdAt: "2024-10-15T13:45:00Z"),
            RegistrationSummary(registrationID: 5, name: "Charlie Brown", createdAt: "2024-10-15T14:20:00Z")
        ]
    }
    
    private func createMockVisitorsWithFood(for registrationID: Int64) -> [VisitorWithFood] {
        // Mock data based on registration ID
        switch registrationID {
        case 1:
            return [
                VisitorWithFood(visitorID: 1, foodTypeName: "Vegetarian", completed: true),
                VisitorWithFood(visitorID: 2, foodTypeName: "Non-Vegetarian", completed: false)
            ]
        case 2:
            return [
                VisitorWithFood(visitorID: 3, foodTypeName: "Vegetarian", completed: false),
                VisitorWithFood(visitorID: 4, foodTypeName: "Vegetarian", completed: false),
                VisitorWithFood(visitorID: 5, foodTypeName: "Non-Vegetarian", completed: true)
            ]
        case 3:
            return [
                VisitorWithFood(visitorID: 6, foodTypeName: "Non-Vegetarian", completed: false)
            ]
        case 4:
            return [
                VisitorWithFood(visitorID: 7, foodTypeName: "Vegetarian", completed: true),
                VisitorWithFood(visitorID: 8, foodTypeName: "Vegetarian", completed: false)
            ]
        case 5:
            return [
                VisitorWithFood(visitorID: 9, foodTypeName: "Non-Vegetarian", completed: false),
                VisitorWithFood(visitorID: 10, foodTypeName: "Non-Vegetarian", completed: false),
                VisitorWithFood(visitorID: 11, foodTypeName: "Vegetarian", completed: true)
            ]
        default:
            return []
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
