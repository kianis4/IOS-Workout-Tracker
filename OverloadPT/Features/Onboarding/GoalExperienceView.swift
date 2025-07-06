//
//  GoalExperienceView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//


import SwiftUI

struct GoalExperienceView: View {
    @ObservedObject var draft: OnboardDraft
    @State private var goNext = false

    var body: some View {
        Form {
            Picker("Primary goal", selection: $draft.goal) {
                ForEach(GoalType.allCases) { Text($0.rawValue).tag($0) }
            }

            Picker("Experience", selection: $draft.experience) {
                ForEach(ExperienceLevel.allCases) {
                    Text($0.rawValue.capitalized).tag($0)
                }
            }.pickerStyle(.segmented)

            Button("Next") { goNext = true }
                .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Training")
        .navigationDestination(isPresented: $goNext) {
            WeekFrequencyView(draft: draft)             // step 3
        }
    }
}
