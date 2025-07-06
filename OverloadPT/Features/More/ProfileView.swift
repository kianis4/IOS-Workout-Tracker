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
    private var p: UserProfile? { profiles.first }

    var body: some View {
        Form {
            Section("Account") {
                row("Name", p?.firstName)
                row("Units", p?.unit == .kg ? "Kilograms" : "Pounds")
            }
            Section("Metrics") {
                if let h = p?.heightCm { row("Height", "\(Int(h)) cm") }
                if let w = p?.currentWeight {
                    row("Weight", String(format: "%.1f %@", w,
                                         p?.unit == .kg ? "kg":"lb"))
                }
                row("Gender", p?.gender.rawValue.capitalized)

                if let h = p?.heightCm {
                    row("Height", "\(Int(h)) cm")
                }
            }
            Section("Training") {
                row("Goal", p?.goal.rawValue)
                row("Experience", p?.experience.rawValue.capitalized)
            }
            
        }
        .navigationTitle("Profile")
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
