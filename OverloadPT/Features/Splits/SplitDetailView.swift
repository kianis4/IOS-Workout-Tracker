//
//  SplitDetailView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//

import SwiftUI
import SwiftData

/// Shows one workout-split template and lets the user change weekday plan
/// and the order of template days (Push / Pull / …).
struct SplitDetailView: View {
    @Bindable var split: WorkoutSplit        // SwiftData-aware
    @State private var editMode = EditMode.inactive

    // MARK: UI
    var body: some View {
        Form {
            // 1️⃣  weekday picker
            Section("Workout Days") {
                WeekdayToggleRow(selected: $split.workoutDays)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            // 2️⃣  editable day-template list
            Section("Day Templates") {
                ForEach(sortedDays) { day in
                    NavigationLink {
                        SplitDayExercisesView(splitDay: day)
                    } label: {
                        HStack {
                            Text(day.title)
                            Spacer()
                            Text("\(day.exercises.count) exercises")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }
                    }
                }
                .onMove(perform: moveDay)
                .onDelete(perform: editMode == .active ? deleteDay : nil)
            }

            // 3️⃣  resolved calendar view
            Section("Planned Schedule") {
                ForEach(resolvedSchedule, id: \.weekday) { item in
                    VStack(alignment: .leading, spacing: 2) {
                        Text("\(weekdayName(item.weekday)):  \(item.day.title)")
                            .fontWeight(.semibold)
                        if let muscles = musclesFor(title: item.day.title) {
                            Text(muscles)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .navigationTitle(split.name)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                EditButton()
            }
            ToolbarItem(placement: .bottomBar) {
                Button("Reset Order") { resetToBalancedOrder() }
            }
        }
    }

    // MARK: - Computed properties
    private var sortedDays: [SplitDay] {
        split.days.sorted { $0.order < $1.order }
    }

    // MARK: - Edit helpers
    private func moveDay(from source: IndexSet, to destination: Int) {
        withAnimation {
            var sortedDays = self.sortedDays
            sortedDays.move(fromOffsets: source, toOffset: destination)
            
            // Update the order property for all days
            for (index, day) in sortedDays.enumerated() {
                day.order = index
            }
        }
    }

    private func deleteDay(at offsets: IndexSet) {
        withAnimation {
            let sortedDays = self.sortedDays
            for index in offsets {
                if index < sortedDays.count {
                    let dayToDelete = sortedDays[index]
                    split.days.removeAll { $0.id == dayToDelete.id }
                }
            }
            
            // Reorder remaining days
            let remainingDays = self.sortedDays
            for (index, day) in remainingDays.enumerated() {
                day.order = index
            }
        }
    }

    private func resetToBalancedOrder() {
        withAnimation {
            let sortedByTitle = split.days.sorted { $0.title < $1.title }
            for (index, day) in sortedByTitle.enumerated() {
                day.order = index
            }
        }
    }

    // MARK: - Computed schedule helpers
    private var resolvedSchedule: [(weekday: Int, day: SplitDay)] {
        let sortedDays = self.sortedDays
        let weekdays = split.workoutDays.sorted()
        guard !sortedDays.isEmpty else { return [] }

        return weekdays.enumerated().map { idx, w in
            (w, sortedDays[idx % sortedDays.count])
        }
    }

    private func weekdayName(_ index: Int) -> String {
        Calendar.current.shortWeekdaySymbols[index]
    }

    private func musclesFor(title: String) -> String? {
        switch title.lowercased() {
        case "push":  return "Chest · Shoulders · Triceps"
        case "pull":  return "Back · Biceps"
        case "legs":  return "Quads · Hamstrings · Glutes"
        case "upper": return "Chest · Back · Shoulders · Arms"
        case "lower": return "Quads · Hamstrings · Glutes · Calves"
        default:      return nil
        }
    }
}
