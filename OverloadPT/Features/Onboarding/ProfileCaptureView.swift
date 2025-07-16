//
//  ProfileCaptureView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//

import SwiftUI

struct ProfileCaptureView: View {
    @ObservedObject var draft: OnboardDraft
    @State private var weightText = ""
    @State private var heightText = ""
    
    var body: some View {
        Form {
            basicInfoSection
            physicalStatsSection
            trainingSection
            continueSection
        }
        .navigationTitle("Profile")
        .onAppear {
            setupInitialValues()
        }
        .onChange(of: weightText) { _, newValue in
            draft.weight = Double(newValue)
        }
        .onChange(of: heightText) { _, newValue in
            draft.heightCm = Double(newValue)
        }
    }
    
    private var basicInfoSection: some View {
        Section("Basic Information") {
            TextField("First Name", text: $draft.firstName)
            
            Picker("Units", selection: $draft.unit) {
                ForEach(MassUnit.allCases, id: \.self) { unit in
                    Text(unit.rawValue).tag(unit)
                }
            }
            .pickerStyle(.segmented)
            
            Picker("Gender", selection: $draft.gender) {
                ForEach(Gender.allCases, id: \.self) { gender in
                    Text(gender.rawValue.capitalized).tag(gender)
                }
            }
        }
    }
    
    private var physicalStatsSection: some View {
        Section("Physical Stats") {
            HStack {
                Text("Weight")
                Spacer()
                TextField("Weight", text: $weightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text(draft.unit.rawValue)
            }
            
            HStack {
                Text("Height")
                Spacer()
                TextField("Height in cm", text: $heightText)
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
                Text("cm")
            }
        }
    }
    
    private var trainingSection: some View {
        Section("Training") {
            Picker("Goal", selection: $draft.goal) {
                ForEach(GoalType.allCases, id: \.self) { goal in
                    Text(goal.rawValue).tag(goal)
                }
            }
            
            Picker("Experience", selection: $draft.experience) {
                ForEach(ExperienceLevel.allCases, id: \.self) { level in
                    Text(level.rawValue.capitalized).tag(level)
                }
            }
        }
    }
    
    private var continueSection: some View {
        Section {
            NavigationLink(destination: SplitTemplatePickerView(draft: draft)) {
                Text("Continue")
                    .frame(maxWidth: .infinity)
                    .fontWeight(.medium)
            }
            .disabled(draft.firstName.isEmpty || draft.weight == nil || draft.heightCm == nil)
        }
    }
    
    private func setupInitialValues() {
        // Only set defaults if user hasn't entered anything
        if weightText.isEmpty {
            let defaultWeight = draft.unit == .kg ? 70.0 : 154.0
            draft.weight = defaultWeight
            weightText = String(defaultWeight)
        }
        
        if heightText.isEmpty {
            let defaultHeight = 170.0
            draft.heightCm = defaultHeight
            heightText = String(defaultHeight)
        }
    }
}
