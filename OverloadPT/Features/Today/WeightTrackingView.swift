//
//  WeightTrackingView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-07-14.
//
import SwiftUI
import SwiftData
import Charts

struct WeightTrackingView: View {
    @Environment(\.modelContext) private var context
    @Query private var userProfiles: [UserProfile]
    let selectedDate: Date
    @Query private var weightLogs: [BodyWeightRecord]
    @State private var showingWeightEntry = false
    
    private var userProfile: UserProfile? {
        userProfiles.first
    }
    
    private var massUnit: MassUnit {
        userProfile?.unit ?? .kg
    }
    
    private var unitSymbol: String {
        massUnit == .kg ? "kg" : "lbs"
    }
    
    private func formatWeight(_ weight: Double) -> String {
        let displayWeight = massUnit == .kg ? weight : weight * 2.20462
        return String(format: "%.1f", displayWeight)
    }
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = #Predicate<BodyWeightRecord> { log in
            log.date >= startOfDay && log.date < endOfDay
        }
        
        self._weightLogs = Query(filter: predicate, sort: [SortDescriptor(\.date, order: .reverse)])
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Body Weight")
                .font(.headline)
            
            if let weightLog = weightLogs.first {
                WeightDisplayCard(
                    weightLog: weightLog,
                    massUnit: massUnit,
                    unitSymbol: unitSymbol,
                    formatWeight: formatWeight
                ) {
                    showingWeightEntry = true
                }
            } else {
                WeightEntryPromptCard {
                    showingWeightEntry = true
                }
            }
        }
        .padding(.vertical)
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntrySheet(
                date: selectedDate,
                existingLog: weightLogs.first,
                massUnit: massUnit
            )
        }
    }
}

struct WeightDisplayCard: View {
    let weightLog: BodyWeightRecord
    let massUnit: MassUnit
    let unitSymbol: String
    let formatWeight: (Double) -> String
    let editAction: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(formatWeight(weightLog.weight)) \(unitSymbol)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(weightLog.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button(action: editAction) {
                Label("Edit", systemImage: "pencil")
                    .labelStyle(.iconOnly)
                    .padding(8)
                    .background(Color.blue.opacity(0.1))
                    .clipShape(Circle())
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct WeightEntryPromptCard: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Log your weight")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Text("Track your progress")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.blue)
            }
            .padding()
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct WeightEntrySheet: View {
    let date: Date
    let existingLog: BodyWeightRecord?
    let massUnit: MassUnit
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var displayWeight: Double
    @State private var notes: String = ""
    
    private var unitSymbol: String {
        massUnit == .kg ? "kg" : "lbs"
    }
    
    init(date: Date, existingLog: BodyWeightRecord? = nil, massUnit: MassUnit) {
        self.date = date
        self.existingLog = existingLog
        self.massUnit = massUnit
        
        let startingWeight = existingLog?.weight ?? 70.0
        let displayWeight = massUnit == .kg ? startingWeight : startingWeight * 2.20462
        self._displayWeight = State(initialValue: displayWeight)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("Weight", value: $displayWeight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text(unitSymbol)
                            .foregroundStyle(.secondary)
                    }
                }
                
                if existingLog != nil {
                    Section {
                        Button("Delete Entry", role: .destructive) {
                            deleteEntry()
                        }
                    }
                }
            }
            .navigationTitle(existingLog != nil ? "Edit Weight" : "Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveEntry() }
                }
            }
        }
        .presentationDetents([.height(300)])
        .presentationDragIndicator(.visible)
    }
    
    private func saveEntry() {
        // Convert display weight to kg for storage
        let weightInKg = massUnit == .kg ? displayWeight : displayWeight / 2.20462
        
        if let existing = existingLog {
            existing.weight = weightInKg
        } else {
            let newLog = BodyWeightRecord(date: date, weight: weightInKg)
            context.insert(newLog)
        }
        
        updateUserProfile(weightInKg: weightInKg)
        
        do {
            try context.save()
        } catch {
            print("Error saving weight: \(error)")
        }
        
        dismiss()
    }
    
    private func deleteEntry() {
        if let existing = existingLog {
            context.delete(existing)
            do {
                try context.save()
            } catch {
                print("Error deleting weight: \(error)")
            }
        }
        dismiss()
    }
    
    private func updateUserProfile(weightInKg: Double) {
        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try context.fetch(descriptor)
            
            if let profile = profiles.first {
                profile.currentWeight = weightInKg
            }
            
            try context.save()
        } catch {
            print("Error updating user profile: \(error)")
        }
    }
}
