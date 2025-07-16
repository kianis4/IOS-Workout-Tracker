//
//  ProfileView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//

import SwiftUI
import SwiftData
struct ProfileView: View {
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var context
    @State private var editMode = EditMode.inactive
    @State private var tempWeight: Double = 0
    @State private var tempHeight: Double = 0
    
    private var profile: UserProfile? { profiles.first }
    
    var body: some View {
        Form {
            Section("Account") {
                row("Name", profile?.firstName)
                row("Units", profile?.unit == .kg ? "Kilograms" : "Pounds")
            }
            
            Section("Metrics") {
                if let height = profile?.heightCm {
                    if editMode == .active {
                        HStack {
                            Text("Height")
                            Spacer()
                            TextField("Height", value: $tempHeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text("cm")
                        }
                    } else {
                        VStack(alignment: .trailing) {
                            HStack {
                                Text("Height")
                                Spacer()
                                Text("\(Int(height)) cm")
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("")
                                Spacer()
                                Text("\(heightInFeetInches(height)) ft")
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                
                if let weight = profile?.currentWeight {
                    if editMode == .active {
                        HStack {
                            Text("Weight")
                            Spacer()
                            TextField("Weight", value: $tempWeight, format: .number)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                                .frame(width: 60)
                            Text(profile?.unit.rawValue ?? "kg")
                        }
                    } else {
                        VStack(alignment: .trailing) {
                            HStack {
                                Text("Weight")
                                Spacer()
                                Text(formatWeight(weight, unit: profile?.unit ?? .kg))
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Text("")
                                Spacer()
                                Text(formatWeightInOtherUnit(weight, unit: profile?.unit ?? .kg))
                                    .font(.caption)
                                    .foregroundStyle(.tertiary)
                            }
                        }
                    }
                }
                
                row("Gender", profile?.gender.rawValue.capitalized)
            }
            
            Section("Training") {
                row("Goal", profile?.goal.rawValue)
                row("Experience", profile?.experience.rawValue.capitalized)
            }
        }
        .navigationTitle("Profile")
        .environment(\.editMode, $editMode)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if editMode == .active {
                    Button("Save") {
                        saveChanges()
                        editMode = .inactive
                    }
                } else {
                    Button("Edit") {
                        editMode = .active
                        tempWeight = profile?.currentWeight ?? 0
                        tempHeight = profile?.heightCm ?? 0
                    }
                }
            }
        }
    }
    
    private func saveChanges() {
        guard let profile = profile else { return }
        
        profile.currentWeight = tempWeight
        profile.heightCm = tempHeight
        
        try? context.save()
    }
    
    private func formatWeight(_ weight: Double, unit: MassUnit) -> String {
        String(format: "%.1f %@", weight, unit.rawValue)
    }
    
    private func formatWeightInOtherUnit(_ weight: Double, unit: MassUnit) -> String {
        if unit == .kg {
            let pounds = weight * 2.20462
            return String(format: "%.1f lb", pounds)
        } else {
            let kg = weight / 2.20462
            return String(format: "%.1f kg", kg)
        }
    }
    
    private func heightInFeetInches(_ cm: Double) -> String {
        let totalInches = cm / 2.54
        let feet = Int(totalInches / 12)
        let inches = Int(totalInches.truncatingRemainder(dividingBy: 12))
        return "\(feet)'\(inches)\""
    }
    
    @ViewBuilder
    private func row(_ name: String, _ value: String?) -> some View {
        HStack {
            Text(name)
            Spacer()
            Text(value ?? "-").foregroundStyle(.secondary)
        }
    }
}
