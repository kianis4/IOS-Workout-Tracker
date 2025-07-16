// Features/Today/WeightTrackingView.swift
import SwiftUI
import SwiftData
import Charts

struct WeightTrackingView: View {
    @Environment(\.modelContext) private var context
    let selectedDate: Date
    @Query private var weightLogs: [BodyWeightRecord]
    @State private var showingWeightEntry = false
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        
        // Create query predicate for the selected date's weight log
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
                // Show today's logged weight
                WeightDisplayCard(weightLog: weightLog) {
                    showingWeightEntry = true
                }
            } else {
                // Show prompt to log weight
                WeightEntryPromptCard {
                    showingWeightEntry = true
                }
            }
        }
        .padding(.vertical)
        .sheet(isPresented: $showingWeightEntry) {
            WeightEntrySheet(
                date: selectedDate,
                existingLog: weightLogs.first
            )
        }
    }
}

struct WeightDisplayCard: View {
    let weightLog: BodyWeightRecord
    let editAction: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(String(format: "%.1f", weightLog.weight)) kg")
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
                    Text("Log today's weight")
                        .font(.headline)
                    
                    Text("Track your progress with daily weigh-ins")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

struct WeightEntrySheet: View {
    let date: Date
    let existingLog: BodyWeightRecord?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    
    @State private var weight: Double
    @State private var notes: String = ""
    
    init(date: Date, existingLog: BodyWeightRecord? = nil) {
        self.date = date
        self.existingLog = existingLog
        
        // Get current weight from user profile or default to previous weight or 70.0
        let startingWeight = existingLog?.weight ?? 70.0
        self._weight = State(initialValue: startingWeight)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        Text("Weight")
                        Spacer()
                        TextField("Weight in kg", value: $weight, format: .number)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                        Text("kg")
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
        if let existing = existingLog {
            // Update existing log
            existing.weight = weight
        } else {
            // Create new log
            let newLog = BodyWeightRecord(date: date, weight: weight)
            context.insert(newLog)
        }
        
        // Update user profile's current weight
        updateUserProfile()
        
        // Save and dismiss
        try? context.save()
        dismiss()
    }
    
    private func deleteEntry() {
        if let existing = existingLog {
            context.delete(existing)
            try? context.save()
        }
        dismiss()
    }
    
    private func updateUserProfile() {
        do {
            let descriptor = FetchDescriptor<UserProfile>()
            let profiles = try context.fetch(descriptor)
            
            if let profile = profiles.first {
                profile.currentWeight = weight
            }
            
            try? context.save()
        } catch {
            print("Error updating user profile: \(error)")
        }
    }
}