//
//  ProgressChartView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-07-06.
//


//
//  ProgressChartView.swift
//  OverloadPT
//
//  Created by Suleyman Kianchi on 2025-06-17.
//

import SwiftUI
import SwiftData
import Charts

struct ProgressChartView: View {
    @Environment(\.modelContext) private var context
    let exercise: Exercise
    let timeFrame: TimeFrame
    
    @State private var progressData: [ProgressDataPoint] = []
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Weight Progress")
                .font(.headline)
            
            if progressData.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 40))
                        .foregroundStyle(.secondary)
                    
                    Text("No data available")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(height: 200)
                .frame(maxWidth: .infinity)
            } else {
                Chart(progressData) { dataPoint in
                    LineMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Weight", dataPoint.maxWeight)
                    )
                    .foregroundStyle(.blue)
                    .symbol(Circle().strokeBorder(lineWidth: 2))
                    
                    PointMark(
                        x: .value("Date", dataPoint.date),
                        y: .value("Weight", dataPoint.maxWeight)
                    )
                    .foregroundStyle(.blue)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: chartXAxisStride)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .chartYAxis {
                    AxisMarks { _ in
                        AxisGridLine()
                        AxisValueLabel()
                    }
                }
                .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
        .onAppear {
            loadProgressData()
        }
        .onChange(of: timeFrame) { _, _ in
            loadProgressData()
        }
    }
    
    private var chartXAxisStride: Calendar.Component {
        switch timeFrame {
        case .week: return .day
        case .month: return .weekOfYear
        case .threeMonths, .sixMonths: return .month
        case .year: return .month
        }
    }
    
    private func loadProgressData() {
        do {
            let startDate = timeFrame.dateRange
            let descriptor = FetchDescriptor<SetEntry>()
            let allSets = try context.fetch(descriptor)
            
            let filteredSets = allSets.filter { set in
                set.exercise.id == exercise.id &&
                set.date >= startDate
            }
            
            // Group by day and find max weight per day
            let groupedByDay = Dictionary(grouping: filteredSets) { set in
                Calendar.current.startOfDay(for: set.date)
            }
            
            progressData = groupedByDay.compactMap { (date, sets) in
                guard let maxWeight = sets.map({ $0.weight }).max(), maxWeight > 0 else {
                    return nil
                }
                return ProgressDataPoint(date: date, maxWeight: maxWeight)
            }.sorted { $0.date < $1.date }
            
        } catch {
            print("Error loading progress data: \(error)")
        }
    }
}

struct ProgressDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let maxWeight: Double
}