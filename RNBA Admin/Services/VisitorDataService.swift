//
//  VisitorDataService.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 18.10.25.
//

import Foundation
import Supabase

/// Service for handling visitor data operations using RPC functions
@available(iOS 14.0, *)
class VisitorDataService {

    private let supabase = SupabaseConfig.client
    private let dataManager = DataManager()

    // Cache durations
    private let visitorDataCacheDuration: TimeInterval = 300 // 5 minutes

    // MARK: - RPC Function Calls

    /// Fetches visitor data for a specific registration using GetVisitorData RPC function
    /// - Parameter registrationID: The registration ID to fetch visitors for
    /// - Returns: Array of VisitorData objects
    func fetchVisitorData(registrationID: Int64) async throws -> [VisitorData] {
        let cacheKey = DataManager.CacheKey.visitorData(registrationID: registrationID)

        // Return mock data for preview mode
        if SupabaseConfig.isPreviewMode {
            print("📱 VisitorDataService: Using mock visitor data for preview mode")
            return createMockVisitorData(for: registrationID)
        }

        // Try cache first
        if let cachedData: [VisitorData] = dataManager.get(forKey: cacheKey, maxAge: visitorDataCacheDuration) {
            print("👥 VisitorDataService: Using cached visitor data for registration \(registrationID)")
            return cachedData
        }

        print("👥 VisitorDataService: Fetching fresh visitor data for registration \(registrationID) from API")

        do {
            // Call the GetVisitorData RPC function
            let response = try await supabase
                .rpc("getvisitordata", params: ["p_registrationid": registrationID])
                .execute()

            let visitorData: [VisitorData] = try SupabaseConfig.decode(response.data, as: [VisitorData].self)

            // Cache the result
            try dataManager.set(visitorData, forKey: cacheKey, expiresIn: visitorDataCacheDuration)

            print("✅ VisitorDataService: Successfully fetched \(visitorData.count) visitors for registration \(registrationID)")
            return visitorData

        } catch {
            // Try to return cached data even if expired as fallback
            if let cachedData: [VisitorData] = dataManager.get(forKey: cacheKey) {
                print("👥 VisitorDataService: Using expired cache as fallback for visitor data")
                return cachedData
            }
            print("❌ VisitorDataService: Failed to fetch visitor data: \(error.localizedDescription)")
            throw error
        }
    }

    /// Updates visitor completion status
    /// - Parameters:
    ///   - visitorID: The visitor ID to update
    ///   - completed: New completion status
    func updateVisitorCompletion(visitorID: Int64, completed: Bool) async throws {
        // For preview mode, just simulate success
        if SupabaseConfig.isPreviewMode {
            print("📱 VisitorDataService: Simulating visitor completion update for preview mode")
            return
        }

        do {
            let updateData = ["Completed": completed]
            let _ = try await supabase
                .from("Visitors")
                .update(updateData)
                .eq("VisitorID", value: String(visitorID))
                .execute()

            // Invalidate related caches
            invalidateVisitorDataCaches()

            print("✅ VisitorDataService: Successfully updated visitor \(visitorID) completion status")

        } catch {
            print("❌ VisitorDataService: Failed to update visitor completion: \(error.localizedDescription)")
            throw error
        }
    }

    /// Deletes a visitor
    /// - Parameter visitorID: The visitor ID to delete
    func deleteVisitor(visitorID: Int64) async throws {
        // For preview mode, just simulate success
        if SupabaseConfig.isPreviewMode {
            print("📱 VisitorDataService: Simulating visitor deletion for preview mode")
            return
        }

        do {
            let _ = try await supabase
                .from("Visitors")
                .delete()
                .eq("VisitorID", value: String(visitorID))
                .execute()

            // Invalidate related caches
            invalidateVisitorDataCaches()

            print("✅ VisitorDataService: Successfully deleted visitor \(visitorID)")

        } catch {
            print("❌ VisitorDataService: Failed to delete visitor: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Cache Management

    /// Invalidates all visitor data related caches
    func invalidateVisitorDataCaches() {
        print("🗑️ VisitorDataService: Invalidating visitor data caches")

        // Invalidate dashboard stats (they depend on visitor completion)
        dataManager.invalidate(forKey: DataManager.CacheKey.dashboardStats)

        // Note: Individual visitor data caches are invalidated by registrationID
        // when fetchVisitorData is called next time
    }

    /// Invalidates cache for a specific registration
    func invalidateCache(for registrationID: Int64) {
        let cacheKey = DataManager.CacheKey.visitorData(registrationID: registrationID)
        dataManager.invalidate(forKey: cacheKey)
        print("🗑️ VisitorDataService: Invalidated cache for registration \(registrationID)")
    }

    // MARK: - Mock Data

    private func createMockVisitorData(for registrationID: Int64) -> [VisitorData] {
        // Generate mock data based on registration ID
        switch registrationID {
        case 1:
            return [
                VisitorData(visitorid: 1, food_preference: "Vegetarian", visit_type: "General Visit", completed: true),
                VisitorData(visitorid: 2, food_preference: "Non-Vegetarian", visit_type: "Food Visit", completed: false)
            ]
        case 2:
            return [
                VisitorData(visitorid: 3, food_preference: "Vegetarian", visit_type: "General Visit", completed: false),
                VisitorData(visitorid: 4, food_preference: nil, visit_type: "General Visit", completed: true),
                VisitorData(visitorid: 5, food_preference: "Non-Vegetarian", visit_type: "Food Visit", completed: true)
            ]
        case 3:
            return [
                VisitorData(visitorid: 6, food_preference: "Vegetarian", visit_type: "Food Visit", completed: false)
            ]
        default:
            return []
        }
    }
}

// MARK: - Service Extension for UI Models

@available(iOS 14.0, *)
extension VisitorDataService {

    /// Fetches visitor data and converts to UI models
    func fetchVisitorDataUI(registrationID: Int64) async throws -> [VisitorDataUI] {
        let visitorData = try await fetchVisitorData(registrationID: registrationID)
        return visitorData.map { VisitorDataUI(visitorData: $0) }
    }
}
