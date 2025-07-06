//
//  SplitsListView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//

import SwiftUI
import SwiftData

struct SplitsListView: View {
    @Query(sort: \WorkoutSplit.name) private var splits: [WorkoutSplit]
    @Environment(\.modelContext) private var ctx

    @State private var showNew = false
    @State private var editMode = EditMode.inactive
    @State private var splitToDelete: WorkoutSplit?
    @State private var showDeleteConfirmation = false

    var body: some View {
        NavigationStack {
            List {
                // Optional: Active Split section
                if let activeSplit = splits.first(where: { $0.isActive }) {
                    Section("Active Split") {
                        NavigationLink {
                            SplitDetailView(split: activeSplit)
                        } label: {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text(activeSplit.name)
                                    .fontWeight(.medium)
                            }
                        }
                    }
                }

                Section("Your Splits") {
                    ForEach(splits) { split in
                        NavigationLink {
                            SplitDetailView(split: split)
                        } label: {
                            HStack {
                                Text(split.name)
                                
                                Spacer()
                                
                                if split.isActive && editMode == .inactive {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else if !split.isActive && editMode == .inactive {
                                    Button {
                                        toggleActive(to: split)
                                    } label: {
                                        Text("Activate")
                                            .font(.caption)
                                            .padding(4)
                                            .background(Color.blue.opacity(0.1))
                                            .cornerRadius(4)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    .onDelete(perform: deleteSelected)
                }
            }
            .navigationTitle("Workout Splits")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showNew = true } label: {
                        Label("New Split", systemImage: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton()
                }
            }
            .environment(\.editMode, $editMode)
            .sheet(isPresented: $showNew) {
                NewSplitSheet().presentationDetents([.medium])
            }
            .alert("Delete Split?", isPresented: $showDeleteConfirmation, presenting: splitToDelete) { split in
                Button("Cancel", role: .cancel) {}
                Button("Delete", role: .destructive) {
                    withAnimation {
                        if split.isActive, let newActive = splits.first(where: { $0.id != split.id }) {
                            toggleActive(to: newActive)
                        }
                        ctx.delete(split)
                        try? ctx.save()
                    }
                }
            } message: { split in
                Text("Are you sure you want to delete '\(split.name)'? This cannot be undone.")
            }
        }
    }

    private func deleteSelected(at indexSet: IndexSet) {
        guard let index = indexSet.first else { return }
        
        let splitToRemove = splits[index]
        // Show confirmation alert
        self.splitToDelete = splitToRemove
        self.showDeleteConfirmation = true
    }

    private func toggleActive(to target: WorkoutSplit) {
        do {
            for s in try ctx.fetch(FetchDescriptor<WorkoutSplit>()) {
                s.isActive = (s.id == target.id)
            }
        } catch {
            print("Toggle active failed: \(error)")
        }
    }
}
