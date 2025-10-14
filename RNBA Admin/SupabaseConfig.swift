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
        guard let path = Bundle.main.path(forResource: "RNBA-Admin-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let url = plist["SupabaseURL"] as? String,
              let key = plist["SupabaseKey"] as? String else {
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

/// Dashboard statistics model
@available(iOS 14.0, *)
struct DashboardStats: Codable {
    let totalRegistrations: Int
    let totalVisitors: Int
    let completedVisitors: Int
    let pendingVisitors: Int
    let totalPayments: Int
    let systemStatus: String
}

// MARK: - Mock Data for Previews

@available(iOS 14.0, *)
extension SupabaseConfig {
    /// Mock dashboard statistics for previews
    static let mockDashboardStats = DashboardStats(
        totalRegistrations: 125,
        totalVisitors: 342,
        completedVisitors: 287,
        pendingVisitors: 55,
        totalPayments: 98,
        systemStatus: "Online"
    )
}
