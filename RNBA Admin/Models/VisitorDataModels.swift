//
//  VisitorDataModels.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 18.10.25.
//

import Foundation

// MARK: - Visitor Data Model

/// Model for visitor data returned by GetVisitorData RPC function
@available(iOS 14.0, *)
struct VisitorData: Codable, Identifiable {
    let visitorid: Int64
    let food_preference: String?
    let visit_type: String?
    let completed: Bool

    var id: Int64 { visitorid }

    enum CodingKeys: String, CodingKey {
        case visitorid = "visitorid"
        case food_preference = "food_preference"
        case visit_type = "visit_type"
        case completed = "completed"
    }
}

// MARK: - Extended Visitor Data Model

/// Extended model with additional computed properties for UI
@available(iOS 14.0, *)
struct VisitorDataUI: Identifiable {
    let visitorData: VisitorData
    var isSelected: Bool = false

    var id: Int64 { visitorData.id }

    // Computed properties for UI
    var displayName: String {
        "Visitor #\(visitorData.visitorid)"
    }

    var foodPreferenceDisplay: String {
        visitorData.food_preference ?? "Not specified"
    }

    var visitTypeDisplay: String {
        visitorData.visit_type ?? "Unknown"
    }

    var completionStatus: String {
        visitorData.completed ? "Completed" : "Pending"
    }

    var completionIcon: String {
        visitorData.completed ? "checkmark.circle.fill" : "circle"
    }

    var completionColor: String {
        visitorData.completed ? "green" : "gray"
    }
}

// MARK: - Request Model

/// Request parameters for GetVisitorData RPC call
@available(iOS 14.0, *)
struct GetVisitorDataRequest: Codable {
    let p_registrationid: Int64

    enum CodingKeys: String, CodingKey {
        case p_registrationid = "p_registrationid"
    }
}
