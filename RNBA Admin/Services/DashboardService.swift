//
//  DashboardService.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import Foundation
import Supabase

/// Service for handling dashboard statistics operations
@available(iOS 14.0, *)
class DashboardService {
    
    private let supabase = SupabaseConfig.client
    
    // MARK: - Read Operations
    
    /// Fetches dashboard statistics from test_schema for today
    func fetchDashboardStats() async throws -> DashboardStats {
        // Return mock data for preview mode
        if SupabaseConfig.isPreviewMode {
            print("📱 DashboardService: Using mock dashboard stats for preview mode")
            return SupabaseConfig.mockDashboardStats
        }
        
        do {
            // Get today's date range (start of day to now)
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: Date())
            let todayISO = ISO8601DateFormatter().string(from: today)
            
            // 1. Get today's registrations
            let registrationResponse = try await supabase
                .from("test_schema.Registration")
                .select("RegistrationID")
                .gte("created_at", value: todayISO)
                .execute()
            let registrations: [Registration] = try SupabaseConfig.decode(registrationResponse.data, as: [Registration].self)
            
            // 2. Get today's visitors (all)
            let visitorResponse = try await supabase
                .from("test_schema.Visitors")
                .select("*")
                .gte("created_at", value: todayISO)
                .execute()
            let visitors: [Visitor] = try SupabaseConfig.decode(visitorResponse.data, as: [Visitor].self)
            
            // 3. Calculate visitors left to visit (not completed)
            let visitorsLeftToVisit = visitors.filter { !$0.completed }.count
            
            // 4. Get non-veg visitors (FoodTypeID = 2)
            let nonVegVisitors = visitors.filter { $0.foodTypeID == 2 }
            let nonVegLeftToEat = nonVegVisitors.filter { !$0.completed }.count
            
            // 5. Get veg visitors (FoodTypeID = 1)
            let vegVisitors = visitors.filter { $0.foodTypeID == 1 }
            let vegLeftToEat = vegVisitors.filter { !$0.completed }.count
            
            // 6. Get registrations left to visit (registrations where all visitors are not completed)
            // For simplicity, we count registrations that have at least one incomplete visitor
            let registrationIDs = Set(visitors.filter { !$0.completed }.map { $0.registrationID })
            let registrationsLeftToVisit = registrationIDs.count
            
            // 7. Spot registrations (assuming registrations created today are "spot")
            // Spot with veg food
            let spotVegVisitors = visitors.filter { visitor in
                visitor.foodTypeID == 1 && registrations.contains(where: { $0.registrationID == visitor.registrationID })
            }
            
            // Spot with non-veg food
            let spotNonVegVisitors = visitors.filter { visitor in
                visitor.foodTypeID == 2 && registrations.contains(where: { $0.registrationID == visitor.registrationID })
            }
            
            return DashboardStats(
                totalRegistrationsToday: registrations.count,
                registrationsLeftToVisit: registrationsLeftToVisit,
                totalVisitorsToday: visitors.count,
                visitorsLeftToVisit: visitorsLeftToVisit,
                nonVegVisitors: nonVegVisitors.count,
                nonVegLeftToEat: nonVegLeftToEat,
                vegVisitors: vegVisitors.count,
                vegLeftToEat: vegLeftToEat,
                spotRegistrationVeg: spotVegVisitors.count,
                spotRegistrationNonVeg: spotNonVegVisitors.count,
                systemStatus: "Online"
            )
            
        } catch {
            throw error
        }
    }
}
