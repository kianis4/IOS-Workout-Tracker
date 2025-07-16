//
//  WeekdayPickerView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//

import SwiftUI
import SwiftData

/// Final onboarding step – pick the exact weekdays you'll train.
struct WeekdayPickerView: View {
    @ObservedObject var draft: OnboardDraft
    @Environment(\.modelContext) private var ctx
    @EnvironmentObject private var app: AppState

    var body: some View {
        Form {
            Section("Which days will you train?") {
                WeekdayToggleRow(selected: $draft.chosenWeekdays)
                    .frame(maxWidth: .infinity, alignment: .center)
            }

            Button("Finish") { finishOnboarding() }
                .buttonStyle(.borderedProminent)
                .disabled(draft.chosenWeekdays.isEmpty)
        }
        .navigationTitle("Workout Days")
    }

    // MARK: – persist profile + first split
    private func finishOnboarding() {
        // 1️⃣ save profile
        let p = UserProfile(firstName: draft.firstName)
        p.unit = draft.unit
        p.heightCm = draft.heightCm ?? 0
        p.currentWeight = draft.weight ?? 0
        p.goal = draft.goal
        p.experience = draft.experience
        p.gender = draft.gender
        ctx.insert(p)

        // 2️⃣ create first split
        if let tmpl = draft.chosenTemplate {
            let split = WorkoutSplit(name: tmpl.name)
            split.isActive = true
            split.workoutDays = draft.chosenWeekdays
            
            // Create days with proper order
            split.days = tmpl.dayTitles.enumerated().map { index, title in
                SplitDay(title: title, order: index)
            }
            
            ctx.insert(split)
        }

        try? ctx.save()
        app.finishedOnboarding()
    }
}
