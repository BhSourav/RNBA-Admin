//
//  OverviewTabView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import SwiftUI

/// Live numbers for the selected event, plus walk-in registration.
struct OverviewTabView: View {
    @Environment(DeskStore.self) private var store
    @State private var showNewRegistration = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    EventHeader()
                        .padding(.horizontal)
                        .padding(.top)

                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        let groups = store.registrations
                        let visitors = store.visitors
                        let food = store.foodVisitors
                        let veg = food.filter { $0.foodKind == .veg }
                        let nonVeg = food.filter { $0.foodKind == .nonVeg }
                        let spot = groups.filter(\.isSpotRegistration)

                        InteractiveStatCard(
                            primaryTitle: "Registrations",
                            primaryValue: "\(groups.count)",
                            secondaryTitle: "Left to check in",
                            secondaryValue: "\(groups.filter { !$0.isFullyCheckedIn }.count)",
                            icon: "person.text.rectangle.fill",
                            color: .blue
                        )

                        InteractiveStatCard(
                            primaryTitle: "People",
                            primaryValue: "\(visitors.count)",
                            secondaryTitle: "Left to check in",
                            secondaryValue: "\(visitors.filter { !$0.completed }.count)",
                            icon: "person.3.fill",
                            color: .indigo
                        )

                        InteractiveStatCard(
                            primaryTitle: "Veg meals",
                            primaryValue: "\(veg.count)",
                            secondaryTitle: "Left to serve",
                            secondaryValue: "\(veg.filter { !$0.food_served }.count)",
                            icon: "leaf.fill",
                            color: .green
                        )

                        InteractiveStatCard(
                            primaryTitle: "Non-Veg meals",
                            primaryValue: "\(nonVeg.count)",
                            secondaryTitle: "Left to serve",
                            secondaryValue: "\(nonVeg.filter { !$0.food_served }.count)",
                            icon: "fork.knife",
                            color: .red
                        )

                        StatCard(
                            title: "Children",
                            value: "\(visitors.filter(\.child).count)",
                            icon: "figure.and.child.holdinghands",
                            color: .orange
                        )

                        StatCard(
                            title: "Spot registrations",
                            value: "\(spot.count)",
                            icon: "person.badge.plus",
                            color: .mint
                        )
                    }
                    .padding(.horizontal)

                    if let lastUpdated = store.lastUpdated {
                        Text("Updated \(lastUpdated.formatted(date: .omitted, time: .shortened)) · pull to refresh")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Button {
                        showNewRegistration = true
                    } label: {
                        Label("New Registration", systemImage: "person.badge.plus")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(store.selectedEvent == nil)
                    .padding(.horizontal)
                }
                .padding(.bottom)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Overview")
            .navigationBarTitleDisplayMode(.inline)
            .refreshable { await store.refreshVisitors() }
            .sheet(isPresented: $showNewRegistration) {
                NewRegistrationView()
            }
        }
    }
}

#Preview {
    OverviewTabView()
        .environment(DeskStore())
}
