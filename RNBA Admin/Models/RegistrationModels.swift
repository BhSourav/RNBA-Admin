//
//  RegistrationModels.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import Foundation

// MARK: - Registration List Models

/// Summary of a registration for list display
@available(iOS 14.0, *)
struct RegistrationSummary: Codable, Identifiable {
    let registrationID: Int64
    let name: String
    let createdAt: String
    
    var id: Int64 { registrationID }
    
    enum CodingKeys: String, CodingKey {
        case registrationID = "RegistrationID"
        case name = "Name"
        case createdAt = "created_at"
    }
}

/// Visitor with food information
@available(iOS 14.0, *)
struct VisitorWithFood: Identifiable, Codable {
    let visitorID: Int64
    let foodTypeName: String
    var completed: Bool
    
    var id: Int64 { visitorID }
}

// MARK: - Registration Data Models

@available(iOS 14.0, *)
struct RegistrationData {
    var name: String = ""
    var numberOfPersons: Int = 1
    var persons: [PersonData] = [PersonData()]
    var contactDetails: ContactDetails = ContactDetails()
    var paymentType: PaymentType = .cash
    var paymentAmount: Decimal = 0
    var paymentRemarks: String? = nil
}

@available(iOS 14.0, *)
struct PersonData {
    var visitType: VisitType = .generalVisit
    var foodPreference: FoodPreference = .none
}

@available(iOS 14.0, *)
struct ContactDetails {
    var phone: String = ""
    var email: String = ""
    var mobile: String = ""
    var address: String = ""
}

// MARK: - Enums

@available(iOS 14.0, *)
enum VisitType: Int64, CaseIterable {
    case generalVisit = 1
    case foodVisit = 2
    
    var visitID: Int64 { self.rawValue }
    
    var displayName: String {
        switch self {
        case .generalVisit: return "General Visit"
        case .foodVisit: return "Food Visit"
        }
    }
}

@available(iOS 14.0, *)
enum FoodPreference: Int16, CaseIterable {
    case none = 0
    case vegetarian = 1
    case nonVegetarian = 2
    
    var foodTypeID: Int16? {
        self == .none ? nil : self.rawValue
    }
    
    var displayName: String {
        switch self {
        case .none: return "No Preference"
        case .vegetarian: return "Vegetarian"
        case .nonVegetarian: return "Non-Vegetarian"
        }
    }
}

@available(iOS 14.0, *)
enum PaymentType: Int64, CaseIterable {
    case cash = 1
    case card = 2
    case online = 3
    
    var paymentTypeID: Int64 { self.rawValue }
    
    var displayName: String {
        switch self {
        case .cash: return "Cash"
        case .card: return "Card"
        case .online: return "Online"
        }
    }
}
