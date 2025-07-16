//
//  TemplatePickerView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//

import SwiftUI

/// Full template picker that shows all templates and allows selection
struct TemplatePickerView: View {
    @ObservedObject var draft: OnboardDraft
    @State private var goNext = false

    var body: some View {
        List {
            ForEach(SplitTemplate.catalog, id: \.id) { tmpl in
                TemplateRow(template: tmpl,
                            isSelected: tmpl.id == draft.chosenTemplate?.id)
                .contentShape(Rectangle())
                .onTapGesture {
                    draft.chosenTemplate = tmpl
                    goNext = true
                }
            }
        }
        .navigationTitle("Choose Template")
        .navigationDestination(isPresented: $goNext) {
            WeekdayPickerView(draft: draft)
        }
    }
}

private struct TemplateRow: View {
    let template: SplitTemplate
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(template.name)
                    .font(.headline)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            
            // Show the days for this template
            ForEach(template.dayTitles, id: \.self) { day in
                Text("• \(day)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.leading, 4)
            }
        }
        .padding(.vertical, 4)
    }
}
