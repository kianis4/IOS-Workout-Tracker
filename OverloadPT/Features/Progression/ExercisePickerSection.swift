//
//  ProgressionSupportingViews.swift
//  OverloadPT
//
//  Created by Suleyman Kianchi on 2025-06-17.
//

import SwiftUI
import SwiftData

struct ExercisePickerSection: View {
    let exercises: [Exercise]
    @Binding var selectedExercise: Exercise?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Exercise")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            Menu {
                ForEach(exercises) { exercise in
                    Button(exercise.name) {
                        selectedExercise = exercise
                    }
                }
            } label: {
                HStack {
                    Text(selectedExercise?.name ?? "Select Exercise")
                        .foregroundStyle(selectedExercise == nil ? .secondary : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.tertiarySystemGroupedBackground))
                .cornerRadius(8)
            }
        }
    }
}

struct TimeFramePickerSection: View {
    @Binding var timeFrame: TimeFrame
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Time Frame")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(spacing: 8) {
                ForEach(TimeFrame.allCases, id: \.self) { frame in
                    Button(frame.rawValue) {
                        timeFrame = frame
                    }
                    .foregroundStyle(timeFrame == frame ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(timeFrame == frame ? Color.blue : Color(.tertiarySystemGroupedBackground))
                    .cornerRadius(6)
                }
                Spacer()
            }
        }
    }
}

struct StatsCardView: View {
    @Environment(\.modelContext) private var context
    let exercise: Exercise
    let timeFrame: TimeFrame
    
    @State private var stats: ProgressStats = ProgressStats()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Statistics")
                .font(.headline)
            
            HStack(spacing: 16) {
                StatItem(
                    title: "Max Weight",
                    value: stats.maxWeight > 0 ? "\(Int(stats.maxWeight))kg" : "N/A",
                    icon: "arrow.up.circle.fill",
                    color: .green
                )
                
                StatItem(
                    title: "Total Sets",
                    value: "\(stats.totalSets)",
                    icon: "number.circle.fill",
                    color: .blue
                )
                
                StatItem(
                    title: "Workouts",
                    value: "\(stats.workoutDays)",
                    icon: "calendar.circle.fill",
                    color: .orange
                )
            }
            
            if stats.weightIncrease != 0 {
                HStack {
                    Image(systemName: stats.weightIncrease > 0 ? "arrow.up.right" : "arrow.down.right")
                        .foregroundStyle(stats.weightIncrease > 0 ? .green : .red)
                    
                    Text("Weight change: \(stats.weightIncrease > 0 ? "+" : "")\(Int(stats.weightIncrease))kg")
                        .font(.subheadline)
                        .foregroundStyle(stats.weightIncrease > 0 ? .green : .red)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .onAppear {
            loadStats()
        }
        .onChange(of: timeFrame) { _, _ in
            loadStats()
        }
    }
    
    private func loadStats() {
        do {
            let startDate = timeFrame.dateRange
            let descriptor = FetchDescriptor<SetEntry>()
            let allSets = try context.fetch(descriptor)
            
            let filteredSets = allSets.filter { set in
                set.exercise.id == exercise.id &&
                set.date >= startDate
            }
            
            let maxWeight = filteredSets.map({ $0.weight }).max() ?? 0
            let totalSets = filteredSets.count
            let workoutDays = Set(filteredSets.map { Calendar.current.startOfDay(for: $0.date) }).count
            
            // Calculate weight increase (first vs last max weight)
            let groupedByDay = Dictionary(grouping: filteredSets) { set in
                Calendar.current.startOfDay(for: set.date)
            }
            
            let sortedDays = groupedByDay.keys.sorted()
            var weightIncrease: Double = 0
            
            if sortedDays.count >= 2 {
                let firstDayMax = groupedByDay[sortedDays.first!]?.map({ $0.weight }).max() ?? 0
                let lastDayMax = groupedByDay[sortedDays.last!]?.map({ $0.weight }).max() ?? 0
                weightIncrease = lastDayMax - firstDayMax
            }
            
            stats = ProgressStats(
                maxWeight: maxWeight,
                totalSets: totalSets,
                workoutDays: workoutDays,
                weightIncrease: weightIncrease
            )
            
        } catch {
            print("Error loading stats: \(error)")
        }
    }
}

struct StatItem: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
            
            Text(value)
                .font(.headline)
                .fontWeight(.semibold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct WorkoutHistoryView: View {
    @Environment(\.modelContext) private var context
    let exercise: Exercise
    let timeFrame: TimeFrame
    
    @State private var workoutHistory: [WorkoutSession] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Workouts")
                .font(.headline)
            
            if workoutHistory.isEmpty {
                Text("No workouts found")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(workoutHistory) { session in
                    WorkoutSessionRow(session: session)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .onAppear {
            loadWorkoutHistory()
        }
        .onChange(of: timeFrame) { _, _ in
            loadWorkoutHistory()
        }
    }
    
    private func loadWorkoutHistory() {
        do {
            let startDate = timeFrame.dateRange
            let descriptor = FetchDescriptor<SetEntry>()
            let allSets = try context.fetch(descriptor)
            
            let filteredSets = allSets.filter { set in
                set.exercise.id == exercise.id &&
                set.date >= startDate
            }
            
            let groupedByDay = Dictionary(grouping: filteredSets) { set in
                Calendar.current.startOfDay(for: set.date)
            }
            
            workoutHistory = groupedByDay.map { (date, sets) in
                let maxWeight = sets.map({ $0.weight }).max() ?? 0
                let totalSets = sets.count
                let avgReps = sets.map({ Double($0.reps) }).reduce(0, +) / Double(sets.count)
                
                return WorkoutSession(
                    date: date,
                    maxWeight: maxWeight,
                    totalSets: totalSets,
                    avgReps: Int(avgReps.rounded())
                )
            }.sorted { $0.date > $1.date }
            
        } catch {
            print("Error loading workout history: \(error)")
        }
    }
}

struct WorkoutSessionRow: View {
    let session: WorkoutSession
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(session.date.formatted(date: .abbreviated, time: .omitted))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(session.totalSets) sets • ~\(session.avgReps) reps")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            if session.maxWeight > 0 {
                Text("\(Int(session.maxWeight))kg")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Data Models

struct ProgressStats {
    let maxWeight: Double
    let totalSets: Int
    let workoutDays: Int
    let weightIncrease: Double
    
    init(maxWeight: Double = 0, totalSets: Int = 0, workoutDays: Int = 0, weightIncrease: Double = 0) {
        self.maxWeight = maxWeight
        self.totalSets = totalSets
        self.workoutDays = workoutDays
        self.weightIncrease = weightIncrease
    }
}

struct WorkoutSession: Identifiable {
    let id = UUID()
    let date: Date
    let maxWeight: Double
    let totalSets: Int
    let avgReps: Int
}