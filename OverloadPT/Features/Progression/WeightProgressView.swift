//
//  WeightProgressView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-07-14.
//

import SwiftUI
import SwiftData
import Charts

// Define a new enum with a different name
enum WeightTimeRange: String, CaseIterable, Identifiable {
    case week = "7 Days"
    case month = "30 Days"
    case threeMonths = "3 Months"
    case sixMonths = "6 Months"
    case year = "1 Year"

    var id: Self { self }

    var dateRange: Date {
        let calendar = Calendar.current
        let now = Date()

        switch self {
        case .week:
            return calendar.date(byAdding: .day, value: -7, to: now)!
        case .month:
            return calendar.date(byAdding: .day, value: -30, to: now)!
        case .threeMonths:
            return calendar.date(byAdding: .month, value: -3, to: now)!
        case .sixMonths:
            return calendar.date(byAdding: .month, value: -6, to: now)!
        case .year:
            return calendar.date(byAdding: .year, value: -1, to: now)!
        }
    }
}

struct WeightProgressView: View {
    @Environment(\.modelContext) private var context
    @Query private var userProfiles: [UserProfile]
    @State private var timeRange: WeightTimeRange = .month
    @State private var weightLogs: [BodyWeightRecord] = []
    
    private var userProfile: UserProfile? {
        userProfiles.first
    }
    
    private var massUnit: MassUnit {
        userProfile?.unit ?? .kg
    }
    
    private var unitSymbol: String {
        massUnit == .kg ? "kg" : "lbs"
    }
    
    private func formatWeight(_ weight: Double) -> String {
        let displayWeight = massUnit == .kg ? weight : weight * 2.20462
        return String(format: "%.1f", displayWeight)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weight Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Picker("Time Range", selection: $timeRange) {
                    ForEach(WeightTimeRange.allCases) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.menu)
            }
            
            if weightLogs.isEmpty {
                EmptyWeightDataView()
            } else {
                // Stats section
                VStack(spacing: 16) {
                    // Weight trends
                    HStack {
                        WeightStatCard(
                            title: "Current",
                            value: "\(formatWeight(latestWeight)) \(unitSymbol)",
                            icon: "scalemass.fill",
                            color: .blue
                        )
                        
                        WeightStatCard(
                            title: "Change",
                            value: weightChangeSummary,
                            trend: weightChange < 0 ? .down : .up,
                            icon: weightChange < 0 ? "arrow.down.circle.fill" : "arrow.up.circle.fill",
                            color: weightChange < 0 ? .green : .red
                        )
                        
                        WeightStatCard(
                            title: "Average",
                            value: "\(formatWeight(averageWeight)) \(unitSymbol)",
                            icon: "chart.bar.fill",
                            color: .purple
                        )
                    }
                    
                    // Chart
                    Chart {
                        ForEach(weightLogs) { log in
                            LineMark(
                                x: .value("Date", log.date),
                                y: .value("Weight", massUnit == .kg ? log.weight : log.weight * 2.20462)
                            )
                            .foregroundStyle(Color.blue.gradient)
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", log.date),
                                y: .value("Weight", massUnit == .kg ? log.weight : log.weight * 2.20462)
                            )
                            .foregroundStyle(Color.blue)
                        }
                        
                        if weightLogs.count >= 3 {
                            RuleMark(y: .value("Average", massUnit == .kg ? averageWeight : averageWeight * 2.20462))
                                .foregroundStyle(.purple.opacity(0.3))
                                .lineStyle(StrokeStyle(lineWidth: 1, dash: [5, 5]))
                                .annotation(position: .top, alignment: .leading) {
                                    Text("Average")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                        }
                    }
                    .frame(height: 220)
                    .chartYScale(domain: chartYDomain)
                    .chartXAxis {
                        AxisMarks { _ in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .onAppear {
            loadWeightLogs()
        }
        .onChange(of: timeRange) { _, _ in
            loadWeightLogs()
        }
    }
    
    // MARK: - Data calculations
    
    private var latestWeight: Double {
        weightLogs.last?.weight ?? 0
    }
    
    private var earliestWeight: Double {
        weightLogs.first?.weight ?? latestWeight
    }
    
    private var weightChange: Double {
        latestWeight - earliestWeight
    }
    
    private var weightChangeSummary: String {
        let absChange = abs(weightChange)
        let displayChange = massUnit == .kg ? absChange : absChange * 2.20462
        let sign = weightChange < 0 ? "-" : "+"
        return "\(sign)\(String(format: "%.1f", displayChange)) \(unitSymbol)"
    }
    
    private var averageWeight: Double {
        guard !weightLogs.isEmpty else { return 0 }
        let sum = weightLogs.reduce(0) { $0 + $1.weight }
        return sum / Double(weightLogs.count)
    }
    
    private var chartYDomain: ClosedRange<Double> {
        guard !weightLogs.isEmpty else {
            return massUnit == .kg ? 60...80 : 132...176
        }
        
        let weights = weightLogs.map { massUnit == .kg ? $0.weight : $0.weight * 2.20462 }
        if let minWeight = weights.min(), let maxWeight = weights.max() {
            let padding = Swift.max(massUnit == .kg ? 2.0 : 4.0, (maxWeight - minWeight) * 0.2)
            return (minWeight - padding)...(maxWeight + padding)
        }
        return massUnit == .kg ? 60...80 : 132...176
    }
    
    // MARK: - Helper methods
    
    private func loadWeightLogs() {
        do {
            let cutoffDate = timeRange.dateRange
            let descriptor = FetchDescriptor<BodyWeightRecord>(
                predicate: #Predicate<BodyWeightRecord> { log in
                    log.date >= cutoffDate
                },
                sortBy: [SortDescriptor(\.date)]
            )
            
            weightLogs = try context.fetch(descriptor)
        } catch {
            print("Error loading weight logs: \(error)")
            weightLogs = []
        }
    }
}

// MARK: - Supporting Views

struct WeightStatCard: View {
    let title: String
    let value: String
    var trend: TrendDirection? = nil
    let icon: String
    let color: Color
    
    enum TrendDirection {
        case up, down
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.bold)
                
                if let trend = trend {
                    Image(systemName: trend == .up ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .foregroundStyle(trend == .up ? .red : .green)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.tertiarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct EmptyWeightDataView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "scalemass")
                .font(.system(size: 50))
                .foregroundStyle(.secondary)
                .padding(.bottom, 8)
            
            Text("No Weight Data")
                .font(.headline)
            
            Text("Start logging your weight daily to see trends and progress over time.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
    }
}
