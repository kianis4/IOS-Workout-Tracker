//
//  RootTabs.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//


import SwiftUI

struct RootTabs: View {
    var body: some View {
        TabView {
            TodayView()
                .tabItem {
                    Label("Today", systemImage: "calendar.day.timeline.left")
                }
            SplitsListView()
                .tabItem { Label("Splits", systemImage: "list.bullet") }
            NavigationStack { ProfileView() }   // NEW
                .tabItem { Label("More", systemImage: "person.crop.circle") }
        }
    }
}
