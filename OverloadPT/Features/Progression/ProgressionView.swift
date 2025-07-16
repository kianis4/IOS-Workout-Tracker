//
//  ProgressionView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-07-06.
//

import SwiftUI
import SwiftData
import Charts

enum ProgressionType: String, CaseIterable {
    case bodyWeight = "Body Weight"
    case lifting = "Lifting"
    
    var id: String { rawValue }
}

struct ProgressionView: View {
    @Environment(\.modelContext) private var context
    @Query private var exercises: [Exercise]
    @State private var selectedExercise: Exercise?
    @State private var timeFrame: TimeFrame = .month
    @State private var progressionType: ProgressionType = .bodyWeight
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Progress Type Selector
                Picker("Progress Type", selection: $progressionType) {
                    ForEach(ProgressionType.allCases, id: \.id) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(Color(.systemGroupedBackground))
                
                // Content based on selected type
                if progressionType == .bodyWeight {
                    ScrollView {
                        WeightProgressView()
                            .padding()
                    }
                } else {
                    // Lifting progression (your existing code)
                    VStack(spacing: 0) {
                        // Exercise Picker
                        if !exercises.isEmpty {
                            ExercisePickerSection(
                                exercises: exercises,
                                selectedExercise: $selectedExercise
                            )
                            .padding()
                            .background(Color(.systemGroupedBackground))
                        }
                        
                        if let exercise = selectedExercise {
                            // Time Frame Picker
                            TimeFramePickerSection(timeFrame: $timeFrame)
                                .padding(.horizontal)
                                .padding(.top)
                            
                            // Progress Charts
                            ScrollView {
                                LazyVStack(spacing: 20) {
                                    ProgressChartView(
                                        exercise: exercise,
                                        timeFrame: timeFrame
                                    )
                                    
                                    StatsCardView(
                                        exercise: exercise,
                                        timeFrame: timeFrame
                                    )
                                    
                                    WorkoutHistoryView(
                                        exercise: exercise,
                                        timeFrame: timeFrame
                                    )
                                }
                                .padding()
                            }
                        } else {
                            // Empty State for lifting
                            VStack(spacing: 16) {
                                Image(systemName: "chart.line.uptrend.xyaxis")
                                    .font(.system(size: 60))
                                    .foregroundStyle(.secondary)
                                
                                Text("Track Your Lifting Progress")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                
                                Text("Select an exercise to view your progression")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                        }
                    }
                }
            }
            .navigationTitle("Progression")
            .onAppear {
                if selectedExercise == nil && !exercises.isEmpty {
                    selectedExercise = exercises.first
                }
            }
        }
    }
}

// Rest of your existing code remains the same...
enum TimeFrame: String, CaseIterable {
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    
    var displayName: String {
        switch self {
        case .week: return "1 Week"
        case .month: return "1 Month"
        case .threeMonths: return "3 Months"
        case .sixMonths: return "6 Months"
        case .year: return "1 Year"
        }
    }
    
    var dateRange: Date {
        let calendar = Calendar.current
        switch self {
        case .week:
            return calendar.date(byAdding: .weekOfYear, value: -1, to: .now) ?? .now
        case .month:
            return calendar.date(byAdding: .month, value: -1, to: .now) ?? .now
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: .now) ?? .now
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: .now) ?? .now
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: .now) ?? .now
        }
    }
}
