//
//  SplitDayExercisesView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-16.
//
//
//  SplitDayExercisesView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-16.
//

import SwiftUI
import SwiftData

struct SplitDayExercisesView: View {
    @Bindable var splitDay: SplitDay
    @Environment(\.modelContext) private var context
    @State private var showExercisePicker = false
    @State private var editMode = EditMode.inactive
    @State private var selectedExercise: Exercise?
    @State private var showLogSheet = false
    @State private var isLoggingMode = false

    var body: some View {
        List {
            if splitDay.exercises.isEmpty {
                Section {
                    Button {
                        showExercisePicker = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(.blue)
                            Text("Add Exercises")
                                .foregroundStyle(.blue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .buttonStyle(.plain)
                }
            } else {
                ForEach(splitDay.exercises) { exercise in
                    if isLoggingMode {
                        Button {
                            selectedExercise = exercise
                            showLogSheet = true
                        } label: {
                            ExerciseConfigRow(exercise: exercise)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    } else {
                        Section {
                            ExerciseConfigRow(exercise: exercise)
                        }
                    }
                }
                .onDelete(perform: deleteExercise)

                if !isLoggingMode {
                    Button {
                        showExercisePicker = true
                    } label: {
                        Label("Add More Exercises", systemImage: "plus")
                    }
                }
            }
        }
        .navigationTitle("\(splitDay.title) Exercises")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if !splitDay.exercises.isEmpty {
                    Button {
                        isLoggingMode.toggle()
                    } label: {
                        Text(isLoggingMode ? "Done" : "Log Workout")
                    }
                }
            }
            
            ToolbarItem(placement: .navigationBarLeading) {
                if !isLoggingMode {
                    EditButton()
                }
            }
        }
        .environment(\.editMode, $editMode)
        .sheet(isPresented: $showExercisePicker) {
            ExercisePickerView(splitDay: splitDay)
                .presentationDetents([.medium, .large])
        }
        // Change this sheet presentation:
        .sheet(isPresented: $showLogSheet) {
            if let exercise = selectedExercise {
                ExerciseLogSheetView(exercise: exercise)  // Use ExerciseLogSheetView instead of ExerciseLogView
            }
        }
    }

    private func deleteExercise(at offsets: IndexSet) {
        for index in offsets {
            let exercise = splitDay.exercises[index]
            splitDay.exercises.remove(at: index)
            context.delete(exercise)
        }
    }
}

// Fixed component that properly handles binding
struct ExerciseConfigRow: View {
    @Bindable var exercise: Exercise
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(exercise.name)
                .font(.headline)
            
            Text(exercise.muscle.displayName)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Stepper("Sets: \(exercise.targetSets)", value: $exercise.targetSets, in: 1...10)
                    .frame(maxWidth: .infinity)
                
                Stepper("Reps: \(exercise.targetReps)", value: $exercise.targetReps, in: 1...30)
                    .frame(maxWidth: .infinity)
            }
            .font(.subheadline)
            .padding(.top, 4)
        }
    }
}
