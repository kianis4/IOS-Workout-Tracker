//
//  ExerciseLogSheetView.swift
//  OverloadPT
//
//  Created by Suleyman Kianchi on 2025-06-17.
//

import SwiftUI
import SwiftData
import Combine
struct ExerciseLogSheetView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    let exercise: Exercise
    let selectedDate: Date
    let progressionData: ProgressionData? // ADD THIS PARAMETER

    @State private var existingSets: [SetEntry] = []
    @State private var sets: [SetEntryViewModel] = []
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Show the date being logged
                VStack(spacing: 4) {
                    Text("Logging for")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(selectedDate.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .padding(.top, 8)

                ExerciseHeaderView(
                    targetSets: exercise.targetSets,
                    targetReps: exercise.targetReps,
                    existingCount: existingSets.count,
                    addedCount: sets.count
                )

                List {
                    LogSetsSectionView(
                        sets: $sets,
                        targetSets: exercise.targetSets,
                        addDefaultSet: addDefaultSet
                    )
                    HistorySectionView(
                        existingSets: existingSets,
                        reuseAction: reusePreviousSets
                    )
                }
                .listStyle(.insetGrouped)
            }
            .navigationTitle("Log \(exercise.name)")
            .navigationBarTitleDisplayMode(.inline)
            .applyLogToolbar(dismiss: dismiss, saveDisabled: false, saveAction: saveWorkout)
            .alert("Changes Saved", isPresented: $showAlert) {
                Button("OK") { dismiss() }
            } message: {
                if sets.isEmpty {
                    Text("All sets have been removed for \(selectedDate.formatted(date: .abbreviated, time: .omitted)).")
                } else {
                    Text("Your workout for \(selectedDate.formatted(date: .abbreviated, time: .omitted)) has been logged successfully.")
                }
            }
            .onAppear {
                loadExistingSets()
                if sets.isEmpty {
                    if !existingSets.isEmpty {
                        // Prefill to edit previous sets
                        sets = existingSets.map {
                            SetEntryViewModel(reps: $0.reps, weight: $0.weight)
                        }
                    } else {
                        initializeSets()
                    }
                }
            }
        }
    }

    // Update this method to use selectedDate instead of .now
    private func loadExistingSets() {
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: selectedDate) // CHANGED: use selectedDate
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
            let descriptor = FetchDescriptor<SetEntry>()
            let allSets = try context.fetch(descriptor)
            existingSets = allSets.filter { set in
                set.exercise.id == exercise.id &&
                set.date >= startOfDay &&
                set.date < endOfDay
            }.sorted(by: { $0.date > $1.date })
        } catch {
            print("Error loading sets: \(error)")
        }
    }

    // Update this method to save with selectedDate
    private func saveWorkout() {
        // First, delete all existing sets for this date for this exercise
        for existingSet in existingSets {
            context.delete(existingSet)
        }
        
        // Then save the new sets with the selectedDate
        for set in sets {
            let entry = SetEntry(
                exercise: exercise,
                weight: set.weight,
                reps: set.reps,
                date: selectedDate // CHANGED: use selectedDate instead of default .now
            )
            context.insert(entry)
        }

        // Try to save context
        do {
            try context.save()
            showAlert = true
        } catch {
            print("Error saving sets: \(error)")
        }
    }

    // Keep all your other methods the same
    private func initializeSets() {
        addDefaultSet()
    }

    private func addDefaultSet() {
        // Use progression data for weight if available, otherwise use previous set weight
        let recommendedWeight = progressionData?.recommendedWeight ?? sets.last?.weight ?? 0
        sets.append(SetEntryViewModel(reps: exercise.targetReps, weight: recommendedWeight))
    }

    private func reusePreviousSets() {
        for s in existingSets {
            sets.append(SetEntryViewModel(reps: s.reps, weight: s.weight))
        }
    }
}

// MARK: - Toolbar Extension

private extension View {
    @ViewBuilder
    func applyLogToolbar(dismiss: DismissAction, saveDisabled: Bool, saveAction: @escaping () -> Void) -> some View {
        if #available(iOS 17.0, *) {
            self.toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveAction() }
                }
            }
        } else {
            self
        }
    }
}

// MARK: - Subviews

struct ExerciseHeaderView: View {
    let targetSets: Int
    let targetReps: Int
    let existingCount: Int
    let addedCount: Int

