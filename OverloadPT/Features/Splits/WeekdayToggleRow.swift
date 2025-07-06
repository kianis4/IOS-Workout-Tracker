//
//  WeekdayToggleRow.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//


import SwiftUI

/// Horizontal row of 7 toggle-buttons (S M T W T F S)
struct WeekdayToggleRow: View {
    @Binding var selected: Set<Int>     // 0 = Sunday … 6 = Saturday

    private let symbols = Calendar.current.veryShortWeekdaySymbols

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { index in
                let isOn = selected.contains(index)
                Text(symbols[index])
                    .font(.subheadline.weight(.semibold))
                    .frame(width: 32, height: 32)
                    .background(isOn ? Color.accentColor : .secondary.opacity(0.2))
                    .foregroundStyle(isOn ? .white : .primary)
                    .clipShape(Circle())
                    .onTapGesture { toggle(index) }
                    .animation(.easeInOut, value: isOn)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }

    private func toggle(_ day: Int) {
        if selected.contains(day) {
            selected.remove(day)
        } else {
            selected.insert(day)
        }
    }
}
