//
//  SplitTemplate.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//

import Foundation

struct SplitTemplate: Identifiable, Hashable {   // ← add Hashable
    let id = UUID()
    let name: String
    let dayTitles: [String]

    static let catalog: [SplitTemplate] = [
        .init(name: "Push / Pull / Legs",
              dayTitles: ["Push", "Pull", "Legs"]),
        .init(name: "Upper / Lower",
              dayTitles: ["Upper", "Lower"]),
        .init(name: "Full-Body 3-Day",
              dayTitles: ["Full Body"]),
        .init(name: "Arnold (PPL x2)",
              dayTitles: ["Chest & Back", "Shoulders & Arms", "Legs"])
    ]
}


