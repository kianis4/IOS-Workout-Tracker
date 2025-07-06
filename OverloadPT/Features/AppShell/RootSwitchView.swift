//
//  RootSwitchView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//


import SwiftUI

/// Chooses which top-level flow to show based on AppState.
struct RootSwitchView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        switch app.step {
        case .authLaunch:   AuthLaunchView()
        case .onboarding:   OnboardingFlowView()
        case .main:         RootTabs()
        }
    }
}
