//
//  OverloadPTApp.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//

import SwiftUI
import SwiftData

@main
struct OverloadPTApp: App {
    // stored properties
    private let container: ModelContainer
    @StateObject private var appState: AppState

    init() {
        // Define schema with all models
        let schema = Schema([
            Exercise.self,
            SetEntry.self,
            WorkoutSplit.self,
            SplitDay.self,
            BodyWeightRecord.self,
            UserProfile.self
        ])
        
        // Use the correct configuration syntax
        let config = ModelConfiguration(isStoredInMemoryOnly: false)
        
        // Create a local container variable to avoid capturing self
        let tempContainer: ModelContainer
        
        do {
            tempContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            print("Failed to create SwiftData container: \(error)")
            
            do {
                tempContainer = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: true)])
            } catch {
                fatalError("Could not create model container: \(error)")
            }
        }
        
        // Now assign to self properties
        self.container = tempContainer
        _appState = StateObject(wrappedValue: AppState(container: tempContainer))
        
        // Run seeder after initialization completes
        let containerRef = tempContainer
        Task {
            try? await ExerciseSeeder.run(container: containerRef)
        }
    }

    var body: some Scene {
        WindowGroup {
            RootSwitchView()
                .environmentObject(appState)
        }
        .modelContainer(container)
    }
}
