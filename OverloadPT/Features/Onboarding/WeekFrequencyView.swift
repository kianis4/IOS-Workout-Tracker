//
//  WeekFrequencyView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//


import SwiftUI

struct WeekFrequencyView: View {
    @ObservedObject var draft: OnboardDraft
    @State private var goNext = false

    var body: some View {
        VStack(spacing: 24) {
            Text("How many days per week\ncan you lift?")
                .multilineTextAlignment(.center)
                .font(.title2)

            Picker("", selection: $draft.desiredDays) {
                ForEach(1...7, id: \.self) { Text("\($0)") }
            }
            .pickerStyle(.wheel)
            .frame(height: 120)

            Button("Next") { goNext = true }
                .buttonStyle(.borderedProminent)
        }
        .padding()
        .navigationDestination(isPresented: $goNext) {
            RecommendedTemplateView(draft: draft)       // step 4
        }
    }
}
