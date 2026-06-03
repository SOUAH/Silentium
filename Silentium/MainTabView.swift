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
        Group {
            if !hasCompletedOnboarding {
                // Onboarding Workflow Routing
                if !showingFirstTimeTest {
                    WelcomeView(hasStarted: $showingFirstTimeTest)
                } else {
                    ToneFinderView(engine: appEngine, isFirstTime: true, onComplete: {
                        hasCompletedOnboarding = true
                    })
                }
            } else {
                // Core Tab Navigation Architecture
                TabView {
                    TherapyMixerView() // 👈 FIXED: Dropped manual init parameters
                        .tabItem { Label("Mixer", systemImage: "slider.horizontal.3") }
                    
                    BreathingView(engine: appEngine)
                        .tabItem { Label("Focus", systemImage: "target") }
                    
                    SleepView(engine: appEngine)
                        .tabItem { Label("Sleep", systemImage: "moon.zzz.fill") }
                }
                .accentColor(.orange)
                .environmentObject(appEngine) // 👈 Injects engine globally to all tabs and nested child modals
                // Full-Screen Cover Panel matching Apple Music Presentation Styles
                .fullScreenCover(isPresented: $appEngine.isPlayerPresentedFullScreen) {
                    if let trackMeta = appEngine.currentSelectedSoundMetadata {
                        SleepPlayerView(
                            engine: appEngine,
                            title: trackMeta.title,
                            subtitle: trackMeta.subtitle,
                            soundType: trackMeta.key
                        )
                    }
                }
            }
        }
    }
}
