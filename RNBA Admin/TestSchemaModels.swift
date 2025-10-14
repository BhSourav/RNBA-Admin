//
//  TestSchemaModels.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 07.10.25.
//

import Foundation

// MARK: - Test Schema Models

/// Visit Type lookup table
@available(iOS 14.0, *)
struct VisitTypeModel: Codable, Identifiable {
    let visitID: Int64
    let name: String
    let withFood: Bool
    
    var id: Int64 { visitID }
    
    enum CodingKeys: String, CodingKey {
        case visitID = "VisitID"
        case name = "Name"
        case withFood = "WithFood"
    }
}

/// Food Type lookup table
@available(iOS 14.0, *)
struct FoodTypeModel: Codable, Identifiable {
    let foodTypeID: Int16
    let name: String
    
    var id: Int16 { foodTypeID }
    
    enum CodingKeys: String, CodingKey {
        case foodTypeID = "FoodTypeID"
        case name = "Name"
    }
}

/// Payment Type lookup table
@available(iOS 14.0, *)
struct PaymentTypeModel: Codable, Identifiable {
    let paymentTypeID: Int64
    let name: String
    let icon: Data? // bytea in database
    
    var id: Int64 { paymentTypeID }
    
    enum CodingKeys: String, CodingKey {
        case paymentTypeID = "PaymentTypeID"
        case name = "Name"
        case icon = "Icon"
    }
}

/// Contact information table
@available(iOS 14.0, *)
struct Contact: Codable, Identifiable {
    let contactID: Int64
    let createdAt: String // timestamptz
    let telephone: String?
    let mobile: String?
    let email: String?
    let address: String?
    
    var id: Int64 { contactID }
    
    enum CodingKeys: String, CodingKey {
        case contactID = "ContactID"
        case createdAt = "created_at"
        case telephone = "Telephone"
        case mobile = "Mobile"
        case email = "Email"
        case address = "Address"
    }
}

/// Event table
@available(iOS 14.0, *)
struct Event: Codable, Identifiable {
    let eventID: Int32
    let name: String
    let year: String
    
    var id: Int32 { eventID }
    
    enum CodingKeys: String, CodingKey {
        case eventID = "EventID"
        case name = "Name"
        case year = "Year"
    }
}

/// Registration table - central entity
@available(iOS 14.0, *)
struct Registration: Codable, Identifiable {
    let registrationID: Int64
    let createdAt: String // timestamptz
    let name: String
    let contactID: Int64 // Foreign key to Contact
    let eventID: Int32 // Foreign key to Event
    
    var id: Int64 { registrationID }
    
    enum CodingKeys: String, CodingKey {
        case registrationID = "RegistrationID"
        case createdAt = "created_at"
        case name = "Name"
        case contactID = "Contact"
        case eventID = "Event"
    }
}

/// Visitor table
@available(iOS 14.0, *)
struct Visitor: Codable, Identifiable {
    let visitorID: Int64
    let createdAt: String // timestamptz
    let registrationID: Int64 // Foreign key to Registration
    let visitID: Int64 // Foreign key to VisitType
    let foodTypeID: Int16? // Foreign key to FoodType (nullable)
    let completed: Bool
    
    var id: Int64 { visitorID }
    
    enum CodingKeys: String, CodingKey {
        case visitorID = "VisitorID"
        case createdAt = "created_at"
        case registrationID = "RegistrationID"
        case visitID = "VisitID"
        case foodTypeID = "FoodTypeID"
        case completed = "Completed"
    }
}

/// Payment table
@available(iOS 14.0, *)
struct Payment: Codable, Identifiable {
    let paymentID: Int64
    let createdAt: String // timestamptz
    let paymentTypeID: Int64 // Foreign key to PaymentType
    let registrationID: Int64 // Foreign key to Registration
    let amount: Decimal // numeric in database
    let remarks: String? // Rema... in schema (likely Remarks)
    
    var id: Int64 { paymentID }
    
    enum CodingKeys: String, CodingKey {
        case paymentID = "PaymentID"
        case createdAt = "created_at"
        case paymentTypeID = "PaymentTypeID"
        case registrationID = "RegistrationID"
        case amount = "Amount"
        case remarks = "Rema..."
    }
}

// MARK: - Extended Models with Relationships

/// Registration with full details (includes related data)
@available(iOS 14.0, *)
struct RegistrationDetail: Codable, Identifiable {
    let registration: Registration
    let contact: Contact?
    let event: Event?
    let visitors: [Visitor]?
    let payments: [Payment]?
    
    var id: Int64 { registration.id }
    
    enum CodingKeys: String, CodingKey {
        case registration
        case contact
        case event
        case visitors
        case payments
    }
}

/// Visitor with full details (includes related lookup data)
@available(iOS 14.0, *)
struct VisitorDetail: Codable, Identifiable {
    let visitor: Visitor
    let visitType: VisitTypeModel?
    let foodType: FoodTypeModel?
    let registration: Registration?
    
