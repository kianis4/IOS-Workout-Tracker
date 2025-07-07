//
//  TodayView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-16.
//


import SwiftUI
import SwiftData

struct TodayView: View {
    @Query private var splits: [WorkoutSplit]
    @State private var selectedDate = Date()
    
    private var activeSplit: WorkoutSplit? {
        splits.first { $0.isActive }
    }
    
    private var dateDisplay: String {
        selectedDate.formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }
    
    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date selector
                DateScrollView(selectedDate: $selectedDate)
                
                if let split = activeSplit {
                    WorkoutForDayView(split: split, date: selectedDate)
                } else {
                    NoActiveSplitView()
                }
            }
            .navigationTitle(isToday ? "Today's Workout" : dateDisplay)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        selectedDate = Date()
                    } label: {
                        Label("Today", systemImage: "calendar.badge.clock")
                    }
                    .disabled(isToday)
                }
            }
        }
    }
}

struct DateScrollView: View {
    @Binding var selectedDate: Date
    let days = -3...7 // Range of days to display
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(days, id: \.self) { offset in
                        let date = Calendar.current.date(byAdding: .day, value: offset, to: Date()) ?? Date()
                        DateCell(date: date, isSelected: Calendar.current.isDate(date, inSameDayAs: selectedDate))
                            .id(offset)
                            .onTapGesture {
                                withAnimation {
                                    selectedDate = date
                                }
                            }
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 8)
            .background(Color(.systemGroupedBackground))
            .onAppear {
                proxy.scrollTo(0, anchor: .center)
            }
        }
    }
}

struct DateCell: View {
    let date: Date
    let isSelected: Bool
    private let calendar = Calendar.current
    
    var isToday: Bool {
        calendar.isDateInToday(date)
    }
    
    private var weekday: String {
        date.formatted(.dateTime.weekday(.abbreviated))
    }
    
    private var day: String {
        date.formatted(.dateTime.day())
    }
    
    var body: some View {
        VStack {
            Text(weekday)
                .font(.caption)
                .foregroundStyle(isSelected ? .white : .primary)
            
            Text(day)
                .font(.headline)
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .frame(width: 45, height: 62)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue : (isToday ? Color.blue.opacity(0.1) : Color(.secondarySystemGroupedBackground)))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isToday && !isSelected ? Color.blue : Color.clear, lineWidth: 1)
        )
    }
}

struct WorkoutForDayView: View {
    let split: WorkoutSplit
    let date: Date
    
    private var dayOfWeek: Int {
        // Get standard 0-6 format (Sunday=0)
        return Calendar.current.component(.weekday, from: date) - 1
    }
    
    private var isWorkoutDay: Bool {
        split.workoutDays.contains(dayOfWeek)
    }
    
    private var splitDayForToday: SplitDay? {
        guard isWorkoutDay, !split.days.isEmpty else { return nil }
        
        // Create an ordered list of workout days
        let orderedWorkoutDays = Array(split.workoutDays).sorted()
        
        // Find position of today's day of week in ordered workout days
        guard let position = orderedWorkoutDays.firstIndex(of: dayOfWeek) else { return nil }
        
        // Map to corresponding split day, using modulo to cycle through days
        let dayIndex = position % split.days.count
        return split.days[dayIndex]
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isWorkoutDay, let splitDay = splitDayForToday {
                    // Header info
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(splitDay.title)
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Spacer()
                            
                            Text(split.name)
                                .font(.subheadline)
                                .padding(6)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        if let description = musclesForDay(title: splitDay.title) {
                            Text(description)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemGroupedBackground))
                    .cornerRadius(12)
                    
                    // Exercises Section (placeholder for now)
                    WorkoutLogSection(splitDay: splitDay, selectedDate: date)
                } else {
                    RestDayView()
                }
            }
            .padding()
        }
    }
    
    private func musclesForDay(title: String) -> String? {
        switch title.lowercased() {
        case "push": return "Chest, Shoulders, Triceps"
        case "pull": return "Back, Biceps"
        case "legs": return "Quads, Hamstrings, Glutes"
        case "upper": return "Chest, Back, Shoulders, Arms"
        case "lower": return "Quads, Hamstrings, Glutes, Calves"
        case "chest & back": return "Chest, Back, Core"
        case "shoulders & arms": return "Shoulders, Biceps, Triceps"
        case "full body": return "All major muscle groups"
        default: return nil
        }
    }
}

