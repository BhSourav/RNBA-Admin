//
//  NewRegistrationView.swift
//  RNBA Admin
//
//  Created by Sourav Bhattacharjee on 14.10.25.
//

import SwiftUI

/// Walk-in registration for the selected event. The database generates the
/// registration ID ("APP-…", see wp-sync/sql/006).
struct NewRegistrationView: View {
    @Environment(DeskStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var walkIn = WalkInRegistration()
    @State private var visitTypes: [VisitTypeRow] = []
    @State private var paymentTypes: [PaymentTypeRow] = []
    @State private var isSaving = false
    @State private var errorMessage: String?
    @State private var savedRegistrationID: String?

    private let service = DeskService()

    /// Distinct Visit_Type names, e.g. Member, Visitor, Performer.
    private var categories: [String] {
        var seen = Set<String>()
        return visitTypes.map(\.name).filter { seen.insert($0).inserted }
    }

    private var isFormValid: Bool {
        !walkIn.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !(walkIn.phone.isEmpty && walkIn.email.isEmpty && walkIn.mobile.isEmpty)
            && !walkIn.persons.isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Event", value: store.selectedEvent?.name ?? "None")
                } footer: {
                    Text("Registers for the event selected in the app. To change it, cancel and tap the event name at the top of the tab.")
                }

                Section("Name") {
                    TextField("Name", text: $walkIn.name)
                        .textContentType(.name)
                }

                Section {
                    ForEach($walkIn.persons) { $person in
                        PersonEditor(person: $person, categories: categories)
                    }
                    .onDelete { walkIn.persons.remove(atOffsets: $0) }

                    Button {
                        walkIn.persons.append(WalkInPerson())
                    } label: {
                        Label("Add person", systemImage: "plus.circle")
                    }
                } header: {
                    Text("People (\(walkIn.persons.count))")
                } footer: {
                    Text("Swipe left on a person to remove them.")
                }

                Section {
                    TextField("Phone", text: $walkIn.phone)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Mobile", text: $walkIn.mobile)
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                    TextField("Email", text: $walkIn.email)
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                    TextField("Address", text: $walkIn.address, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Contact")
                } footer: {
                    Text("A phone, mobile or email is required.")
                }

                // Payment_Type is empty in RNBA_Prod for now; the section
                // appears once payment types are added there.
                if !paymentTypes.isEmpty {
                    Section("Payment") {
                        Picker("Payment type", selection: $walkIn.paymentTypeID) {
                            Text("None").tag(Int?.none)
                            ForEach(paymentTypes) { Text($0.name).tag(Optional($0.paymenttypeid)) }
                        }
                        if walkIn.paymentTypeID != nil {
                            TextField("Amount", value: $walkIn.paymentAmount, format: .number)
                                .keyboardType(.decimalPad)
                            TextField("Remarks", text: $walkIn.paymentRemarks)
                        }
                    }
                }

                Section {
                    Toggle("Check in now", isOn: $walkIn.checkInNow)
                }
            }
            .navigationTitle("New Registration")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") { Task { await save() } }
                            .disabled(!isFormValid || store.selectedEvent == nil)
                    }
                }
            }
            .interactiveDismissDisabled(isSaving)
            .task { await loadLookups() }
            .alert("Couldn't Save", isPresented: Binding(
                get: { errorMessage != nil },
                set: { if !$0 { errorMessage = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage ?? "")
            }
            .alert("Registered", isPresented: Binding(
                get: { savedRegistrationID != nil },
                set: { if !$0 { savedRegistrationID = nil; dismiss() } }
            )) {
                Button("OK") {}
            } message: {
                Text("Registration \(savedRegistrationID ?? "") was created.")
            }
        }
    }

    private func loadLookups() async {
        do {
            visitTypes = try await service.fetchVisitTypes()
            paymentTypes = try await service.fetchPaymentTypes()
        } catch {
            errorMessage = "Couldn't load visit types: \(error.localizedDescription)"
        }
    }

    private func save() async {
        guard let eventID = store.selectedEventID else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let id = try await service.createWalkIn(walkIn, eventID: eventID, visitTypes: visitTypes)
            await store.refreshVisitors()
            savedRegistrationID = id
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

// MARK: - Person Editor

private struct PersonEditor: View {
    @Binding var person: WalkInPerson
    let categories: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Picker("Type", selection: $person.category) {
                ForEach(categories, id: \.self) { Text($0).tag($0) }
            }
            Picker("Food", selection: $person.food) {
                ForEach(WalkInFood.allCases) { Text($0.label).tag($0) }
            }
            .pickerStyle(.segmented)
            Toggle("Child", isOn: $person.isChild)
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    NewRegistrationView()
        .environment(DeskStore())
}
