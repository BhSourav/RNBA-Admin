//
//  VisitorService.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import Foundation
import Supabase

/// Service for handling visitor-related database operations
@available(iOS 14.0, *)
class VisitorService {
    
    private let supabase = SupabaseConfig.client
    private let dataManager = DataManager()
    
    // Cache durations
    private let visitorCacheDuration: TimeInterval = 1800 // 30 minutes
    
    // MARK: - Read Operations
    
    /// Fetches all visitors from test_schema.visitors table
    func fetchVisitors() async throws -> [Visitor] {
        // Return mock data for preview mode
        if SupabaseConfig.isPreviewMode {
            print("📱 VisitorService: Using mock visitor data for preview mode")
            return createMockVisitors()
        }
        
        do {
            let response = try await supabase
                .from("test_schema.visitors")
                .select()
                .order("created_at", ascending: false)
                .execute()
            
            let visitors: [Visitor] = try SupabaseConfig.decode(response.data, as: [Visitor].self)
            return visitors
            
        } catch {
            throw error
        }
    }
    
    /// Fetches visitors with full details (including related data)
    func fetchVisitorDetails() async throws -> [VisitorDetail] {
        // Return mock data for preview mode
        if SupabaseConfig.isPreviewMode {
            print("📱 VisitorService: Using mock visitor details for preview mode")
            return createMockVisitorDetails()
        }
        
        do {
            let response = try await supabase
                .from("test_schema.visitors")
                .select("""
                    *,
                    test_schema.visit_type!inner(*),
                    test_schema.food_type(*),
                    test_schema.registration!inner(*)
                """)
                .order("created_at", ascending: false)
                .execute()
            
            let visitorDetails: [VisitorDetail] = try SupabaseConfig.decode(response.data, as: [VisitorDetail].self)
            return visitorDetails
            
        } catch {
            throw error
        }
    }
    
    // MARK: - Update Operations
    
    /// Updates visitor completed status
    func updateVisitorCompletedStatus(visitorID: Int64, completed: Bool) async throws {
        // For preview mode, just simulate success
        if SupabaseConfig.isPreviewMode {
            print("📱 VisitorService: Simulating visitor status update for preview mode")
            return
        }
        
        do {
            let updateData = ["Completed": completed]
            let _ = try await supabase
                .from("test_schema.visitors")
                .update(updateData)
                .eq("VisitorID", value: String(visitorID))
                .execute()
            
            // Invalidate related caches since data changed
            invalidateVisitorCaches()
            
        } catch {
            throw error
        }
    }
    
    // MARK: - Cache Management
    
    /// Invalidate all visitor-related caches
    func invalidateVisitorCaches() {
        print("🗑️ VisitorService: Invalidating visitor caches")
        
        // Invalidate dashboard stats (they depend on visitor completion)
        dataManager.invalidate(forKey: DataManager.CacheKey.dashboardStats)
        
        // Note: Individual visitor caches are invalidated by registrationID in RegistrationService
        // when fetchVisitorsWithFood is called next time
    }
    
    // MARK: - Mock Data
    
    private func createMockVisitors() -> [Visitor] {
        return [
            Visitor(
                visitorID: 1,
                createdAt: "2024-01-15T10:30:00Z",
                registrationID: 1,
                visitID: 1,
                foodTypeID: 1,
                completed: true
            ),
            Visitor(
                visitorID: 2,
                createdAt: "2024-01-15T11:15:00Z",
                registrationID: 1,
                visitID: 2,
                foodTypeID: 2,
                completed: false
            ),
            Visitor(
                visitorID: 3,
                createdAt: "2024-01-15T12:00:00Z",
                registrationID: 2,
                visitID: 1,
                foodTypeID: nil,
                completed: true
            )
        ]
    }
    
    private func createMockVisitorDetails() -> [VisitorDetail] {
        let mockVisitors = createMockVisitors()
        let mockVisitTypes = [
            VisitTypeModel(visitID: 1, name: "General Visit", withFood: true),
            VisitTypeModel(visitID: 2, name: "Food Visit", withFood: true)
        ]
        let mockFoodTypes = [
            FoodTypeModel(foodTypeID: 1, name: "Vegetarian"),
            FoodTypeModel(foodTypeID: 2, name: "Non-Vegetarian")
        ]
        let mockRegistrations = [
            Registration(registrationID: 1, createdAt: "2024-01-15T10:00:00Z", name: "John Doe", contactID: 1, eventID: 2024),
            Registration(registrationID: 2, createdAt: "2024-01-15T11:00:00Z", name: "Jane Smith", contactID: 2, eventID: 2024)
        ]
        
        return mockVisitors.map { visitor in
            let visitType = mockVisitTypes.first { $0.visitID == visitor.visitID }
            let foodType = visitor.foodTypeID != nil ? mockFoodTypes.first { $0.foodTypeID == visitor.foodTypeID } : nil
            let registration = mockRegistrations.first { $0.registrationID == visitor.registrationID }
            
            return VisitorDetail(
                visitor: visitor,
                visitType: visitType,
                foodType: foodType,
                registration: registration
            )
        }
    }
}
