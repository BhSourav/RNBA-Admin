//
//  WelcomeDeskView.swift
//  RNBA Admin
//
//  Welcome desk: find a registration for the selected event by name or
//  registration/ticket ID, and check in all of its people at once.
//

import SwiftUI

struct WelcomeDeskView: View {
    @Environment(DeskStore.self) private var store
    @State private var searchText = ""
    @State private var filter: Filter = .notCheckedIn
    @State private var selectedGroup: EventRegistrationGroup?

    enum Filter: String, CaseIterable, Identifiable {
        case notCheckedIn = "To check in"
        case checkedIn = "Checked in"
        case all = "All"
        var id: Self { self }
    }

    private var filteredGroups: [EventRegistrationGroup] {
        store.registrations.filter { group in
            let matchesFilter: Bool
            switch filter {
            case .notCheckedIn: matchesFilter = !group.isFullyCheckedIn
            case .checkedIn: matchesFilter = group.isFullyCheckedIn
            case .all: matchesFilter = true
            }
            // Ticket IDs are searchable too: a single ticket's ID is often
            // also its registration ID.
            let fields = [group.name, group.registrationid, group.email]
                + group.visitors.map { String($0.visitorid) }
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
                    ForEach(filteredGroups) { group in
                        RegistrationRow(group: group) {
                            Task { await store.setCheckedIn(group, true) }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture { selectedGroup = group }
                        .swipeActions(edge: .trailing) {
                            if group.checkedInCount > 0 {
                                Button("Undo") {
                                    Task { await store.setCheckedIn(group, false) }
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
            .navigationTitle("Welcome Desk")
            .refreshable { await store.refreshVisitors() }
            .sheet(item: $selectedGroup) { group in
                RegistrationCheckInSheet(registrationID: group.registrationid)
            }
        }
    }

    private var summary: some View {
        let groups = store.registrations
        let done = groups.filter(\.isFullyCheckedIn).count
        let people = store.visitors.count
        let arrived = store.visitors.filter(\.completed).count
        return HStack {
            Label("\(done) of \(groups.count) registrations", systemImage: "person.text.rectangle")
            Spacer()
            Label("\(arrived) of \(people) people", systemImage: "person.3")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var emptyState: some View {
        if store.isLoadingVisitors && store.visitors.isEmpty {
            ProgressView("Loading registrations…")
        } else if filteredGroups.isEmpty {
            if !DeskSearch.normalized(searchText).isEmpty {
                ContentUnavailableView.search(text: searchText)
            } else if store.visitors.isEmpty {
                ContentUnavailableView(
                    "No Registrations",
                    systemImage: "person.text.rectangle",
                    description: Text("Nobody is registered for this event yet.")
                )
            } else if filter == .notCheckedIn {
                ContentUnavailableView(
                    "Everyone Is Checked In",
                    systemImage: "checkmark.circle",
                    description: Text("All registrations for this event have arrived.")
                )
            }
        }
    }
}

// MARK: - Row

private struct RegistrationRow: View {
    let group: EventRegistrationGroup
    let onCheckIn: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(group.name)
                    .font(.headline)
                Text(group.registrationid)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                HStack(spacing: 6) {
                    TagBadge(text: group.visitors.count == 1 ? "1 person" : "\(group.visitors.count) people")
                    if group.foodCount > 0 { TagBadge(text: "\(group.foodCount) food") }
                    if group.childCount > 0 { TagBadge(text: "\(group.childCount) child") }
                    if group.isSpotRegistration { TagBadge(text: "Spot") }
                }
            }

            Spacer()

            if group.isFullyCheckedIn {
                Label("Checked in", systemImage: "checkmark.circle.fill")
                    .labelStyle(.iconOnly)
                    .font(.title2)
                    .foregroundStyle(.green)
                    .accessibilityLabel("Checked in")
            } else {
                Button(group.isPartlyCheckedIn ? "Check in rest" : "Check in", action: onCheckIn)
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Detail Sheet

/// Every ticket of one registration, with check-in / undo for all of them.
private struct RegistrationCheckInSheet: View {
    @Environment(DeskStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    let registrationID: String

    /// Read live from the store, so the sheet reflects the latest state.
    private var group: EventRegistrationGroup? {
        store.registrations.first { $0.registrationid == registrationID }
    }

    var body: some View {
        NavigationStack {
            List {
                if let group {
                    Section {
                        LabeledContent("Name", value: group.name)
                        LabeledContent("Registration", value: group.registrationid)
                        if let email = group.email {
                            LabeledContent("Email", value: email)
                        }
                        LabeledContent("Checked in", value: "\(group.checkedInCount) of \(group.visitors.count)")
                    }

                    Section("Tickets") {
                        ForEach(group.visitors) { visitor in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ticket #\(visitor.visitorid)")
                                        .font(.body.monospaced())
                                    HStack(spacing: 6) {
                                        FoodBadge(kind: visitor.foodKind)
                                        if let type = visitor.visit_type { TagBadge(text: type) }
                                        if visitor.child { TagBadge(text: "Child") }
                                    }
                                }
                                Spacer()
                                Image(systemName: visitor.completed ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(visitor.completed ? .green : .secondary)
                                    .accessibilityLabel(visitor.completed ? "Checked in" : "Not checked in")
                            }
                        }
                    }

                    Section {
                        if !group.isFullyCheckedIn {
                            Button {
                                Task {
                                    await store.setCheckedIn(group, true)
                                    dismiss()
                                }
                            } label: {
                                Label("Check in all \(group.visitors.count)", systemImage: "checkmark.circle.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                            .listRowInsets(EdgeInsets())
                        }
                        if group.checkedInCount > 0 {
                            Button("Undo check-in", role: .destructive) {
                                Task { await store.setCheckedIn(group, false) }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView("Registration Not Found", systemImage: "questionmark.circle")
                }
            }
            .navigationTitle("Check In")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

#Preview {
    WelcomeDeskView()
        .environment(DeskStore())
}