    // Compute progress outside the body
    private var totalDone: Int { existingCount + addedCount }
    private var progressFraction: Double {
        guard targetSets > 0 else { return 0 }
        return min(Double(totalDone) / Double(targetSets), 1.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 24) {
                VStack {
                    Text("\(targetSets)")
                        .font(.title).fontWeight(.bold)
                    Text("Target Sets")
                        .font(.caption).foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(targetReps)")
                        .font(.title).fontWeight(.bold)
                    Text("Target Reps")
                        .font(.caption).foregroundStyle(.secondary)
                }
                VStack {
                    Text("\(existingCount)")
                        .font(.title).fontWeight(.bold)
                        .foregroundColor(existingCount == 0 ? .primary : .green)
                    Text("Sets Done")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)

            ProgressView(value: progressFraction)
                .tint(.green)
                .padding(.horizontal)
                .padding(.bottom, 4)
        }
        .padding(.bottom, 0)
        .background(Color(.systemGroupedBackground))
    }
}


/// Simplified to avoid internal compiler issues.
struct LogSetsSectionView: View {
    @Binding var sets: [SetEntryViewModel]
    let targetSets: Int
    let addDefaultSet: () -> Void

    var body: some View {
        Section(header: sectionHeader) {
            // List each existing set with the full row view
            ForEach(sets.indices, id: \.self) { index in
                // Use a helper method to remove, avoiding inline complex closures
                SetRowView(
                    index: index,
                    set: $sets[index],
                    onDelete: { removeSet(at: index) }
                )
            }
            // Add Set button
            Button(action: addDefaultSet) {
                HStack {
                    Spacer()
                    Label("Add Set", systemImage: "plus")
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .padding(.vertical, 8)
        }
    }

    /// Header view for the section, moved into its own var
    private var sectionHeader: some View {
        HStack {
            Text("Log Sets")
            Spacer()
            if !sets.isEmpty {
                Text("\(sets.count) of \(targetSets) sets")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// Remove a set at given index with animation
    private func removeSet(at index: Int) {
        withAnimation {
            sets.remove(at: index)
        }
    }
}

/// Section showing previous sets (history), with reuse button
struct HistorySectionView: View {
    let existingSets: [SetEntry]
    let reuseAction: () -> Void

    var body: some View {
        Section(header: Text("History")) {
            if existingSets.isEmpty {
                Text("No previous sets today.")
                    .font(.caption).foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(existingSets) { set in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            if set.weight > 0 {
                                Text("\(Int(set.weight))kg × \(set.reps) reps")
                                    .font(.subheadline)
                            } else {
                                Text("\(set.reps) reps")
                                    .font(.subheadline)
                            }
                            Spacer(minLength: 0)
                            Text(set.date.formatted(date: .omitted, time: .shortened))
                                .font(.caption2).foregroundStyle(.tertiary)
                        }
                    }
                    Button("Reuse previous sets") {
                        reuseAction()
                    }
                    .font(.caption)
                    .padding(.top, 4)
                }
            }
        }
    }
}

/// Row view for a single set entry: weight TextField, reps Stepper, delete.
struct SetRowView: View {
    let index: Int
    @Binding var set: SetEntryViewModel
    let onDelete: () -> Void

    var body: some View {
        HStack {
            // Set number badge
            Text("SET \(index + 1)")
                .font(.caption).fontWeight(.semibold)
                .padding(.vertical, 2).padding(.horizontal, 6)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(4)
                .frame(width: 52)

            // Weight input
            HStack(spacing: 0) {
                TextField("", value: $set.weight, format: .number)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 50)
                    .textFieldStyle(.roundedBorder)
                    .font(.headline)
                Text("kg")
                    .font(.caption).foregroundStyle(.secondary)
                    .frame(width: 24, alignment: .leading)
            }
            .frame(width: 80)

            // Reps stepper
            Stepper(value: $set.reps, in: 1...50) {
                HStack(spacing: 2) {
                    Text("\(set.reps)")
                        .font(.headline)
                    Text("reps")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 0)

            // Delete button
            Button(action: onDelete) {
                Image(systemName: "xmark")
                    .foregroundColor(.red)
                    .font(.caption)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
        .onReceive(Just(set)) { newValue in
            // Keep weight >= 0
            if newValue.weight < 0 {
                set.weight = 0
            }
            // Keep reps >= 1
            if newValue.reps < 1 {
                set.reps = 1
            }
        }
    }
}

struct SetEntryViewModel: Identifiable, Equatable {
    var id = UUID()
    var reps: Int
    var weight: Double

    init(reps: Int, weight: Double = 0) {
        self.reps = reps
        self.weight = weight
    }

    static func == (lhs: SetEntryViewModel, rhs: SetEntryViewModel) -> Bool {
        lhs.id == rhs.id && lhs.reps == rhs.reps && lhs.weight == rhs.weight
    }
}

struct ProgressionData {
    let lastWeight: Double
    let recommendedWeight: Double
    let lastWorkoutDate: Date
    let daysAgo: Int
}
