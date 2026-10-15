//
//  FoodDeskView.swift
//  RNBA Admin
//
//  Food desk: every food ticket for the selected event, marked served one
//  ticket at a time.
//

import SwiftUI

struct FoodDeskView: View {
    @Environment(DeskStore.self) private var store
    @State private var searchText = ""
    @State private var filter: Filter = .toServe

    enum Filter: String, CaseIterable, Identifiable {
        case toServe = "To serve"
        case served = "Served"
        case all = "All"
        var id: Self { self }
    }

    private var filteredVisitors: [EventVisitor] {
        store.foodVisitors.filter { visitor in
            let matchesFilter: Bool
            switch filter {
            case .toServe: matchesFilter = !visitor.food_served
            case .served: matchesFilter = visitor.food_served
            case .all: matchesFilter = true
            }
            let fields = [visitor.name, visitor.registrationid, String(visitor.visitorid), visitor.email]
            return matchesFilter && DeskSearch.matches(searchText, fields)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    EventHeader()
                    summary
                    Picker("Show", selection: $filter) {
                        ForEach(Filter.allCases) { Text($0.rawValue).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    ForEach(filteredVisitors) { visitor in
                        FoodTicketRow(visitor: visitor) {
                            Task { await store.setFoodServed(visitor, true) }
                        }
                        .swipeActions(edge: .trailing) {
                            if visitor.food_served {
                                Button("Undo") {
                                    Task { await store.setFoodServed(visitor, false) }
                                }
                                .tint(.orange)
                            }
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .overlay { emptyState }
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Search name, registration or ticket ID"
            )
            .navigationTitle("Food Desk")
            .refreshable { await store.refreshVisitors() }
        }
    }

    private var summary: some View {
        let food = store.foodVisitors
        let veg = food.filter { $0.foodKind == .veg }
        let nonVeg = food.filter { $0.foodKind == .nonVeg }
        return HStack {
            Label("Veg \(veg.filter(\.food_served).count)/\(veg.count)", systemImage: "leaf.fill")
                .foregroundStyle(.green)
            Spacer()
            Label("Non-Veg \(nonVeg.filter(\.food_served).count)/\(nonVeg.count)", systemImage: "fork.knife")
                .foregroundStyle(.red)
        }
        .font(.subheadline.weight(.medium))
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var emptyState: some View {
        if store.isLoadingVisitors && store.visitors.isEmpty {
            ProgressView("Loading food tickets…")
        } else if filteredVisitors.isEmpty {
            if !DeskSearch.normalized(searchText).isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if store.foodVisitors.isEmpty {
                ContentUnavailableView(
                    "No Food Tickets",
                    systemImage: "fork.knife",
                    description: Text("Nobody has food booked for this event.")
                )
            } else if filter == .toServe {
                ContentUnavailableView(
                    "All Served",
                    systemImage: "checkmark.circle",
                    description: Text("Every food ticket for this event has been served.")
                )
            }
        }
    }
}

// MARK: - Row

private struct FoodTicketRow: View {
    let visitor: EventVisitor
    let onServe: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(visitor.name)
                    .font(.headline)
                Text("Ticket #\(visitor.visitorid) · \(visitor.registrationid)")
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    FoodBadge(kind: visitor.foodKind)
                    if visitor.child { TagBadge(text: "Child") }
                    if !visitor.completed {
                        // Not blocked: the food desk can still serve, but it's
                        // worth knowing the welcome desk hasn't seen them.
                        Label("Not checked in", systemImage: "exclamationmark.circle")
                            .font(.caption)
                            .foregroundStyle(.orange)
                    }
                }
            }

            Spacer()

            if visitor.food_served {
                Label("Served", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .foregroundStyle(.green)
                    .accessibilityLabel("Served")
            } else {
                Button("Serve", action: onServe)
                    .buttonStyle(.borderedProminent)
                    .tint(visitor.foodKind == .veg ? .green : .red)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    FoodDeskView()
        .environment(DeskStore())
}
