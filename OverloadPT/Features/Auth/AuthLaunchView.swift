//
//  AuthLaunchView.swift
//  OverloadPT
//
//  Created by Suleyman Kiani on 2025-06-14.
//


import SwiftUI

struct AuthLaunchView: View {
    @EnvironmentObject private var app: AppState

    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 72))
            Text("Overload PT")
                .font(.largeTitle.weight(.bold))
            Spacer()
            Button("Continue") {              // placeholder → skips straight in
                app.signedInSuccessfully()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .padding()
    }
}