struct WorkoutLogSection: View {
    let splitDay: SplitDay
    let selectedDate: Date
    @Environment(\.modelContext) private var context // Add this line
    @State private var showExercisePicker = false
    @State private var selectedExercise: Exercise?
    @State private var selectedProgressionData: ProgressionData?
    @State private var showLogSheet = false
    @State private var refreshTrigger = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Exercises")
                .font(.headline)
            
            if splitDay.exercises.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "dumbbell")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    
                    Text("No exercises added yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add Exercises", systemImage: "plus")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            } else {
                // Display exercises with log button
                ForEach(splitDay.exercises) { exercise in
                    Button {
                        // Load progression data before showing sheet
                        selectedProgressionData = loadProgressionData(for: exercise)
                        selectedExercise = exercise
                        showLogSheet = true
                    } label: {
                        ExerciseLogView(
                            exercise: exercise,
                            selectedDate: selectedDate
                        )
                        .contentShape(Rectangle())
                        .id("\(exercise.id)-\(refreshTrigger)")
                    }
                    .buttonStyle(.plain)
                }
                
                Button {
                    showExercisePicker = true
                } label: {
                    Label("Add Exercise", systemImage: "plus")
                }
                .padding(.top)
            }
        }
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView(splitDay: splitDay)
                .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $showLogSheet, onDismiss: {
            refreshTrigger.toggle()
        }) {
            if let exercise = selectedExercise {
                ExerciseLogSheetView(
                    exercise: exercise,
                    selectedDate: selectedDate,
                    progressionData: selectedProgressionData
                )
            }
        }
    }
    
    private func loadProgressionData(for exercise: Exercise) -> ProgressionData? {
        do {
            // Use the context from the environment instead of ModelContainer.shared
            let descriptor = FetchDescriptor<SetEntry>()
            let allSets = try context.fetch(descriptor)
            
            let currentDayStart = Calendar.current.startOfDay(for: selectedDate)
            let exerciseSets = allSets.filter { set in
                set.exercise.id == exercise.id &&
                Calendar.current.startOfDay(for: set.date) < currentDayStart
            }
            
            // Rest of the function remains unchanged
            let groupedByDay = Dictionary(grouping: exerciseSets) { set in
                Calendar.current.startOfDay(for: set.date)
            }
            
            let sortedDays = groupedByDay.keys.sorted(by: >)
            
            for day in sortedDays {
                guard let daySets = groupedByDay[day] else { continue }
                
                if daySets.count >= exercise.targetSets {
                    let weights = daySets.map { $0.weight }
                    let maxWeight = weights.max() ?? 0
                    
                    if maxWeight > 0 {
                        let daysAgo = Calendar.current.dateComponents([.day], from: day, to: currentDayStart).day ?? 0
                        let isLowerBody = exercise.muscle == .legs
                        let increment = isLowerBody ? 5.0 : 2.5
                        let recommendedWeight = maxWeight + increment
                        
                        return ProgressionData(
                            lastWeight: maxWeight,
                            recommendedWeight: recommendedWeight,
                            lastWorkoutDate: day,
                            daysAgo: daysAgo
                        )
                    }
                }
            }
            
            return nil
        } catch {
            print("Error loading progression data: \(error)")
            return nil
        }
    }
    // Helper function to load progression data
