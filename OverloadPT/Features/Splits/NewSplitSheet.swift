//
//  NewSplitSheet.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//


import SwiftUI
import SwiftData

struct NewSplitSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    
    @State private var name = ""
    @State private var selectedTemplate: SplitTemplate? = SplitTemplate.catalog.first
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Split Name") {
                    TextField("Split name", text: $name)
                }
                
                Section {
                    Text("Choose a template for your split")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } header: {
                    Text("Split Template")
                }
                
                ForEach(SplitTemplate.catalog) { template in
                    Section {
                        Button(action: {
                            selectedTemplate = template
                        }) {
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    Text(template.name)
                                        .font(.headline)
                                    
                                    Spacer()
                                    
                                    if selectedTemplate?.id == template.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .imageScale(.large)
                                    } else {
                                        Image(systemName: "circle")
                                            .foregroundColor(.gray)
                                            .imageScale(.large)
                                    }
                                }
                                
                                // Show days with descriptions
                                ForEach(template.dayTitles, id: \.self) { day in
                                    HStack(alignment: .top) {
                                        Text("• \(day)")
                                            .fontWeight(.medium)
                                        
                                        if let muscles = musclesFor(title: day) {
                                            Text(muscles)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .padding(.leading, 4)
                                }
                                
                                Text("Weekly schedule: \(scheduleDescriptionFor(template))")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 2)
                            }
                        }
                        .buttonStyle(.plain)
                        .contentShape(Rectangle())
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTemplate?.id == template.id ? Color.blue.opacity(0.1) : Color.clear)
                        )
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("New Split")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", role: .cancel) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create Split") { save() }
                        .disabled(name.isEmpty || selectedTemplate == nil)
                }
            }
        }
    }
    
    private func save() {
        guard let template = selectedTemplate else { return }
        
        // Create split with the name
        let split = WorkoutSplit(name: name)
        
        // Add days from template
        for dayTitle in template.dayTitles {
            split.days.append(SplitDay(title: dayTitle))
        }
        
        // Set workout days based on template
        if template.dayTitles.count == 3 {
            split.workoutDays = [1, 3, 5] // Monday, Wednesday, Friday
        } else if template.dayTitles.count == 2 {
            split.workoutDays = [1, 4] // Monday, Thursday
        } else if template.dayTitles.count == 1 {
            split.workoutDays = [1, 3, 5] // M/W/F for full body
        } else if template.dayTitles.count == 6 {
            split.workoutDays = [1, 2, 3, 4, 5, 6] // All days except Sunday
        } else {
            split.workoutDays = [1, 3, 5]
        }
        
        ctx.insert(split)
        try? ctx.save()
        dismiss()
    }
    
    // Helper function to describe muscles for each day
    private func musclesFor(title: String) -> String? {
        switch title.lowercased() {
        case "push": return "Chest, Shoulders, Triceps"
        case "pull": return "Back, Biceps"
        case "legs": return "Quads, Hamstrings, Glutes"
        case "upper": return "Chest, Back, Shoulders, Arms"
        case "lower": return "Quads, Hamstrings, Glutes, Calves"
        case "chest & back": return "Chest, Back, Core"
        case "shoulders & arms": return "Shoulders, Biceps, Triceps"
        case "full body": return "All major muscle groups"
        default: return nil
        }
    }
    
    private func scheduleDescriptionFor(_ template: SplitTemplate) -> String {
        switch template.dayTitles.count {
        case 1: return "3x weekly (M/W/F)"
        case 2: return "2x weekly (M/Th)"
        case 3: return "3x weekly (M/W/F)"
        case 6: return "6x weekly"
        default: return "\(template.dayTitles.count)x weekly"
        }
    }
}
