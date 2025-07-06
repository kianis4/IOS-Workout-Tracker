//
//  OnboardDraft.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//


import Foundation
import SwiftData

@MainActor
final class OnboardDraft: ObservableObject {
    // profile basics
    @Published var firstName = ""
    @Published var unit: MassUnit = .kg
    @Published var weight: Double?
    @Published var heightCm: Double?          // NEW
    @Published var gender: Gender = .undisclosed
    // training prefs
    @Published var goal: GoalType = .buildMuscle
    @Published var experience: ExperienceLevel = .novice
    @Published var desiredDays: Int = 3
    @Published var chosenWeekdays: Set<Int> = []

    // split
    @Published var chosenTemplate: SplitTemplate?
}
