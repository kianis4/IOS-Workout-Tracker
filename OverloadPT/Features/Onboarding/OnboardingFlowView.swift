//
//  OnboardingFlowView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//

import SwiftUI

struct OnboardingFlowView: View {
    @StateObject private var draft = OnboardDraft()

    var body: some View {
        NavigationStack {
            ProfileCaptureView(draft: draft)            // step 1
        }
    }
}
