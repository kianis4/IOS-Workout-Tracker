//
//  RecommendedTemplateView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//


import SwiftUI

/// Shows the recommended split, lets user accept **or** pick another.
struct RecommendedTemplateView: View {
    @ObservedObject var draft: OnboardDraft
    @State private var showAll = false                     // sheet toggle

    // simple rule-of-thumb recommender  🧠
    private var recommended: SplitTemplate {
        switch draft.desiredDays {
        case 1...2: SplitTemplate.catalog.first(where:{ $0.name == "Upper / Lower" })!
        case 3:     SplitTemplate.catalog.first(where:{ $0.name == "Full-Body 3-Day" })!
        case 4:     SplitTemplate.catalog.first(where:{ $0.name == "Upper / Lower" })!
        default:    draft.experience == .novice
                     ? SplitTemplate.catalog.first(where:{ $0.name == "Push / Pull / Legs" })!
                     : SplitTemplate.catalog.first(where:{ $0.name == "Arnold (PPL x2)" })!
        }
    }

    var body: some View {
        VStack(spacing: 24) {
            Text("We recommend")
                .font(.title2.weight(.medium))
            Text(recommended.name)
                .font(.largeTitle.weight(.bold))
                .multilineTextAlignment(.center)

            Button("Sounds good") {
                draft.chosenTemplate = recommended
                showAll = true      // advance → weekday picker
            }
            .buttonStyle(.borderedProminent)

            Button("See other templates") { showAll = true }
                .padding(.top, 8)
        }
        .padding()
        .navigationDestination(isPresented: $showAll) {
            TemplatePickerView(draft: draft)      // now *real* picker
        }
    }
}
