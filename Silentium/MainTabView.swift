//
//  MainTabView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct MainTabView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var onboardingStep: Int = 0
    @StateObject private var appEngine = TinnitusAppEngine()
    
    var body: some View {
        Group {
            if !hasCompletedOnboarding {
                switch onboardingStep {
                case 0:
                    WelcomeView(hasStarted: Binding(
                        get: { onboardingStep > 0 },
                        set: { if $0 { onboardingStep = 1 } }
                    ))
                    
                case 1:
                    ImportantNoticeView(onNext: {
                        withAnimation(.easeInOut) { onboardingStep = 2 }
                    })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    
                case 2:
                    AppInfoView(onNext: {
                        withAnimation(.easeInOut) { onboardingStep = 3 }
                    })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                    
                case 3:
                    ToneFinderView(engine: appEngine, isFirstTime: true, onComplete: {
                        withAnimation(.spring()) {
                            hasCompletedOnboarding = true
                        }
                    })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .opacity))
                    
                default:
                    WelcomeView(hasStarted: .constant(false))
                }
            } else {
                TabView {
                    SoundsView()
                        .tabItem { Label("Sounds", systemImage: "music.pages") }
                    
                    SleepView(engine: appEngine)
                        .tabItem { Label("Sleep", systemImage: "moon.zzz.fill") }
                }
                .accentColor(.orange)
                .environmentObject(appEngine)
                .sheet(isPresented: $appEngine.isPlayerPresentedFullScreen) {
                    if let trackMeta = appEngine.currentSelectedSoundMetadata {
                        PlayerView(
                            engine: appEngine,
                            title: trackMeta.title,
                            subtitle: trackMeta.subtitle,
                            soundType: trackMeta.key
                        )
                        .presentationDetents([.large])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(28)
                    }
                }
            }
        }
    }
}
