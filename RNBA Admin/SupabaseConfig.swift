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
    
    // MARK: - Configuration
    
    /// Supabase project URL
    static let supabaseURL = "YOUR_SUPABASE_URL" // Replace with your actual URL
    
    /// Supabase anonymous key
    static let supabaseKey = "YOUR_SUPABASE_ANON_KEY" // Replace with your actual key
    
    /// Shared Supabase client instance
    static let client = SupabaseClient(
        supabaseURL: URL(string: supabaseURL)!,
        supabaseKey: supabaseKey
    )
    
    // MARK: - Helper Methods
    
    /// Validates if Supabase is properly configured
    static var isConfigured: Bool {
        return !supabaseURL.contains("https://ofeayvavciwdzlyfdtqk.supabase.co") && 
               !supabaseKey.contains("sb_publishable_m3zLMhSn_HBSjsiClxklVA_ZJi-v9IH")
    }
    
    /// Gets configuration from Info.plist if available
    static func loadFromInfoPlist() -> (url: String, key: String)? {
        guard let path = Bundle.main.path(forResource: "Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let url = plist["SupabaseURL"] as? String,
              let key = plist["SupabaseKey"] as? String else {
            return nil
        }
        return (url: url, key: key)
    }
    
    /// Helper method to decode JSON data to model
    static func decode<T: Codable>(_ data: Data, as type: T.Type) throws -> T {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try decoder.decode(type, from: data)
    }
}

// MARK: - Database Models

/// Registration data model for Supabase
@available(iOS 14.0, *)
struct SupabaseRegistration: Codable {
    let id: UUID?
    let name: String
    let numberOfPersons: Int
    let phone: String
    let email: String
    let mobile: String?
    let address: String
    let paymentType: String
    let createdAt: String?
    let updatedAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case name
        case numberOfPersons = "number_of_persons"
        case phone
        case email
        case mobile
        case address
        case paymentType = "payment_type"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Person details model for Supabase
@available(iOS 14.0, *)
struct SupabasePersonDetail: Codable {
    let id: UUID?
    let registrationId: UUID
    let personIndex: Int
    let visitType: String
    let foodPreference: String?
    let createdAt: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case registrationId = "registration_id"
        case personIndex = "person_index"
        case visitType = "visit_type"
        case foodPreference = "food_preference"
        case createdAt = "created_at"
    }
}

/// Dashboard statistics model
@available(iOS 14.0, *)
struct DashboardStats: Codable {
    let totalUsers: Int
    let activeSessions: Int
    let qrScansToday: Int
    let systemStatus: String
}
