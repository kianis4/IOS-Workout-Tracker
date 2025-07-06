//
//  Models.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//
//


import Foundation
import SwiftData

// MARK: - Workout & Logging
@Model
final class Exercise {
    @Attribute(.unique) var id = UUID()
    var name: String
    var muscle: MuscleGroup
    var targetSets: Int
    var targetReps: Int
    
    init(name: String, muscle: MuscleGroup, targetSets: Int = 3, targetReps: Int = 10) {
        self.name = name
        self.muscle = muscle
        self.targetSets = targetSets
        self.targetReps = targetReps
    }
}

@Model
final class SetEntry {
    var id: UUID = UUID()
    var exercise: Exercise
    var weight: Double
    var reps: Int
    var date: Date
    
    init(exercise: Exercise, weight: Double = 0, reps: Int, date: Date = .now) {
        self.exercise = exercise
        self.weight = weight
        self.reps = reps
        self.date = date
    }
}

// MARK: - Split Planning
@Model
final class WorkoutSplit {
    var name: String
    var isActive = false

    /// Bit-mask of weekdays (0 = Sun … 6 = Sat)
    var workoutDayMask: Int16 = 0
    var days: [SplitDay] = []

    init(name: String) { self.name = name }

    /// Convenience API (not persisted)
    var workoutDays: Set<Int> {
        get { Set((0...6).filter { (workoutDayMask & (1 << $0)) != 0 }) }
        set {
            var mask: Int16 = 0
            newValue.forEach { mask |= Int16(1 << $0) }
            workoutDayMask = mask
        }
    }
}

@Model
final class SplitDay: Identifiable {
    var title: String
    var order: Int = 0            // explicit ordering index
    var exercises: [Exercise] = []

    init(title: String, order: Int = 0, exercises: [Exercise] = []) {
        self.title = title
        self.order = order
        self.exercises = exercises
    }
}

// MARK: - Tracking & Profile
@Model
final class BodyWeightRecord {
    var date: Date
    var weight: Double
    init(date: Date = .now, weight: Double) {
        self.date = date
        self.weight = weight
    }
}

enum Gender: String, Codable, CaseIterable, Identifiable {
    case female, male, other, undisclosed
    var id: String { rawValue }
}

@Model
final class UserProfile {
    var firstName: String
    var unit:       MassUnit        = MassUnit.kg
    var heightCm:   Double?
    var currentWeight: Double?
    var goal:       GoalType        = GoalType.buildMuscle
    var experience: ExperienceLevel = ExperienceLevel.novice
    var gender: Gender = Gender.undisclosed

    init(firstName: String) { self.firstName = firstName }
}

// MARK: - Helper enums
enum MuscleGroup: String, Codable, CaseIterable, Identifiable {
    case chest, back, legs, shoulders, biceps, triceps, forearms, core, fullBody
    var id: String { rawValue }
    
    var displayName: String {
        switch self {
        case .fullBody: return "Full Body"
        default: return rawValue.capitalized
        }
    }
    
    // Helper to get exercises for this muscle group
    var exercises: [String] {
        switch self {
        case .chest: return ExerciseDatabase.chest
        case .back: return ExerciseDatabase.back
        case .legs: return ExerciseDatabase.legs
        case .shoulders: return ExerciseDatabase.shoulders
        case .biceps: return ExerciseDatabase.biceps
        case .triceps: return ExerciseDatabase.triceps
        case .forearms: return ExerciseDatabase.forearms
        case .core: return ExerciseDatabase.core
        case .fullBody: return ExerciseDatabase.fullBody
        }
    }
}

enum MassUnit: String, Codable, CaseIterable, Identifiable {
    case kg, lb
    var id: String { rawValue }
    var unitMass: UnitMass { self == .kg ? .kilograms : .pounds }
}

enum GoalType: String, Codable, CaseIterable, Identifiable {
    case buildMuscle = "Build Muscle"
    case loseFat     = "Lose Fat"
    case strength    = "Increase Strength"
    var id: String { rawValue }
}

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case novice, intermediate, advanced
    var id: String { rawValue }
}

enum Weekday: Int, CaseIterable, Identifiable {
    case sun = 0, mon, tue, wed, thu, fri, sat
    var id: Int { rawValue }
    var short: String { Calendar.current.shortWeekdaySymbols[rawValue] }
}

// MARK: - Exercise Database
struct ExerciseDatabase {
    static let chest = [
        "Barbell Bench Press", "Dumbbell Bench Press", "Incline Barbell Press",
        "Incline Dumbbell Press", "Decline Bench Press", "Push-Ups",
        "Weighted Dips (Chest)", "Cable Crossover", "Cable Flys",
        "Machine Chest Press", "Pec Deck Machine", "Guillotine Press"
    ]

