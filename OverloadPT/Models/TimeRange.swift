//
//  TimeRange.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-07-14.
//


// Create a new file: Models/TimeRange.swift
import Foundation

enum TimeRange: String, CaseIterable, Identifiable {
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