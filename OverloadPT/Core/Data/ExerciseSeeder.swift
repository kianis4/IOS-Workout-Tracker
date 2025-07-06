//
//  ExerciseSeeder.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//

import Foundation
import SwiftData
@MainActor
enum ExerciseSeeder {
    static func run(container: ModelContainer) async throws {
        let ctx = container.mainContext

        // Seed exercises once
        if try ctx.fetch(FetchDescriptor<Exercise>()).isEmpty,
           let url   = Bundle.main.url(forResource: "Exercises", withExtension: "json"),
           let data  = try? Data(contentsOf: url),
           let items = try? JSONDecoder().decode([SeedExercise].self, from: data) {

            for item in items {
                if let group = MuscleGroup(rawValue: item.muscle.lowercased()) {
                    ctx.insert(Exercise(name: item.name, muscle: group))
                }
            }
            try ctx.save()
        }
    }

    private struct SeedExercise: Decodable {
        let name: String
        let muscle: String
    }
}