    var id: Int64 { visitor.id }
    
    enum CodingKeys: String, CodingKey {
        case visitor
        case visitType
        case foodType
        case registration
    }
}

/// Payment with full details (includes related lookup data)
@available(iOS 14.0, *)
struct PaymentDetail: Codable, Identifiable {
    let payment: Payment
    let paymentType: PaymentTypeModel?
    let registration: Registration?
    
    var id: Int64 { payment.id }
    
    enum CodingKeys: String, CodingKey {
        case payment
        case paymentType
        case registration
    }
}

// MARK: - Request/Response Models

/// Request model for creating a new registration
@available(iOS 14.0, *)
struct CreateRegistrationRequest: Codable {
    let name: String
    let contactID: Int64
    let eventID: Int32
    let visitors: [CreateVisitorRequest]
    let payments: [CreatePaymentRequest]
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case contactID = "Contact"
        case eventID = "Event"
        case visitors
        case payments
    }
}

/// Request model for creating a visitor
@available(iOS 14.0, *)
struct CreateVisitorRequest: Codable {
    let registrationID: Int64
    let visitID: Int64
    let foodTypeID: Int16?
    let completed: Bool
    
    enum CodingKeys: String, CodingKey {
        case registrationID = "RegistrationID"
        case visitID = "VisitID"
        case foodTypeID = "FoodTypeID"
        case completed = "Completed"
    }
}

/// Request model for creating a payment
@available(iOS 14.0, *)
struct CreatePaymentRequest: Codable {
    let paymentTypeID: Int64
    let registrationID: Int64
    let amount: Decimal
    let remarks: String?
    
    enum CodingKeys: String, CodingKey {
        case paymentTypeID = "PaymentTypeID"
        case registrationID = "RegistrationID"
        case amount = "Amount"
        case remarks = "Rema..."
    }
}

/// Request model for creating contact
@available(iOS 14.0, *)
struct CreateContactRequest: Codable {
    let telephone: String?
    let mobile: String?
    let email: String?
    let address: String?
    
    enum CodingKeys: String, CodingKey {
        case telephone = "Telephone"
        case mobile = "Mobile"
        case email = "Email"
        case address = "Address"
    }
}

// MARK: - Update Models

/// Update model for registration
@available(iOS 14.0, *)
struct UpdateRegistrationRequest: Codable {
    let name: String?
    let contactID: Int64?
    let eventID: Int32?
    
    enum CodingKeys: String, CodingKey {
        case name = "Name"
        case contactID = "Contact"
        case eventID = "Event"
    }
}

/// Update model for visitor
@available(iOS 14.0, *)
struct UpdateVisitorRequest: Codable {
    let visitID: Int64?
    let foodTypeID: Int16?
    let completed: Bool?
    
    enum CodingKeys: String, CodingKey {
        case visitID = "VisitID"
        case foodTypeID = "FoodTypeID"
        case completed = "Completed"
    }
}

/// Update model for payment
@available(iOS 14.0, *)
struct UpdatePaymentRequest: Codable {
    let paymentTypeID: Int64?
    let amount: Decimal?
    let remarks: String?
    
    enum CodingKeys: String, CodingKey {
        case paymentTypeID = "PaymentTypeID"
        case amount = "Amount"
        case remarks = "Rema..."
    }
}

// MARK: - Statistics Models

/// Dashboard statistics for Test schema
@available(iOS 14.0, *)
struct TestSchemaStats: Codable {
    let totalRegistrations: Int
    let totalVisitors: Int
    let totalPayments: Int
    let totalEvents: Int
    let completedVisitors: Int
    let totalRevenue: Decimal
    let averagePaymentAmount: Decimal
}

/// Event statistics
@available(iOS 14.0, *)
struct EventStats: Codable {
    let event: Event
    let registrationCount: Int
    let visitorCount: Int
    let totalRevenue: Decimal
    let completedVisitors: Int
}

// MARK: - Search and Filter Models

/// Search parameters for registrations
@available(iOS 14.0, *)
struct RegistrationSearchParams: Codable {
    let name: String?
    let eventID: Int32?
    let contactEmail: String?
    let contactPhone: String?
    let dateFrom: String?
    let dateTo: String?
}

/// Filter parameters for visitors
@available(iOS 14.0, *)
struct VisitorFilterParams: Codable {
    let registrationID: Int64?
    let visitID: Int64?
    let foodTypeID: Int16?
    let completed: Bool?
    let dateFrom: String?
    let dateTo: String?
}

/// Filter parameters for payments
@available(iOS 14.0, *)
struct PaymentFilterParams: Codable {
    let registrationID: Int64?
    let paymentTypeID: Int64?
    let minAmount: Decimal?
    let maxAmount: Decimal?
    let dateFrom: String?
    let dateTo: String?
}
