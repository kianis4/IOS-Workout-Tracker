//
//  AppState.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//


import Foundation
import Combine
import SwiftUI
import SwiftData

/// High-level flow controller for the whole app.
@MainActor
final class AppState: ObservableObject {
    enum FlowStep { case authLaunch, onboarding, main }

    @Published var step: FlowStep

    @AppStorage("onboarded") private var onboarded = false
    @AppStorage("signedIn")  private var signedIn  = false

    let container: ModelContainer   // pass from App

    init(container: ModelContainer) {
        self.container = container
        // temporary init to satisfy Swift’s “all stored properties” rule
        self.step = .authLaunch

        // decide real first screen
        if !signedIn {
            self.step = .authLaunch
        } else if !onboarded {
            self.step = .onboarding
        } else {
            self.step = .main
        }
    }


    // MARK: transitions
    func signedInSuccessfully()  { signedIn = true;  step = .onboarding }
    func finishedOnboarding()    { onboarded = true; step = .main }
}
