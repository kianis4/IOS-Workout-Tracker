// Features/Progress/WeightProgressView.swift
import SwiftUI
import SwiftData
import Charts

struct WeightProgressView: View {
    @Query private var weightLogs: [BodyWeightRecord]
    @State private var timeRange: TimeRange = .month
    
    init(timeRange: TimeRange = .month) {
        self._timeRange = State(initialValue: timeRange)
        
        // Get weight logs for the selected time range
        let cutoffDate = timeRange.dateRange
        let predicate = #Predicate<BodyWeightRecord> { log in
            log.date >= cutoffDate
        }
        
        self._weightLogs = Query(
            filter: predicate,
            sort: [SortDescriptor(\.date)]
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Weight Progress")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Spacer()
                
                Picker("Time Range", selection: $timeRange) {
                    ForEach(TimeRange.allCases) { range in
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
                            value: String(format: "%.1f kg", latestWeight),
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
                            value: String(format: "%.1f kg", averageWeight),
                            icon: "chart.bar.fill",
                            color: .purple
                        )
                    }
                    
                    // Chart
                    Chart {
                        ForEach(weightLogs) { log in
                            LineMark(
                                x: .value("Date", log.date),
                                y: .value("Weight", log.weight)
                            )
                            .foregroundStyle(Color.blue.gradient)
                            .interpolationMethod(.catmullRom)
                            
                            PointMark(
                                x: .value("Date", log.date),
                                y: .value("Weight", log.weight)
                            )
                            .foregroundStyle(Color.blue)
                        }
                        
                        if weightLogs.count >= 3 {
                            RuleMark(y: .value("Average", averageWeight))
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
                        AxisMarks(values: .stride(by: dateStride)) { _ in
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
        .onChange(of: timeRange) { _, newValue in
            updateQuery(for: newValue)
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
        let sign = weightChange < 0 ? "-" : "+"
        return "\(sign)\(String(format: "%.1f", absChange)) kg"
    }
    
    private var averageWeight: Double {
        guard !weightLogs.isEmpty else { return 0 }
        let sum = weightLogs.reduce(0) { $0 + $1.weight }
        return sum / Double(weightLogs.count)
    }
    
    private var chartYDomain: ClosedRange<Double> {
        guard !weightLogs.isEmpty else { return 60...80 }
        
        let weights = weightLogs.map { $0.weight }
        if let min = weights.min(), let max = weights.max() {
            let padding = max(2.0, (max - min) * 0.2)
            return (min - padding)...(max + padding)
        }
        return 60...80
    }
    
    private var dateStride: Calendar.Component {
        switch timeRange {
        case .week: return .day
        case .month: return .weekOfMonth
        case .threeMonths: return .month
        case .sixMonths: return .month
        case .year: return .month
        }
    }
    
    // MARK: - Helper methods
    
    private func updateQuery(for timeRange: TimeRange) {
        let cutoffDate = timeRange.dateRange
        let predicate = #Predicate<BodyWeightRecord> { log in
            log.date >= cutoffDate
        }
        
        self._weightLogs = Query(
            filter: predicate,
            sort: [SortDescriptor(\.date)]
        )
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