//
//  MainTabView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct MainTabView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var showingFirstTimeTest = false
    
    // Create a single instance of TinnitusAppEngine to be shared across views
    @StateObject private var appEngine = TinnitusAppEngine()
    
    var body: some View {
        if !hasCompletedOnboarding {
            if !showingFirstTimeTest {
                // Step 1: Normal Screen Welcome
                WelcomeView(hasStarted: $showingFirstTimeTest)
            } else {
                // Step 2: Normal Screen Test (Onboarding)
                // Pass the shared appEngine instance to ToneFinderView
                ToneFinderView(engine: appEngine, isFirstTime: true, onComplete: {
                    hasCompletedOnboarding = true
                })
            }
        } else {
            // Step 3: Main App
            TabView {
                TherapyMixerView(engine: appEngine)
                    .tabItem { Label("Mixer", systemImage: "slider.horizontal.3") }
                
                BioReliefView(engine: appEngine)
                    .tabItem { Label("Relief", systemImage: "heart.text.square.fill") }
                
                SettingsView()
                    .tabItem { Label("Settings", systemImage: "gearshape.2.fill") }
            }
            .accentColor(.orange)
            // Kept in case internal subviews require implicit Environment access
            .environmentObject(appEngine)
        }
    }
}
