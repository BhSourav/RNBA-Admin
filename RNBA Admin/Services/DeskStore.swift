//
//  DeskStore.swift
//  RNBA Admin
//
//  App-wide state for the event desks: the event list, which event is
//  selected (remembered across launches), and that event's visitors.
//  Every tab reads from the same store, so a check-in at the welcome desk
//  shows up on the Overview and Food Desk tabs straight away.
//

import Foundation
import Observation

@Observable
final class DeskStore {

    // MARK: - State

    private(set) var events: [FestivalEvent] = []

    /// The event the whole app shows. Persisted, so each device stays on
    /// its own event after a restart.
    var selectedEventID: Int? {
        didSet {
            guard selectedEventID != oldValue else { return }
            UserDefaults.standard.set(selectedEventID, forKey: Self.selectedEventKey)
            visitors = []
        }
    }

    /// Non-cancelled visitors of the selected event.
    private(set) var visitors: [EventVisitor] = []

    private(set) var isLoadingEvents = false
    private(set) var isLoadingVisitors = false
    private(set) var lastUpdated: Date?

    /// Shown as an alert; cleared when dismissed.
    var errorMessage: String?

    private let service = DeskService()
    private static let selectedEventKey = "selectedEventID"

    init() {
        selectedEventID = UserDefaults.standard.object(forKey: Self.selectedEventKey) as? Int
    }

    // MARK: - Derived

    var selectedEvent: FestivalEvent? {
        events.first { $0.eventid == selectedEventID }
    }

    /// Visitors grouped by registration, sorted by name.
    var registrations: [EventRegistrationGroup] {
        Dictionary(grouping: visitors, by: \.registrationid)
            .map { EventRegistrationGroup(registrationid: $0.key, visitors: $0.value) }
            .sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
    }

    var foodVisitors: [EventVisitor] {
        visitors.filter(\.withfood)
    }

    // MARK: - Loading

    func loadEvents() async {
        isLoadingEvents = true
        defer { isLoadingEvents = false }
        do {
            events = try await service.fetchEvents()
            if selectedEvent == nil {
                selectedEventID = Self.defaultEvent(in: events)?.eventid
            }
        } catch {
            errorMessage = "Couldn't load events: \(error.localizedDescription)"
        }
    }

    /// Reloads the selected event's visitors. Results that arrive after the
    /// user has switched to another event are discarded.
    func refreshVisitors() async {
        guard let eventID = selectedEventID else { return }
        isLoadingVisitors = true
        defer { isLoadingVisitors = false }
        do {
            let fetched = try await service.fetchVisitors(eventID: eventID)
            guard eventID == selectedEventID else { return }
            visitors = fetched
            lastUpdated = Date()
        } catch is CancellationError {
            // The view went away or the event changed; nothing to report.
        } catch {
            guard eventID == selectedEventID else { return }
            errorMessage = "Couldn't load visitors: \(error.localizedDescription)"
        }
    }

    // MARK: - Check-ins

    /// Welcome desk: checks in (or undoes) every ticket of a registration
    /// for the selected event. Updates the screen first, and puts it back
    /// if the server call fails.
    func setCheckedIn(_ group: EventRegistrationGroup, _ checkedIn: Bool) async {
        guard let eventID = selectedEventID else { return }
        let ids = Set(group.visitors.map(\.visitorid))
        let previous = visitors
        update(ids) { $0.completed = checkedIn }
        do {
            try await service.setCheckedIn(registrationID: group.registrationid, eventID: eventID, checkedIn: checkedIn)
        } catch {
            if eventID == selectedEventID { visitors = previous }
            errorMessage = "Check-in for \(group.name) didn't save: \(error.localizedDescription)"
        }
    }

    /// Food desk: marks (or undoes) one ticket's meal as served.
    func setFoodServed(_ visitor: EventVisitor, _ served: Bool) async {
        let eventID = selectedEventID
        let previous = visitors
        update([visitor.visitorid]) { $0.food_served = served }
        do {
            try await service.setFoodServed(visitorID: visitor.visitorid, served: served)
        } catch {
            if eventID == selectedEventID { visitors = previous }
            errorMessage = "Food for ticket #\(visitor.visitorid) didn't save: \(error.localizedDescription)"
        }
    }

    private func update(_ ids: Set<Int64>, _ change: (inout EventVisitor) -> Void) {
        for index in visitors.indices where ids.contains(visitors[index].visitorid) {
            change(&visitors[index])
        }
    }

    // MARK: - Default Event

    /// The event marked current, else the next one from today, else the last.
    private static func defaultEvent(in events: [FestivalEvent]) -> FestivalEvent? {
        if let current = events.first(where: { $0.current == true }) {
            return current
        }
        let today = Calendar.current.startOfDay(for: Date())
        if let upcoming = events.first(where: { ($0.day ?? .distantPast) >= today }) {
            return upcoming
        }
        return events.last
    }
}
