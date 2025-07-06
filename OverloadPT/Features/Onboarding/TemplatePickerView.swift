//
//  TemplatePickerView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//


import SwiftUI

/// Lets the user choose a split template.
/// When a template is tapped we mark it as chosen and push `WeekdayPickerView`.
struct TemplatePickerView: View {
    @ObservedObject var draft: OnboardDraft
    @State private var goNext = false           // push trigger

    var body: some View {
        List {
            ForEach(SplitTemplate.catalog, id: \.id) { tmpl in
                TemplateRow(template: tmpl,
                            isSelected: tmpl.id == draft.chosenTemplate?.id)
                .contentShape(Rectangle())      // makes whole row tappable
                .onTapGesture {
                    draft.chosenTemplate = tmpl
                    goNext = true
                }
            }
        }
        .navigationTitle("Templates")
        .navigationDestination(isPresented: $goNext) {
            WeekdayPickerView(draft: draft)
        }
    }
}

/// A tiny, compiler-friendly row view.
private struct TemplateRow: View {
    let template: SplitTemplate
    let isSelected: Bool

    var body: some View {
        HStack {
            Text(template.name)
            if isSelected {
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.tint)     // <- changed here
            }
        }
    }
}
