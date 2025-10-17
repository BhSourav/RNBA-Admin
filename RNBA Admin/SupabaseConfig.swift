//
//  SupabaseConfig.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 07.10.25.
//

import Foundation
import Supabase

/// Configuration and client setup for Supabase integration
@available(iOS 14.0, *)
struct SupabaseConfig {
    
    // MARK: - Helper Methods
    
    /// Gets configuration from Info.plist if available
    private static func loadFromInfoPlist() -> (url: String, key: String)? {
        guard let url = Bundle.main.object(forInfoDictionaryKey: "SupabaseURL") as? String,
              let key = Bundle.main.object(forInfoDictionaryKey: "SupabaseKey") as? String else {
            return nil
        }
        return (url: url, key: key)
    }
    
    // MARK: - Configuration
    
    /// Supabase project URL - loaded from Info.plist
    static let supabaseURL: String = {
        if let config = loadFromInfoPlist() {
            return config.url
        }
        // Fallback for development (should be replaced with your actual URL)
        return "https://your-project.supabase.co"
    }()
    
    /// Supabase anonymous key - loaded from Info.plist
    static let supabaseKey: String = {
        if let config = loadFromInfoPlist() {
            return config.key
        }
        // Fallback for development (should be replaced with your actual key)
        return "your-anon-key"
    }()
    
    /// Shared Supabase client instance
    static let client = SupabaseClient(
        supabaseURL: URL(string: supabaseURL)!,
        supabaseKey: supabaseKey
    )
    
    // MARK: - Additional Helper Methods
    
    /// Validates if Supabase is properly configured
    static var isConfigured: Bool {
        return !supabaseURL.contains("your-project") && 
               !supabaseKey.contains("your-anon-key")
    }
    
    /// Test basic connectivity to Supabase
    static func testConnectivity() async -> Bool {
        do {
            // Test the auth endpoint which should always be available
            let authUrl = URL(string: "\(supabaseURL)/auth/v1/health")!
            var request = URLRequest(url: authUrl)
            request.httpMethod = "GET"
            request.setValue("Bearer \(supabaseKey)", forHTTPHeaderField: "Authorization")
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                // Accept 200 (OK) or 404 (endpoint not found but server responds)
                let success = (200...404).contains(httpResponse.statusCode)
                return success
            }
            return false
        } catch {
            // If auth endpoint fails, try basic REST endpoint
            return await testBasicConnectivity()
        }
    }
    
    /// Test very basic connectivity (fallback)
    private static func testBasicConnectivity() async -> Bool {
        do {
            // Try to connect to a known Supabase endpoint that should exist
            let healthUrl = URL(string: "\(supabaseURL)/rest/v1/")!
            var request = URLRequest(url: healthUrl)
            request.httpMethod = "GET"
            request.timeoutInterval = 10
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                let success = httpResponse.statusCode != 0  // Any response means server is reachable
                return success
            }
            return false
        } catch {
            return false
        }
    }
    
    /// Force preview mode for testing (set to true for previews)
    static var forcePreviewMode = false
    
    /// Checks if we're running in preview mode
    static var isPreviewMode: Bool {
        #if DEBUG
        return forcePreviewMode || 
               ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" ||
               ProcessInfo.processInfo.environment["PREVIEW_MODE"] == "1"
        #else
        return false
        #endif
    }
    
    /// Helper method to decode JSON data to model
    static func decode<T: Codable>(_ data: Data, as type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
}

// MARK: - Dashboard Statistics Model

/// Dashboard statistics model for today's data
@available(iOS 14.0, *)
struct DashboardStats: Codable {
    // Registration stats
    let totalRegistrationsToday: Int
    let registrationsLeftToVisit: Int
    
    // Visitor stats
    let totalVisitorsToday: Int
    let visitorsLeftToVisit: Int
    
    // Food stats
    let nonVegVisitors: Int
    let nonVegLeftToEat: Int
    let vegVisitors: Int
    let vegLeftToEat: Int
    
    // Spot registration stats
    let spotRegistrationVeg: Int
    let spotRegistrationNonVeg: Int
    
    let systemStatus: String
}

// MARK: - Mock Data for Previews

@available(iOS 14.0, *)
extension SupabaseConfig {
    /// Mock dashboard statistics for previews
    static let mockDashboardStats = DashboardStats(
        totalRegistrationsToday: 45,
        registrationsLeftToVisit: 12,
        totalVisitorsToday: 128,
        visitorsLeftToVisit: 23,
        nonVegVisitors: 76,
        nonVegLeftToEat: 15,
        vegVisitors: 52,
        vegLeftToEat: 8,
        spotRegistrationVeg: 18,
        spotRegistrationNonVeg: 27,
        systemStatus: "Online"
    )
}