//    private func loadProgressionData(for exercise: Exercise) -> ProgressionData? {
//        // This is the same logic from ExerciseLogView
//        // We'll implement it here to get the progression data
//        do {
//            let context = splitDay.modelContext ?? ModelContext(ModelContainer.shared)
//            let descriptor = FetchDescriptor<SetEntry>()
//            let allSets = try context.fetch(descriptor)
//            
//            let currentDayStart = Calendar.current.startOfDay(for: selectedDate)
//            let exerciseSets = allSets.filter { set in
//                set.exercise.id == exercise.id &&
//                Calendar.current.startOfDay(for: set.date) < currentDayStart
//            }
//            
//            let groupedByDay = Dictionary(grouping: exerciseSets) { set in
//                Calendar.current.startOfDay(for: set.date)
//            }
//            
//            let sortedDays = groupedByDay.keys.sorted(by: >)
//            
//            for day in sortedDays {
//                guard let daySets = groupedByDay[day] else { continue }
//                
//                if daySets.count >= exercise.targetSets {
//                    let weights = daySets.map { $0.weight }
//                    let maxWeight = weights.max() ?? 0
//                    
//                    if maxWeight > 0 {
//                        let daysAgo = Calendar.current.dateComponents([.day], from: day, to: currentDayStart).day ?? 0
//                        let isLowerBody = exercise.muscle == .legs
//                        let increment = isLowerBody ? 5.0 : 2.5
//                        let recommendedWeight = maxWeight + increment
//                        
//                        return ProgressionData(
//                            lastWeight: maxWeight,
//                            recommendedWeight: recommendedWeight,
//                            lastWorkoutDate: day,
//                            daysAgo: daysAgo
//                        )
//                    }
//                }
//            }
//            
//            return nil
//        } catch {
//            print("Error loading progression data: \(error)")
//            return nil
//        }
//    }
}
//struct WorkoutLogSection: View {
//    let splitDay: SplitDay
//    @State private var showExercisePicker = false
//    @State private var selectedExercise: Exercise?
//    @State private var showLogSheet = false
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 12) {
//            Text("Today's Exercises")
//                .font(.headline)
//
//            if splitDay.exercises.isEmpty {
//                VStack(spacing: 16) {
//                    Image(systemName: "dumbbell")
//                        .font(.system(size: 40))
//                        .foregroundStyle(.secondary)
//
//                    Text("No exercises added yet")
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//
//                    Button {
//                        showExercisePicker = true
//                    } label: {
//                        Label("Add Exercises", systemImage: "plus")
//                            .frame(maxWidth: .infinity)
//                    }
//                    .buttonStyle(.borderedProminent)
//                }
//                .frame(maxWidth: .infinity)
//                .padding()
//                .background(Color(.secondarySystemGroupedBackground))
//                .cornerRadius(12)
//            } else {
//                // Display exercises with log button
//                ForEach(splitDay.exercises) { exercise in
//                    Button {
//                        selectedExercise = exercise
//                        showLogSheet = true
//                    } label: {
//                        ExerciseLogView(exercise: exercise)
//                            .contentShape(Rectangle())
//                    }
//                    .buttonStyle(.plain)
//                }
//
//                Button {
//                    showExercisePicker = true
//                } label: {
//                    Label("Add Exercise", systemImage: "plus")
//                }
//                .padding(.top)
//            }
//        }
//        .sheet(isPresented: $showExercisePicker) {
//            ExercisePickerView(splitDay: splitDay)
//                .presentationDetents([.medium, .large])
//        }
//        .sheet(isPresented: $showLogSheet) {
//            if let exercise = selectedExercise {
//                ExerciseLogSheetView(exercise: exercise)
//            }
//        }
//    }
//}
//

struct ExerciseLogView: View {
    let exercise: Exercise
    let selectedDate: Date // ADD THIS PARAMETER

    
    // Store sets directly rather than using a Query with complex predicate
    @State private var completedSets: [SetEntry] = []
    @Environment(\.modelContext) private var context
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text(exercise.name)
                        .font(.headline)
                    
                    Text(exercise.muscle.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if completedSets.isEmpty {
                    Text("Log")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                } else if completedSets.count >= exercise.targetSets {
                    // Show "View Log" when target sets are completed
                    Text("View Log")
                        .font(.footnote)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(Color.green)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                } else {
                    ProgressBadge(completed: completedSets.count, target: exercise.targetSets)
                }
            }
            
            // Progress indicators and set summary
            if !completedSets.isEmpty {
                VStack(spacing: 6) {
                    // Progress bar
                    ProgressView(value: Double(completedSets.count), total: Double(exercise.targetSets))
                        .tint(.green)
                    
                    HStack {
                        if completedSets.count >= exercise.targetSets {
                            Label("Complete!", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption.bold())
                        } else {
                            Text("\(completedSets.count)/\(exercise.targetSets) sets completed")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                            
                        Button {
                            // Action to edit the logged workout
                        } label: {
                            Text("Edit Log")
                                .font(.caption)
                                .foregroundStyle(.blue)
                        }
                    }
                    
                    // Show latest weight if available
                    if let maxWeight = completedSets.map({ $0.weight }).max(), maxWeight > 0 {
                        Text("Latest: \(Int(maxWeight))kg × \(completedSets.last?.reps ?? 0) reps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else {
                Text("Target: \(exercise.targetSets) × \(exercise.targetReps)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(8)
        .onAppear {
            loadCompletedSets()
        }
        .onChange(of: context) { _, _ in
            // Refresh when context changes (new data saved)
            loadCompletedSets()
        }
    }
    
    private func loadCompletedSets() {
            do {
                let calendar = Calendar.current
                let startOfDay = calendar.startOfDay(for: selectedDate) // CHANGED: use selectedDate
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
                
                let descriptor = FetchDescriptor<SetEntry>()
                let allSets = try context.fetch(descriptor)
                
                self.completedSets = allSets.filter { set in
                    set.exercise.id == exercise.id &&
                    set.date >= startOfDay &&
                    set.date < endOfDay
                }
            } catch {
                print("Error loading sets: \(error)")
            }
        }
}
//struct ExerciseLogView: View {
//    let exercise: Exercise
//
//    // Store sets directly rather than using a Query with complex predicate
//    @State private var completedSets: [SetEntry] = []
//    @Environment(\.modelContext) private var context
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                VStack(alignment: .leading) {
//                    Text(exercise.name)
//                        .font(.headline)
//
//                    Text(exercise.muscle.displayName)
//                        .font(.subheadline)
//                        .foregroundStyle(.secondary)
//                }
//
//                Spacer()
//
//                if completedSets.isEmpty {
//                    Text("Log")
//                        .font(.footnote)
//                        .fontWeight(.medium)
//                        .padding(.horizontal, 16)
//                        .padding(.vertical, 6)
//                        .background(Color.blue)
//                        .foregroundStyle(.white)
//                        .cornerRadius(8)
//                } else {
//                    ProgressBadge(completed: completedSets.count, target: exercise.targetSets)
//                }
//            }
//
//            // Progress indicators and set summary
//            if !completedSets.isEmpty {
//                VStack(spacing: 6) {
//                    // Progress bar
//                    ProgressView(value: Double(completedSets.count), total: Double(exercise.targetSets))
//                        .tint(.green)
//
//                    HStack {
//                        if completedSets.count >= exercise.targetSets {
//                            Label("Complete!", systemImage: "checkmark.circle.fill")
//                                .foregroundStyle(.green)
//                                .font(.caption.bold())
//                        } else {
//                            Text("\(completedSets.count)/\(exercise.targetSets) sets completed")
//                                .font(.caption)
//                                .foregroundStyle(.secondary)
//                        }
//
//                        Spacer()
//
//                        Button {
//                            // Action to edit the logged workout
//                        } label: {
//                            Text("Edit Log")
//                                .font(.caption)
//                                .foregroundStyle(.blue)
//                        }
//                    }
//
//                    // Show latest weight if available
//                    if let maxWeight = completedSets.map({ $0.weight }).max(), maxWeight > 0 {
//                        Text("Latest: \(Int(maxWeight))kg × \(completedSets.last?.reps ?? 0) reps")
//                            .font(.caption)
//                            .foregroundStyle(.secondary)
//                    }
//                }
//            } else {
//                Text("Target: \(exercise.targetSets) × \(exercise.targetReps)")
//                    .font(.caption)
//                    .foregroundStyle(.secondary)
//            }
//        }
//        .padding()
//        .frame(maxWidth: .infinity, alignment: .leading)
//        .background(Color(.secondarySystemGroupedBackground))
//        .cornerRadius(8)
//        .onAppear {
//            loadCompletedSets()
//        }
//    }
//
//    private func loadCompletedSets() {
//        // Manually fetch completed sets to avoid predicate issues
//        do {
//            let calendar = Calendar.current
//            let today = calendar.startOfDay(for: .now)
//            let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
//
//            let descriptor = FetchDescriptor<SetEntry>()
//            let allSets = try context.fetch(descriptor)
//
//            // Filter manually
//            self.completedSets = allSets.filter { set in
//                set.exercise.id == exercise.id &&
//                set.date >= today &&
//                set.date < tomorrow
//            }
//        } catch {
//            print("Error loading sets: \(error)")
//        }
//    }
//}

// New component for showing completed/total sets in a badge
struct ProgressBadge: View {
    let completed: Int
    let target: Int
    
    var body: some View {
        Text("\(completed)/\(target)")
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(completed >= target ? Color.green : Color.blue)
            )
            .foregroundStyle(.white)
    }
}

struct RestDayView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.mind.and.body")
                .font(.system(size: 60))
                .foregroundStyle(.blue)
            
            Text("Rest Day")
                .font(.title)
                .fontWeight(.bold)
            
            Text("Today is scheduled as a rest day. Take time to recover and prepare for your next workout.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
            
            Button {
                // Action to log a workout anyway
            } label: {
                Text("Log a workout anyway")
                    .padding(.horizontal)
            }
            .buttonStyle(.bordered)
            .padding(.top)
        }
        .padding(40)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}

struct NoActiveSplitView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundStyle(.orange)
            
            Text("No Active Split")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("You need to create and activate a workout split to see your schedule.")
                .multilineTextAlignment(.center)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            NavigationLink(destination: SplitsListView()) {
                Label("Set Up a Split", systemImage: "plus")
                    .padding(.horizontal)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(40)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}
