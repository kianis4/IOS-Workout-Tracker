//
//  SplitTemplatePickerView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//

import SwiftUI

/// Shows recommended template with option to see all templates
struct SplitTemplatePickerView: View {
    @ObservedObject var draft: OnboardDraft
    @State private var showAllTemplates = false

    // Recommendation logic
    private var recommended: SplitTemplate {
        switch draft.desiredDays {
        case 1...2: return SplitTemplate.catalog.first(where: { $0.name == "Upper / Lower" })!
        case 3: return SplitTemplate.catalog.first(where: { $0.name == "Full-Body 3-Day" })!
        case 4: return SplitTemplate.catalog.first(where: { $0.name == "Upper / Lower" })!
        default: return draft.experience == .novice
            ? SplitTemplate.catalog.first(where: { $0.name == "Push / Pull / Legs" })!
            : SplitTemplate.catalog.first(where: { $0.name == "Arnold (PPL x2)" })!
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("We recommend")
                .font(.title2.weight(.medium))
            
            Text(recommended.name)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)
            
            // Show what days this template includes
            VStack(spacing: 4) {
                ForEach(recommended.dayTitles, id: \.self) { day in
                    Text("• \(day)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .padding()
            
            VStack(spacing: 16) {
                Button("Use This Template") {
                    draft.chosenTemplate = recommended
                    showAllTemplates = true // This will navigate to weekday picker
                }
                .buttonStyle(.borderedProminent)
                
                Button("See All Templates") {
                    showAllTemplates = true
                }
                .buttonStyle(.bordered)
            }
        }
        .padding()
        .navigationTitle("Split Template")
        .navigationDestination(isPresented: $showAllTemplates) {
            if draft.chosenTemplate != nil {
                WeekdayPickerView(draft: draft)
            } else {
                TemplatePickerView(draft: draft)
            }
        }
    }
}
