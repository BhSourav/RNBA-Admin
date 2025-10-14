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
    
    /// Fetches dashboard statistics from test_schema
    func fetchDashboardStats() async throws -> DashboardStats {
        // Return mock data for preview mode
        if SupabaseConfig.isPreviewMode {
            print("📱 DashboardService: Using mock dashboard stats for preview mode")
            return SupabaseConfig.mockDashboardStats
        }
        
        do {
            // Get total registrations count
            let registrationResponse = try await supabase
                .from("test_schema.Registration")
                .select("RegistrationID")
                .execute()
            let registrations: [Registration] = try SupabaseConfig.decode(registrationResponse.data, as: [Registration].self)
            
            // Get total visitors count
            let visitorResponse = try await supabase
                .from("test_schema.Visitors")
                .select("VisitorID")
                .execute()
            let visitors: [Visitor] = try SupabaseConfig.decode(visitorResponse.data, as: [Visitor].self)
            
            // Get completed visitors count
            let completedResponse = try await supabase
                .from("test_schema.Visitors")
                .select("VisitorID")
                .eq("Completed", value: true)
                .execute()
            let completedVisitors: [Visitor] = try SupabaseConfig.decode(completedResponse.data, as: [Visitor].self)
            
            // Get total payments count
            let paymentResponse = try await supabase
                .from("test_schema.Payment")
                .select("PaymentID")
                .execute()
            let payments: [Payment] = try SupabaseConfig.decode(paymentResponse.data, as: [Payment].self)
            
            return DashboardStats(
                totalRegistrations: registrations.count,
                totalVisitors: visitors.count,
                completedVisitors: completedVisitors.count,
                pendingVisitors: visitors.count - completedVisitors.count,
                totalPayments: payments.count,
                systemStatus: "Online"
            )
            
        } catch {
            throw error
        }
    }
}
