//
//  DeskModels.swift
//  RNBA Admin
//
//  Models for the RNBA_Prod event desks (Overview, Welcome Desk, Food Desk,
//  New Registration).
//

import Foundation

// These are plain data types passed in and out of the Supabase client, so
// they're nonisolated rather than inheriting the target's default MainActor
// isolation.

// MARK: - Event

/// A row of RNBA_Prod.Event.
nonisolated struct FestivalEvent: Codable, Identifiable, Hashable, Sendable {
    let eventid: Int
    let name: String
    let current: Bool?
    let date: String?
    let isevening: Bool?

    var id: Int { eventid }

    /// The event date as a Date, if it parses ("2026-10-17").
    var day: Date? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: date)
    }

    /// e.g. "Sat 17 Oct · Morning"
    var subtitle: String {
        var parts: [String] = []
        if let day {
            parts.append(day.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated)))
        }
        if let isevening {
            parts.append(isevening ? "Evening" : "Morning")
        }
        return parts.joined(separator: " · ")
    }
}

// MARK: - Event Visitor

/// One ticket for the selected event, as returned by GetEventVisitors.
nonisolated struct EventVisitor: Codable, Identifiable, Hashable, Sendable {
    let visitorid: Int64
    let registrationid: String
    let registration_name: String?
    let email: String?
    let visit_type: String?
    let withfood: Bool
    let foodtypeid: Int?
    let food_type: String?
    let child: Bool
    /// Welcome desk check-in.
    var completed: Bool
    /// Food desk: meal handed out.
    var food_served: Bool

    var id: Int64 { visitorid }

    var name: String { registration_name ?? "Unnamed" }

    var foodKind: FoodKind {
        guard withfood else { return .none }
        switch foodtypeid {
        case 1: return .veg
        case 2: return .nonVeg
        default: return .unspecified
        }
    }
}

/// Food on a ticket, derived from Visit_Type.withfood and foodtypeid.
nonisolated enum FoodKind: Sendable {
    case none, veg, nonVeg, unspecified

    var label: String {
        switch self {
        case .none: return "No food"
        case .veg: return "Veg"
        case .nonVeg: return "Non-Veg"
        case .unspecified: return "Food"
        }
    }
}

// MARK: - Registration Group

/// All tickets of one registration for the selected event - what the
/// welcome desk checks in together.
struct EventRegistrationGroup: Identifiable, Hashable {
    let registrationid: String
    let visitors: [EventVisitor]

    var id: String { registrationid }
    var name: String { visitors.first?.name ?? "Unnamed" }
    var email: String? { visitors.first?.email }
    var checkedInCount: Int { visitors.filter(\.completed).count }
    var isFullyCheckedIn: Bool { checkedInCount == visitors.count }
    var isPartlyCheckedIn: Bool { checkedInCount > 0 && !isFullyCheckedIn }
    var foodCount: Int { visitors.filter(\.withfood).count }
    var childCount: Int { visitors.filter(\.child).count }
    /// Registrations created in the app get "APP-..." IDs (sql/006).
    var isSpotRegistration: Bool { registrationid.hasPrefix("APP-") }
}

// MARK: - Search

/// Case-insensitive search over names and IDs. A leading "#" is ignored,
/// so "#1811" and "1811" both find ticket/registration 1811.
nonisolated enum DeskSearch {
    static func normalized(_ text: String) -> String {
        var query = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if query.hasPrefix("#") { query.removeFirst() }
        return query
    }

    static func matches(_ query: String, _ fields: [String?]) -> Bool {
        let query = normalized(query)
        guard !query.isEmpty else { return true }
        return fields.contains { field in
            guard let field else { return false }
            return field.localizedCaseInsensitiveContains(query)
        }
    }
}

// MARK: - Lookup Rows (New Registration)

nonisolated struct VisitTypeRow: Codable, Identifiable, Hashable, Sendable {
    let visitid: Int
    let name: String
    let withfood: Bool
    var id: Int { visitid }
}

nonisolated struct PaymentTypeRow: Codable, Identifiable, Hashable, Sendable {
    let paymenttypeid: Int
    let name: String
    var id: Int { paymenttypeid }
}

// MARK: - Walk-in Registration Input

/// One person in a walk-in registration.
struct WalkInPerson: Identifiable {
    let id = UUID()
    /// Visit_Type.name, e.g. "Visitor", "Member", "Performer".
    var category: String = "Visitor"
    var isChild: Bool = false
    var food: WalkInFood = .none
}

enum WalkInFood: Int, CaseIterable, Identifiable {
    case none = 0
    case veg = 1
    case nonVeg = 2

    var id: Int { rawValue }

    /// Food_Type.foodtypeid, or nil for no food.
    var foodTypeID: Int? { self == .none ? nil : rawValue }

    var label: String {
        switch self {
        case .none: return "No food"
        case .veg: return "Veg"
        case .nonVeg: return "Non-Veg"
        }
    }
}

struct WalkInRegistration {
    var name: String = ""
    var phone: String = ""
    var email: String = ""
    var mobile: String = ""
    var address: String = ""
    var persons: [WalkInPerson] = [WalkInPerson()]
    /// Walk-ins are standing at the welcome desk, so check them in by default.
    var checkInNow: Bool = true
    var paymentTypeID: Int?
    var paymentAmount: Decimal = 0
    var paymentRemarks: String = ""
}