    static let shoulders = [
        "Barbell Overhead Press", "Dumbbell Shoulder Press", "Arnold Press",
        "Seated Overhead Press", "Z-Press", "Lateral Raises",
        "Cable Lateral Raises", "Front Raises", "Rear Delt Flys",
        "Reverse Pec Deck", "Face Pulls", "Bradford Press"
    ]

    static let back = [
        "Pull-Ups", "Chin-Ups", "Lat Pulldowns", "Barbell Rows",
        "Dumbbell Rows", "T-Bar Rows", "Seated Cable Rows",
        "Chest-Supported Rows", "Deadlifts", "Rack Pulls",
        "Meadows Rows", "Face Pulls", "Straight Arm Lat Pulldown"
    ]

    static let legs = [
        "Back Squat", "Front Squat", "Hack Squat", "Goblet Squat",
        "Leg Press", "Walking Lunges", "Bulgarian Split Squats",
        "Step-Ups", "Romanian Deadlift (RDL)", "Conventional Deadlift",
        "Sumo Deadlift", "Leg Extensions", "Leg Curls",
        "Nordic Hamstring Curl", "Glute Bridges", "Hip Thrusts", "Cable Kickbacks"
    ]

    static let biceps = [
        "Barbell Curl", "Dumbbell Curl", "Hammer Curl",
        "Concentration Curl", "Preacher Curl", "Cable Curl",
        "EZ Bar Curl", "Incline Dumbbell Curl", "Reverse Curl"
    ]

    static let triceps = [
        "Close-Grip Bench Press", "Skull Crushers", "Cable Tricep Pushdown",
        "Overhead Dumbbell Extension", "Overhead Cable Extension",
        "Dips", "Kickbacks", "EZ Bar Overhead Extension"
    ]

    static let forearms = [
        "Wrist Curl", "Reverse Wrist Curl", "Reverse Curl",
        "Farmer's Carry", "Plate Pinch", "Fat Grip Work", "Towel Grip Pull-Ups"
    ]

    static let core = [
        "Planks", "Hanging Leg Raises", "Cable Crunches",
        "Decline Sit-Ups", "Russian Twists", "Dead Bugs",
        "Ab Wheel Rollout", "Dragon Flags", "L-Sit Hold",
        "Toes to Bar", "Side Planks", "Cable Woodchoppers", "Windshield Wipers"
    ]

    static let fullBody = [
        "Deadlift", "Squat", "Bench Press", "Overhead Press", "Pull-Up",
        "Power Clean", "Clean and Jerk", "Snatch", "Push Press",
        "Thruster", "Farmer's Carry"
    ]

    static var all: [String] {
        chest + shoulders + back + legs + biceps + triceps + forearms + core + fullBody
    }
    
    // Helper method to determine muscle group for an exercise name
    static func muscleGroupFor(exerciseName: String) -> MuscleGroup {
        let name = exerciseName.lowercased()
        
        if chest.contains(where: { $0.lowercased() == name }) {
            return .chest
        } else if back.contains(where: { $0.lowercased() == name }) {
            return .back
        } else if legs.contains(where: { $0.lowercased() == name }) {
            return .legs
        } else if shoulders.contains(where: { $0.lowercased() == name }) {
            return .shoulders
        } else if biceps.contains(where: { $0.lowercased() == name }) {
            return .biceps
        } else if triceps.contains(where: { $0.lowercased() == name }) {
            return .triceps
        } else if forearms.contains(where: { $0.lowercased() == name }) {
            return .forearms
        } else if core.contains(where: { $0.lowercased() == name }) {
            return .core
        } else if fullBody.contains(where: { $0.lowercased() == name }) {
            return .fullBody
        } else {
            // Default fallback
            return .fullBody
        }
    }

    // Helper to get recommended exercises based on split day title
    static func recommendedExercisesFor(splitTitle: String) -> [String] {
        let title = splitTitle.lowercased()
        
        if title.contains("push") {
            return chest + shoulders + triceps
        } else if title.contains("pull") {
            return back + biceps + forearms
        } else if title.contains("leg") {
            return legs
        } else if title.contains("chest") {
            return chest
        } else if title.contains("back") {
            return back
        } else if title.contains("shoulder") {
            return shoulders
        } else if title.contains("arm") || title.contains("bicep") || title.contains("tricep") {
            return biceps + triceps
        } else if title.contains("core") || title.contains("ab") {
            return core
        } else if title.contains("full") {
            return fullBody
        } else {
            return all
        }
    }
}
