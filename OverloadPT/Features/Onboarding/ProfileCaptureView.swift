//
//  ProfileCaptureView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//
import SwiftUI

struct ProfileCaptureView: View {
    @ObservedObject var draft: OnboardDraft
    @State private var goNext = false

    @State private var first = ""
    @State private var unit: MassUnit = .kg
    @State private var weightText = ""
    @State private var heightText = ""
    @State private var feetText   = ""
    @State private var inchText   = ""

    var body: some View {
        Form {
            // ── Personal ───────────────────────────
            Section("About you") {
                TextField("First name", text: $first)

                Picker("Gender", selection: $draft.gender) {           // NEW
                    ForEach(Gender.allCases) { Text($0.rawValue.capitalized).tag($0) }
                }

                Picker("Units", selection: $unit) {
                    Text("Kilograms").tag(MassUnit.kg)
                    Text("Pounds").tag(MassUnit.lb)
                }
                .pickerStyle(.segmented)

                if unit == .kg {
                    TextField("Height (cm)", text: $heightText)        // cm field
                        .keyboardType(.decimalPad)
                } else {
                    HStack {                                           // ft-in fields
                        TextField("ft", text: $feetText)
                            .keyboardType(.numberPad)
                            .frame(width: 40)
                        TextField("in", text: $inchText)
                            .keyboardType(.numberPad)
                            .frame(width: 50)
                    }
                }

                TextField("Current weight (\(unit == .kg ? "kg":"lb"))",
                          text: $weightText)
                    .keyboardType(.decimalPad)
            }

            Button("Next")  { stash(); goNext = true }
                .buttonStyle(.borderedProminent)
                .disabled(first.isEmpty)
        }
        .navigationTitle("Welcome")
        .navigationDestination(isPresented: $goNext) {
            GoalExperienceView(draft: draft)          // step 2
        }
    }

    private func stash() {
        draft.firstName = first
        draft.unit      = unit
        if let w = Double(weightText) { draft.weight = w }
        if let h = Double(heightText) { draft.heightCm = h }
        if unit == .lb, let ft = Double(feetText), let inch = Double(inchText) {
            draft.heightCm = (ft * 12 + inch) * 2.54
        } else if let h = Double(heightText) {
            draft.heightCm = h
        }
    }
}
