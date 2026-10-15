//
//  DeskComponents.swift
//  RNBA Admin
//
//  Small views shared by the Overview, Welcome Desk and Food Desk tabs.
//

import SwiftUI

// MARK: - Event Picker

/// Selected event name and date at the top of each tab. Tapping it opens
/// the event list, so the event can be switched right where you search.
struct EventHeader: View {
    @Environment(DeskStore.self) private var store

    var body: some View {
        @Bindable var store = store
        Menu {
            Picker("Event", selection: $store.selectedEventID) {
                ForEach(store.events) { event in
                    VStack(alignment: .leading) {
                        Text(event.name)
                        Text(event.subtitle)
                    }
                    .tag(Optional(event.eventid))
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(store.selectedEvent?.name ?? "Choose an event")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    if let subtitle = store.selectedEvent?.subtitle, !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                Spacer()
                Label("Change event", systemImage: "chevron.up.chevron.down")
                    .labelStyle(.iconOnly)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.tint)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .accessibilityLabel("Event: \(store.selectedEvent?.name ?? "none")")
        .accessibilityHint("Double-tap to choose a different event")
    }
}

// MARK: - Badges

/// Veg / Non-Veg / Food / No food tag.
struct FoodBadge: View {
    let kind: FoodKind

    var body: some View {
        Label(kind.label, systemImage: icon)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(color)
            .background(color.opacity(0.12), in: Capsule())
    }

    private var icon: String {
        switch kind {
        case .veg: return "leaf.fill"
        case .nonVeg: return "fork.knife"
        case .unspecified: return "fork.knife"
        case .none: return "minus.circle"
        }
    }

    private var color: Color {
        switch kind {
        case .veg: return .green
        case .nonVeg: return .red
        case .unspecified: return .orange
        case .none: return .secondary
        }
    }
}

/// Small grey capsule, e.g. "Child" or "Member".
struct TagBadge: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.caption.weight(.medium))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .foregroundStyle(.secondary)
            .background(Color(.systemGray5), in: Capsule())
    }
}

// MARK: - Errors

extension View {
    /// Shows the store's error message as an alert.
    func deskErrorAlert(_ store: DeskStore) -> some View {
        alert(
            "Something went wrong",
            isPresented: Binding(
                get: { store.errorMessage != nil },
                set: { if !$0 { store.errorMessage = nil } }
            )
        ) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(store.errorMessage ?? "")
        }
    }
}
