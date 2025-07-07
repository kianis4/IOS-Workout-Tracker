//
//  TodayWorkoutView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-16.
//


import SwiftUI
import SwiftData

struct TodayWorkoutView: View {
    @Environment(\.modelContext) private var context
    @Query private var activeSplit: [WorkoutSplit]
    @State private var selectedExercise: Exercise?
    @State private var showLogSheet = false
    
    var body: some View {
        NavigationStack {
            Group {
                if let workoutForToday = todaysWorkout {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            // Header section
                            VStack(alignment: .leading) {
                                Text(workoutForToday.day.title)
                                    .font(.largeTitle)
                                    .fontWeight(.bold)
                                
                                Text("Let's crush your \(workoutForToday.day.title) workout today!")
                                    .foregroundStyle(.secondary)
                            }
                            .padding()
                            
                            // Exercise list
                            ForEach(workoutForToday.day.exercises) { exercise in
                                ExerciseCardView(exercise: exercise) {
                                    selectedExercise = exercise
                                    showLogSheet = true
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                } else {
                    ContentUnavailableView(
                        "No Workout Today",
                        systemImage: "figure.run.circle",
                        description: Text("You don't have a workout scheduled for today. Add a split program or select different workout days.")
                    )
                }
            }
            .navigationTitle("Today's Workout")
            .sheet(isPresented: $showLogSheet) {
                if let exercise = selectedExercise {
                    ExerciseLogView(exercise: exercise, selectedDate: Date())
                }
            }
        }
    }
    private var todaysWorkout: (day: SplitDay, weekday: Int)? {
        guard let activeSplit = activeSplit.first(where: { $0.isActive }) else {
            return nil
        }
        
        let today = Calendar.current.component(.weekday, from: Date()) - 1
        let adjustedToday = (today + 6) % 7  // Convert to 0-6 where 0 is Monday
        
        if !activeSplit.workoutDays.contains(adjustedToday) {
            return nil
        }
        
        // Calculate which day's workout to show
        let workoutDays = activeSplit.workoutDays.sorted()
        guard let indexInSchedule = workoutDays.firstIndex(of: adjustedToday) else {
            return nil
        }
        
        let dayIndex = indexInSchedule % activeSplit.days.count
        guard dayIndex < activeSplit.days.count else {
            return nil
        }
        
        return (activeSplit.days[dayIndex], adjustedToday)
    }
}

struct ExerciseCardView: View {
    let exercise: Exercise
    let logAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                VStack(alignment: .leading) {
                    Text(exercise.name)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text(exercise.muscle.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button(action: logAction) {
                    Text("Log")
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.blue)
                        .foregroundStyle(.white)
                        .cornerRadius(8)
                }
            }
            
            Divider()
                .padding(.vertical, 2)
            
            Text("\(exercise.targetSets) sets × \(exercise.targetReps) reps")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
