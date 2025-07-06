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

    @State private var existingSets: [SetEntry] = []
    @State private var sets: [SetEntryViewModel] = []
    @State private var showAlert = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
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
            .applyLogToolbar(dismiss: dismiss, saveDisabled: sets.isEmpty, saveAction: saveWorkout)
            .alert("Changes Saved", isPresented: $showAlert) {
                Button("OK") { dismiss() }
            } message: {
                if sets.isEmpty {
                    Text("All sets have been removed for this exercise.")
                } else {
                    Text("Your workout has been logged successfully.")
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

    private func initializeSets() {
        // If no existing sets, add one default
        addDefaultSet()
    }

    private func addDefaultSet() {
        let previousWeight = sets.last?.weight ?? 0
        sets.append(SetEntryViewModel(reps: exercise.targetReps, weight: previousWeight))
    }

    private func reusePreviousSets() {
        for s in existingSets {
            sets.append(SetEntryViewModel(reps: s.reps, weight: s.weight))
        }
    }

    private func loadExistingSets() {
        do {
            let calendar = Calendar.current
            let today = calendar.startOfDay(for: .now)
            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
            let descriptor = FetchDescriptor<SetEntry>()
            let allSets = try context.fetch(descriptor)
            existingSets = allSets.filter { set in
                set.exercise.id == exercise.id &&
                set.date >= today &&
                set.date < tomorrow
            }.sorted(by: { $0.date > $1.date })
        } catch {
            print("Error loading sets: \(error)")
        }
    }
    private func saveWorkout() {
        // First, delete all existing sets for today for this exercise
        for existingSet in existingSets {
            context.delete(existingSet)
        }
        
        // Then save the new sets (if any)
        for set in sets {
            let entry = SetEntry(
                exercise: exercise,
                weight: set.weight,
                reps: set.reps
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
//    private func saveWorkout() {
//        // Delete old entries
//        for oldEntry in existingSets {
//            context.delete(oldEntry)
//        }
//        // Insert new/edited sets
//        for vm in sets {
//            let entry = SetEntry(
//                exercise: exercise,
//                weight: vm.weight,
//                reps: vm.reps
//            )
//            context.insert(entry)
//        }
//        do {
//            try context.save()
//            showAlert = true
//        } catch {
//            print("Error saving sets: \(error)")
//        }
//    }
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
////
////  ExerciseLogSheetView.swift
////  OverloadPT
////
////  Created by Suleyman Kianchi on 2025-06-17.
////
//
//import SwiftUI
//import SwiftData
//import Combine
//
//struct ExerciseLogSheetView: View {
//    @Environment(\.modelContext) private var context
//    @Environment(\.dismiss) private var dismiss
//    let exercise: Exercise
//
//    @State private var existingSets: [SetEntry] = []
//    @State private var sets: [SetEntryViewModel] = []
//    @State private var showAlert = false
//
//    var body: some View {
//        NavigationStack {
//            // Show only header for now
//            ExerciseHeaderView(
//                targetSets: exercise.targetSets,
//                targetReps: exercise.targetReps,
//                existingCount: existingSets.count,
//                addedCount: sets.count
//            )
//            .navigationTitle("Log \(exercise.name)")
//            .navigationBarTitleDisplayMode(.inline)
//            // No toolbar yet
//        }
//        .onAppear {
//            // For now, loadExistingSets so header displays something:
//            loadExistingSets()
//            // Also initialize sets so addedCount > 0 if desired
//            if sets.isEmpty {
//                initializeSets()
//            }
//        }
//    }
////    @Environment(\.modelContext) private var context
////    @Environment(\.dismiss) private var dismiss
////    let exercise: Exercise
////
////    @State private var existingSets: [SetEntry] = []
////    @State private var sets: [SetEntryViewModel] = []
////    @State private var showAlert = false
////
////    
////    var body: some View {
////        NavigationStack {
////            VStack(spacing: 0) {
////                ExerciseHeaderView(
////                    targetSets: exercise.targetSets,
////                    targetReps: exercise.targetReps,
////                    existingCount: existingSets.count,
////                    addedCount: sets.count
////                )
////                List {
////                    LogSetsSectionView(
////                        sets: $sets,
////                        targetSets: exercise.targetSets,
////                        addDefaultSet: addDefaultSet
////                    )
////                    HistorySectionView(
////                        existingSets: existingSets,
////                        reuseAction: reusePreviousSets
////                    )
////                }
////            }
////            .navigationTitle("Log \(exercise.name)")
////            .navigationBarTitleDisplayMode(.inline)
////            .applyLogToolbar(dismiss: dismiss, saveDisabled: sets.isEmpty, saveAction: saveWorkout)
////            .alert("Workout Saved", isPresented: $showAlert) {
////                Button("OK") { dismiss() }
////            } message: {
////                Text("Your workout has been logged successfully.")
////            }
////            .onAppear {
////                loadExistingSets()
////                if sets.isEmpty {
////                    initializeSets()
////                }
////            }
////        }
////    }
//
//    // MARK: - Helper Methods
//
//    private func initializeSets() {
//        if existingSets.isEmpty {
//            let remainingSets = max(0, exercise.targetSets - existingSets.count)
//            for _ in 0..<min(remainingSets, 1) {
//                addDefaultSet()
//            }
//        }
//    }
//
//    private func addDefaultSet() {
//        let previousWeight = sets.last?.weight ?? 0
//        sets.append(SetEntryViewModel(reps: exercise.targetReps, weight: previousWeight))
//    }
//
//    private func reusePreviousSets() {
//        for s in existingSets {
//            sets.append(SetEntryViewModel(reps: s.reps, weight: s.weight))
//        }
//    }
//
//    private func loadExistingSets() {
//        do {
//            let calendar = Calendar.current
//            let today = calendar.startOfDay(for: .now)
//            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
//
//            let descriptor = FetchDescriptor<SetEntry>()
//            let allSets = try context.fetch(descriptor)
//            existingSets = allSets.filter { set in
//                set.exercise.id == exercise.id &&
//                set.date >= today &&
//                set.date < tomorrow
//            }.sorted(by: { $0.date > $1.date })
//        } catch {
//            print("Error loading sets: \(error)")
//        }
//    }
//
//    private func saveWorkout() {
//        for vm in sets {
//            let entry = SetEntry(
//                exercise: exercise,
//                weight: vm.weight,
//                reps: vm.reps
//            )
//            context.insert(entry)
//        }
//        do {
//            try context.save()
//            showAlert = true
//        } catch {
//            print("Error saving sets: \(error)")
//        }
//    }
//}
//
//// MARK: - Toolbar Extension
//
//private extension View {
//    @ViewBuilder
//    func applyLogToolbar(dismiss: DismissAction, saveDisabled: Bool, saveAction: @escaping () -> Void) -> some View {
//        if #available(iOS 17.0, *) {
//            self.toolbar {
//                ToolbarItem(placement: .cancellationAction) {
//                    Button("Cancel") { dismiss() }
//                }
//                ToolbarItem(placement: .confirmationAction) {
//                    Button("Save") { saveAction() }
//                        .disabled(saveDisabled)
//                }
//            }
//        } else {
//            self
//        }
//    }
//}
//
//// MARK: - Subviews
//
//struct ExerciseHeaderView: View {
//    let targetSets: Int
//    let targetReps: Int
//    let existingCount: Int
//    let addedCount: Int
//
//    var body: some View {
//        VStack(spacing: 12) {
//            HStack(spacing: 24) {
//                VStack {
//                    Text("\(targetSets)")
//                        .font(.title).fontWeight(.bold)
//                    Text("Target Sets")
//                        .font(.caption).foregroundStyle(.secondary)
//                }
//                VStack {
//                    Text("\(targetReps)")
//                        .font(.title).fontWeight(.bold)
//                    Text("Target Reps")
//                        .font(.caption).foregroundStyle(.secondary)
//                }
//                VStack {
//                    Text("\(existingCount)")
//                        .font(.title).fontWeight(.bold)
//                        .foregroundColor(existingCount == 0 ? .primary : .green)
//                    Text("Sets Done")
//                        .font(.caption).foregroundStyle(.secondary)
//                }
//            }
//            .frame(maxWidth: .infinity)
//            .padding(.vertical, 12)
//
//            let progress = min(Double(existingCount + addedCount) / Double(max(targetSets, 1)), 1.0)
//            ProgressView(value: progress)
//                .tint(.green)
//                .padding(.horizontal)
//                .padding(.bottom, 4)
//        }
//        .padding()
//        .background(Color(.systemGroupedBackground))
//    }
//}
//
//struct LogSetsSectionView: View {
//    var body: some View {
//        Text("LogSetsSectionView stub")
//    }
////    @Binding var sets: [SetEntryViewModel]
////    let targetSets: Int
////    let addDefaultSet: () -> Void
////
////    var body: some View {
////        Section(header: header) {
////            ForEach(sets.indices, id: \.self) { index in
////                SetRowView(
////                    index: index,
////                    set: $sets[index],
////                    onDelete: {
////                        withAnimation {
////                            sets.remove(at: index)
////                        }
////                    }
////                )
////            }
////            Button {
////                withAnimation { addDefaultSet() }
////            } label: {
////                Label("Add Set", systemImage: "plus")
////                    .frame(maxWidth: .infinity, alignment: .center)
////                    .contentShape(Rectangle())
////            }
////            .buttonStyle(.plain)
////            .padding(.vertical, 8)
////        }
////    }
//
////    private var header: some View {
////        HStack {
////            Text("Log Sets")
////            Spacer()
////            if !sets.isEmpty {
////                Text("\(sets.count) of \(targetSets) sets")
////                    .font(.caption).foregroundStyle(.secondary)
////            }
////        }
////    }
//}
//
//struct HistorySectionView: View {
//    let existingSets: [SetEntry]
//    let reuseAction: () -> Void
//
//    var body: some View {
//        Text("HistorySectionView stub")
//    }
////    let existingSets: [SetEntry]
////    let reuseAction: () -> Void
////
////    var body: some View {
////        Section(header: Text("History")) {
////            if existingSets.isEmpty {
////                Text("This is your first time logging this exercise today.")
////                    .font(.caption).foregroundStyle(.secondary)
////            } else {
////                VStack(alignment: .leading, spacing: 8) {
////                    Text("Today's previous sets")
////                        .font(.caption).foregroundStyle(.secondary)
////                    ForEach(existingSets) { set in
////                        HStack {
////                            Image(systemName: "checkmark.circle.fill")
////                                .foregroundColor(.green)
////                                .font(.caption)
////                            if set.weight > 0 {
////                                Text("\(Int(set.weight))kg × \(set.reps) reps")
////                                    .font(.subheadline)
////                            } else {
////                                Text("\(set.reps) reps")
////                                    .font(.subheadline)
////                            }
////                            Spacer(minLength: 0)
////                            Text(set.date.formatted(date: .omitted, time: .shortened))
////                                .font(.caption2).foregroundStyle(.tertiary)
////                        }
////                    }
////                    Button("Add these sets again") {
////                        reuseAction()
////                    }
////                    .font(.caption)
////                    .padding(.top, 4)
////                }
////            }
////        }
////    }
//}
//
//struct SetRowView: View {
//    var body: some View {
//        Text("SetRowView stub")
//    }
////    let index: Int
////    @Binding var set: SetEntryViewModel
////    let onDelete: () -> Void
////
////    var body: some View {
////        HStack {
////            Text("SET \(index + 1)")
////                .font(.caption).fontWeight(.semibold)
////                .padding(.vertical, 2).padding(.horizontal, 6)
////                .background(Color.gray.opacity(0.2))
////                .cornerRadius(4)
////                .frame(width: 52)
////
////            HStack(spacing: 0) {
////                TextField("", value: $set.weight, format: .number)
////                    .keyboardType(.decimalPad)
////                    .multilineTextAlignment(.trailing)
////                    .frame(width: 50)
////                    .textFieldStyle(.roundedBorder)
////                    .font(.headline)
////                Text("kg")
////                    .font(.caption).foregroundStyle(.secondary)
////                    .frame(width: 24, alignment: .leading)
////            }
////            .frame(width: 80)
////
////            Stepper(value: $set.reps, in: 1...50) {
////                HStack(spacing: 2) {
////                    Text("\(set.reps)")
////                        .font(.headline)
////                    Text("reps")
////                        .font(.caption).foregroundStyle(.secondary)
////                }
////            }
////
////            Spacer(minLength: 0)
////
////            Button(action: onDelete) {
////                Image(systemName: "xmark")
////                    .foregroundColor(.red)
////                    .font(.caption)
////            }
////            .buttonStyle(.plain)
////        }
////        .padding(.vertical, 4)
////        .onReceive(Just(set)) { newValue in
////            if newValue.weight < 0 { set.weight = 0 }
////            if newValue.reps < 1 { set.reps = 1 }
////        }
////    }
//}
//
//struct SetEntryViewModel: Identifiable, Equatable {
//    var id = UUID()
//    var reps: Int
//    var weight: Double
//
//    init(reps: Int, weight: Double = 0) {
//        self.reps = reps
//        self.weight = weight
//    }
//
//    static func == (lhs: SetEntryViewModel, rhs: SetEntryViewModel) -> Bool {
//        lhs.id == rhs.id && lhs.reps == rhs.reps && lhs.weight == rhs.weight
//    }
//}
