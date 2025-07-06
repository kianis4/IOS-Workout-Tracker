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

    // MARK: UI
    var body: some View {
        Form {
            // 1️⃣  weekday picker
            Section("Workout Days") {
                WeekdayToggleRow(selected: $split.workoutDays)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            // 2️⃣  editable day-template list
            // SplitDetailView.swift - Update the day templates section
            Section("Day Templates") {
                ForEach(split.days) { day in
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
        .navigationBarItems(trailing: EditButton())          // ← Edit mode
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Reset Order") { resetToBalancedOrder() }
            }
        }
    }

    // MARK: - Edit helpers
    private func moveDay(from source: IndexSet, to destination: Int) {
        var copy = split.days
        copy.move(fromOffsets: source, toOffset: destination)
        split.days = copy                               // persists order
    }

    private func resetToBalancedOrder() {
        split.days.sort { $0.title < $1.title }         // simple demo rule
    }

    // MARK: - Computed schedule helpers
    private var resolvedSchedule: [(weekday: Int, day: SplitDay)] {
        let sortedDays = split.days
        let weekdays   = split.workoutDays.sorted()
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
        case "push":  "Chest · Shoulders · Triceps"
        case "pull":  "Back · Biceps"
        case "legs":  "Quads · Hamstrings · Glutes"
        case "upper": "Chest · Back · Shoulders · Arms"
        case "lower": "Quads · Hamstrings · Glutes · Calves"
        default:       nil
        }
    }
}

#Preview {
    // in-memory preview
    let c = try! ModelContainer(
        for: WorkoutSplit.self, SplitDay.self,
        configurations: .init(isStoredInMemoryOnly: true)
    )
    let demo = WorkoutSplit(name: "Push / Pull / Legs")
    demo.workoutDays = [1,3,5]
    demo.days = [SplitDay(title: "Push"),
                 SplitDay(title: "Pull"),
                 SplitDay(title: "Legs")]
    c.mainContext.insert(demo)

    return NavigationStack { SplitDetailView(split: demo) }
        .modelContainer(c)
}
