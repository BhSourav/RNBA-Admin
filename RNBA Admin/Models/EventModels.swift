//
//  EventModels.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 18.10.25.
//

import Foundation

// MARK: - Current Event Models

/// Response model for GetCurrentEventRegistrations RPC function
@available(iOS 14.0, *)
struct CurrentEventRegistrationsResponse: Codable {
    let event_id: Int32
    let registrations: [CurrentEventRegistration]?

    enum CodingKeys: String, CodingKey {
        case event_id = "event_id"
        case registrations = "registrations"
    }

    /// Check if response contains an error
    var hasError: Bool {
        return registrations == nil && event_id == 0
    }

    /// Get error message if present
    var errorMessage: String? {
        // Note: The function returns error in JSON, but our model doesn't capture it
        // This could be enhanced if needed
        return hasError ? "No current event or registrations found" : nil
    }
}

/// Individual registration in current event response
@available(iOS 14.0, *)
struct CurrentEventRegistration: Codable, Identifiable {
    let RegistrationID: Int64
    let Name: String

    var id: Int64 { RegistrationID }

    enum CodingKeys: String, CodingKey {
        case RegistrationID = "RegistrationID"
        case Name = "Name"
    }
}

// MARK: - Event Management Models

/// Model for event information
@available(iOS 14.0, *)
struct EventInfo: Codable, Identifiable {
    let eventID: Int32
    let name: String
    let date: String
    let isCurrent: Bool

    var id: Int32 { eventID }

    enum CodingKeys: String, CodingKey {
        case eventID = "EventID"
        case name = "Name"
        case date = "Date"
        case isCurrent = "Current"
    }
}

// MARK: - Request Models

/// Request parameters for GetCurrentEventRegistrations RPC call
@available(iOS 14.0, *)
struct GetCurrentEventRegistrationsRequest: Codable {
    // No parameters needed - function finds current event automatically
}
