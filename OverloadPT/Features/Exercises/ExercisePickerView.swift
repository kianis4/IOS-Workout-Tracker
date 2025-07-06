//
//  ExercisePickerView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-16.
//
import SwiftUI
import SwiftData

struct ExercisePickerView: View {
    @Bindable var splitDay: SplitDay
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var searchText = ""
    @State private var selectedCategory: String = "Recommended"

    var categories: [String] {
        ["Recommended"] + MuscleGroup.allCases.map { $0.displayName }
    }

    var filteredExercises: [String] {
        let exercises: [String]

        if selectedCategory == "Recommended" {
            exercises = ExerciseDatabase.recommendedExercisesFor(splitTitle: splitDay.title)
        } else if let muscleGroup = MuscleGroup.allCases.first(where: { $0.displayName == selectedCategory }) {
            exercises = muscleGroup.exercises
        } else {
            exercises = ExerciseDatabase.all
        }

        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }

    // Filter out exercises that are already added
    var availableExercises: [String] {
        let existingNames = Set(splitDay.exercises.map { $0.name })
        return filteredExercises.filter { !existingNames.contains($0) }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(categories, id: \.self) { category in
                            Button {
                                selectedCategory = category
                            } label: {
                                Text(category)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 6)
                                    .background(
                                        Capsule()
                                            .fill(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                                    )
                                    .foregroundStyle(selectedCategory == category ? .white : .primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
                .background(Color(.systemGroupedBackground))

                List {
                    ForEach(availableExercises, id: \.self) { exerciseName in
                        Button {
                            addExercise(exerciseName)
                        } label: {
                            HStack {
                                Text(exerciseName)
                                Spacer()
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(.blue)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .searchable(text: $searchText, prompt: "Search exercises")
            }
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }

    private func addExercise(_ name: String) {
        let muscleGroup = ExerciseDatabase.muscleGroupFor(exerciseName: name)
        let exercise = Exercise(name: name, muscle: muscleGroup)
        splitDay.exercises.append(exercise)
        context.insert(exercise)
    }
}
