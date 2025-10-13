//
//  DataService.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 07.10.25.
//

import Foundation
import Supabase
import Combine

/// Service class for handling all database operations with Supabase
@available(iOS 14.0, *)
@MainActor
class DataService: ObservableObject {
    
    // MARK: - Properties
    
    private let supabase = SupabaseConfig.client
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    // ObservableObject conformance
    var objectWillChange = ObservableObjectPublisher()
    
    // MARK: - Registration Operations
    
    /// Creates a new registration with person details
    func createRegistration(_ registrationData: RegistrationData) async throws -> UUID {
        isLoading = true
        errorMessage = nil
        
        do {
            // Create the main registration record
            let supabaseRegistration = SupabaseRegistration(
                id: nil,
                name: registrationData.name,
                numberOfPersons: registrationData.numberOfPersons,
                phone: registrationData.contactDetails.phone,
                email: registrationData.contactDetails.email,
                mobile: registrationData.contactDetails.mobile.isEmpty ? nil : registrationData.contactDetails.mobile,
                address: registrationData.contactDetails.address,
                paymentType: registrationData.paymentType.rawValue,
                createdAt: nil,
                updatedAt: nil
            )
            
            let response = try await supabase
                .from("registrations")
                .insert(supabaseRegistration)
                .select()
                .execute()
            
            let registrations: [SupabaseRegistration] = try SupabaseConfig.decode(response.data, as: [SupabaseRegistration].self)
            guard let newRegistration = registrations.first,
                  let registrationId = newRegistration.id else {
                throw DataServiceError.registrationCreationFailed
            }
            
            // Create person details for each person
            for (index, person) in registrationData.persons.enumerated() {
                let personDetail = SupabasePersonDetail(
                    id: nil,
                    registrationId: registrationId,
                    personIndex: index,
                    visitType: person.visitType.rawValue,
                    foodPreference: person.foodPreference == .none ? nil : person.foodPreference.rawValue,
                    createdAt: nil
                )
                
                try await supabase
                    .from("person_details")
                    .insert(personDetail)
                    .execute()
            }
            
            isLoading = false
            return registrationId
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Fetches all registrations
    func fetchRegistrations() async throws -> [SupabaseRegistration] {
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await supabase
                .from("registrations")
                .select()
                .order("created_at", ascending: false)
                .execute()
            
            let registrations: [SupabaseRegistration] = try SupabaseConfig.decode(response.data, as: [SupabaseRegistration].self)
            isLoading = false
            return registrations
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Fetches person details for a specific registration
    func fetchPersonDetails(for registrationId: UUID) async throws -> [SupabasePersonDetail] {
        do {
            let response = try await supabase
                .from("person_details")
                .select()
                .eq("registration_id", value: registrationId)
                .order("person_index", ascending: true)
                .execute()
            
            let personDetails: [SupabasePersonDetail] = try SupabaseConfig.decode(response.data, as: [SupabasePersonDetail].self)
            return personDetails
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Updates an existing registration
    func updateRegistration(id: UUID, data: RegistrationData) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            let supabaseRegistration = SupabaseRegistration(
                id: id,
                name: data.name,
                numberOfPersons: data.numberOfPersons,
                phone: data.contactDetails.phone,
                email: data.contactDetails.email,
                mobile: data.contactDetails.mobile.isEmpty ? nil : data.contactDetails.mobile,
                address: data.contactDetails.address,
                paymentType: data.paymentType.rawValue,
                createdAt: nil,
                updatedAt: nil
            )
            
            let _ = try await supabase
                .from("registrations")
                .update(supabaseRegistration)
                .eq("id", value: id)
                .execute()
            
            // Update person details
            let _ = try await supabase
                .from("person_details")
                .delete()
                .eq("registration_id", value: id)
                .execute()
            
            for (index, person) in data.persons.enumerated() {
                let personDetail = SupabasePersonDetail(
                    id: nil,
                    registrationId: id,
                    personIndex: index,
                    visitType: person.visitType.rawValue,
                    foodPreference: person.foodPreference == .none ? nil : person.foodPreference.rawValue,
                    createdAt: nil
                )
                
                let _ = try await supabase
                    .from("person_details")
                    .insert(personDetail)
                    .execute()
            }
            
            isLoading = false
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    /// Deletes a registration and its associated person details
    func deleteRegistration(id: UUID) async throws {
        isLoading = true
        errorMessage = nil
        
        do {
            // Delete person details first (due to foreign key constraint)
            let _ = try await supabase
                .from("person_details")
                .delete()
                .eq("registration_id", value: id)
                .execute()
            
            // Delete the main registration
            let _ = try await supabase
                .from("registrations")
                .delete()
                .eq("id", value: id)
                .execute()
            
            isLoading = false
            
        } catch {
            isLoading = false
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Dashboard Operations
    
    /// Fetches dashboard statistics
    func fetchDashboardStats() async throws -> DashboardStats {
        do {
            // Get total registrations count
            let totalResponse = try await supabase
                .from("registrations")
                .select("id")
                .execute()
            let totalRegistrations: [SupabaseRegistration] = try SupabaseConfig.decode(totalResponse.data, as: [SupabaseRegistration].self)
            
            // Get today's registrations count
            let today = ISO8601DateFormatter().string(from: Date())
            let todayResponse = try await supabase
                .from("registrations")
                .select("id")
                .gte("created_at", value: today)
                .execute()
            let todayRegistrations: [SupabaseRegistration] = try SupabaseConfig.decode(todayResponse.data, as: [SupabaseRegistration].self)
            
            return DashboardStats(
                totalUsers: totalRegistrations.count,
                activeSessions: Int.random(in: 50...100), // Mock data for now
                qrScansToday: Int.random(in: 200...500), // Mock data for now
                systemStatus: "Online"
            )
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Search Operations
    
    /// Searches registrations by name, email, or phone
    func searchRegistrations(query: String) async throws -> [SupabaseRegistration] {
        do {
            let response = try await supabase
                .from("registrations")
                .select()
                .or("name.ilike.%\(query)%,email.ilike.%\(query)%,phone.ilike.%\(query)%")
                .order("created_at", ascending: false)
                .execute()
            
            let registrations: [SupabaseRegistration] = try SupabaseConfig.decode(response.data, as: [SupabaseRegistration].self)
            return registrations
            
        } catch {
            errorMessage = error.localizedDescription
            throw error
        }
    }
    
    // MARK: - Real-time Subscriptions
    
    /// Subscribes to registration changes
    func subscribeToRegistrations(onChange: @escaping ([SupabaseRegistration]) -> Void) {
        let channel = supabase.realtimeV2.channel("registrations")
        
        // Subscribe to all postgres changes for registrations table
        channel.onPostgresChange(
            event: .insert,
            schema: "public",
            table: "registrations"
        ) { payload in
            Task { @MainActor in
                do {
                    let registrations = try await self.fetchRegistrations()
                    onChange(registrations)
                } catch {
                    print("Error fetching updated registrations: \(error)")
                }
            }
        }
        
        channel.onPostgresChange(
            event: .update,
            schema: "public",
            table: "registrations"
        ) { payload in
            Task { @MainActor in
                do {
                    let registrations = try await self.fetchRegistrations()
                    onChange(registrations)
                } catch {
                    print("Error fetching updated registrations: \(error)")
                }
            }
        }
        
        channel.onPostgresChange(
            event: .delete,
            schema: "public",
            table: "registrations"
        ) { payload in
            Task { @MainActor in
                do {
                    let registrations = try await self.fetchRegistrations()
                    onChange(registrations)
                } catch {
                    print("Error fetching updated registrations: \(error)")
                }
            }
        }
        
        Task {
            await channel.subscribe()
        }
    }
}

// MARK: - Error Types

@available(iOS 14.0, *)
enum DataServiceError: LocalizedError {
    case registrationCreationFailed
    case invalidData
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .registrationCreationFailed:
            return "Failed to create registration"
        case .invalidData:
            return "Invalid data provided"
        case .networkError:
            return "Network connection error"
        case .unknownError:
            return "An unknown error occurred"
        }
    }
}
