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
    @StateObject private var appEngine = TinnitusAppEngine()
    
    var body: some View {
        if !hasCompletedOnboarding {
            if !showingFirstTimeTest {
                WelcomeView(hasStarted: $showingFirstTimeTest)
            } else {
                ToneFinderView(engine: appEngine, isFirstTime: true, onComplete: {
                    hasCompletedOnboarding = true
                })
            }
        } else {
            // Re-architected: Only 3 primary view tracks left in the core interface dock
            TabView {
                TherapyMixerView(engine: appEngine)
                    .tabItem { Label("Mixer", systemImage: "slider.horizontal.3") }
                
                BreathingView(engine: appEngine)
                    .tabItem { Label("Focus", systemImage: "target") }
                
                SleepView(engine: appEngine)
                    .tabItem { Label("Sleep", systemImage: "moon.zzz.fill") }
            }
            .accentColor(.orange)
            .environmentObject(appEngine)
        }
    }
}
