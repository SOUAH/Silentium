//
//  PlayerView.swift
//  Silentium
//
//  Created by Souha Aouididi on 22/05/26.
//

import SwiftUI

enum BreathingPattern {
    case none
    case resonant
    case sleep478
}

struct PlayerView: View {
    @ObservedObject var engine: TinnitusAppEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String
    let soundType: String

    @State private var sessionMinutes: Int = 45
    
    @State private var dynamicBreathingMode: BreathingPattern = .none
    @State private var breathingCirclePhase = 0
    @State private var breathingText = "Breathe In"
    @State private var breathScale: CGFloat = 1.0
    
    @State private var remainingSeconds: Int = 2700
    @State private var totalSeconds: Int = 2700
    @State private var masterTimer: Timer? = nil
    @State private var isTimerRunning = false
    
    private var isSleepCategoryTrack: Bool {
        soundType == "brown_sleep" || soundType == "sub_delta"
    }
    
    private var soundColors: [Color] {
        switch soundType {
        case "Torrential Downpour", "Steam Vent Meditation", "white_sleep":
            return [Color(red: 0.12, green: 0.35, blue: 0.75), Color(red: 0.35, green: 0.62, blue: 0.95)]
        case "Rhythmic Ocean Swells", "Wind Through Pine Needles", "Steady Canopy Rain":
            return [Color(red: 0.78, green: 0.24, blue: 0.44), Color(red: 0.92, green: 0.48, blue: 0.62)]
        case "Distant Rolling Thunder", "Subterranean Canyon Rift", "brown_sleep", "sub_delta":
            return [Color(red: 0.42, green: 0.26, blue: 0.16), Color(red: 0.68, green: 0.48, blue: 0.32)]
        default:
            return [Color(red: 0.40, green: 0.20, blue: 0.15), Color(red: 0.65, green: 0.35, blue: 0.25)]
        }
    }
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    soundColors.first?.opacity(colorScheme == .dark ? 0.5 : 0.25) ?? .clear,
                    AppTheme.background
                ],
                startPoint: .topLeading, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button(action: {
                        engine.isPlayerPresentedFullScreen = false
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(AppTheme.text.opacity(0.75))
                            .frame(width: 42, height: 42)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                if dynamicBreathingMode != .none {
                    VStack(spacing: 40) {
                        VStack(spacing: 6) {
                            Text(dynamicBreathingMode == .resonant ? "Resonant Coherence Tuning" : "4-7-8 Sleep Induction")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(AppTheme.text)
                            
                            Text(dynamicBreathingMode == .resonant ? "Balances the autonomic nervous system to reduce focus on your tinnitus" : "Triggers the parasympathetic shift for instant rest")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.text.opacity(0.5))
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 30)
                        }
                        
                        ZStack {
                            Circle()
                                .stroke(AppTheme.text.opacity(0.05), lineWidth: 10)
                                .frame(width: 180, height: 180)
                            Circle()
                                .fill(LinearGradient(colors: soundColors, startPoint: .top, endPoint: .bottom).opacity(0.3))
                                .frame(width: 160, height: 160)
                                .scaleEffect(breathScale)
                            Text(breathingText)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppTheme.text)
                        }
                        .frame(height: 200)
                        
                        Button(action: { stopBreathingExerciseBridge(shouldStartTimer: dynamicBreathingMode == .sleep478) }) {
                            Text(dynamicBreathingMode == .sleep478 ? "Skip Directly to Sleep Mode" : "Return to Player Dashboard")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.text.opacity(0.6))
                                .padding(.horizontal, 20)
                                .padding(.vertical, 12)
                                .background(Capsule().stroke(AppTheme.text.opacity(0.2), lineWidth: 1))
                        }
                        .buttonStyle(.plain)
                    }
                    .transition(.opacity)
                } else {
                    VStack(spacing: 0) {
                        LargeWaveformVisual(isPlaying: engine.isPlaying, soundColors: soundColors)
                            .frame(maxWidth: .infinity)
                            .padding(.horizontal, 40)

                        Spacer().frame(height: 40)

                        VStack(spacing: 6) {
                            Text(title)
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(AppTheme.text)
                            Text(subtitle)
                                .font(.system(size: 15))
                                .foregroundColor(AppTheme.text.opacity(0.5))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.horizontal, 40)

                        Spacer().frame(height: 32)

                        VStack(spacing: 8) {
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(AppTheme.text.opacity(0.12)).frame(height: 4)
                                    Capsule()
                                        .fill(LinearGradient(colors: soundColors, startPoint: .leading, endPoint: .trailing))
                                        .frame(width: geo.size.width * CGFloat(Double(totalSeconds - remainingSeconds) / Double(totalSeconds)), height: 4)
                                }
                            }
                            .frame(height: 4)
                            
                            HStack {
                                Text(elapsedTime)
                                Spacer()
                                Text(timeString(from: remainingSeconds))
                            }
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(AppTheme.text.opacity(0.4))
                        }
                        .padding(.horizontal, 40)

                        Spacer().frame(height: 32)

                        HStack(spacing: 50) {
                            Menu {
                                ForEach([15, 30, 45, 60, 90], id: \.self) { mins in
                                    Button("\(mins) minutes") {
                                        sessionMinutes = mins
                                        remainingSeconds = mins * 60
                                        totalSeconds = mins * 60
                                    }
                                }
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "timer").font(.system(size: 20))
                                    Text("\(sessionMinutes)m").font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(AppTheme.text.opacity(0.7))
                            }

                            Button {
                                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                                if engine.isPlaying {
                                    deactivateSleepTimerSequence()
                                } else {
                                    engine.startProceduralSound(type: soundType)
                                    activateSleepTimerSequence()
                                }
                            } label: {
                                Image(systemName: engine.isPlaying ? "stop.fill" : (isSleepCategoryTrack ? "moon.stars.fill" : "play.fill"))
                                    .font(.system(size: 30))
                                    .foregroundColor(AppTheme.background)
                                    .frame(width: 76, height: 76)
                                    .background(Circle().fill(AppTheme.text))
                            }
                            .buttonStyle(.plain)

                            Button {
                                startBreathingExerciseBridge(mode: isSleepCategoryTrack ? .sleep478 : .resonant)
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "lungs.fill").font(.system(size: 20))
                                    Text("Breathe").font(.system(size: 11, weight: .bold))
                                }
                                .foregroundColor(AppTheme.text.opacity(0.7))
                            }
                        }
                    }
                    .transition(.opacity)
                }
                Spacer()
            }
        }
        .onAppear {
            if engine.isPlaying { activateSleepTimerSequence() }
        }
        .onDisappear {
            masterTimer?.invalidate()
            masterTimer = nil
        }
    }

    private var elapsedTime: String {
        let elapsed = totalSeconds - remainingSeconds
        return String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
    }
    
    private func timeString(from seconds: Int) -> String {
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    
    private func startBreathingExerciseBridge(mode: BreathingPattern) {
        breathingCirclePhase = 0
        withAnimation(.easeInOut(duration: 0.4)) { dynamicBreathingMode = mode }
        engine.startProceduralSound(type: soundType)
        executeBreathingAnimationLoop()
    }
    
    private func stopBreathingExerciseBridge(shouldStartTimer: Bool) {
        withAnimation(.easeInOut(duration: 0.4)) { dynamicBreathingMode = .none }
        if shouldStartTimer {
            activateSleepTimerSequence()
        } else {
            engine.stopMaskingSound()
        }
    }
    
    private func executeBreathingAnimationLoop() {
        guard dynamicBreathingMode != .none else { return }
        if dynamicBreathingMode == .resonant {
            if breathingCirclePhase == 0 {
                breathingText = "Inhale"
                withAnimation(.linear(duration: 5.0)) { breathScale = 1.35 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.breathingCirclePhase = 2
                    self.executeBreathingAnimationLoop()
                }
            } else {
                breathingText = "Exhale"
                withAnimation(.easeInOut(duration: 5.0)) { breathScale = 1.0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    self.breathingCirclePhase = 0
                    self.executeBreathingAnimationLoop()
                }
            }
        } else if dynamicBreathingMode == .sleep478 {
            if breathingCirclePhase == 0 {
                textFadeAnimation(to: "Inhale")
                withAnimation(.linear(duration: 4.0)) { breathScale = 1.35 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    self.breathingCirclePhase = 1
                    self.executeBreathingAnimationLoop()
                }
            } else if breathingCirclePhase == 1 {
                textFadeAnimation(to: "Hold")
                DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                    self.breathingCirclePhase = 2
                    self.executeBreathingAnimationLoop()
                }
            } else {
                textFadeAnimation(to: "Exhale")
                withAnimation(.easeInOut(duration: 8.0)) { breathScale = 1.0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                    self.breathingCirclePhase = 0
                    self.stopBreathingExerciseBridge(shouldStartTimer: true)
                }
            }
        }
    }
    
    private func textFadeAnimation(to newText: String) {
        withAnimation(.easeOut(duration: 0.2)) { self.breathingText = newText }
    }
    
    private func activateSleepTimerSequence() {
        masterTimer?.invalidate()
        isTimerRunning = true
        masterTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if self.engine.isPlaying {
                if self.remainingSeconds > 0 {
                    self.remainingSeconds -= 1
                    if self.remainingSeconds == 600 {
                        engine.startIntelligentSleepFade(durationMinutes: 10)
                    }
                } else {
                    self.deactivateSleepTimerSequence()
                }
            }
        }
    }
    
    private func deactivateSleepTimerSequence() {
        isTimerRunning = false
        dynamicBreathingMode = .none
        masterTimer?.invalidate()
        masterTimer = nil
        engine.stopMaskingSound()
        engine.stopSleepFadeEngine()
        remainingSeconds = sessionMinutes * 60
    }
}

struct LargeWaveformVisual: View {
    let isPlaying: Bool
    let soundColors: [Color]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<16) { text in
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: soundColors, startPoint: .top, endPoint: .bottom))
                    .frame(width: 6, height: CGFloat([45, 90, 120, 65, 140, 70, 110, 50, 85, 130, 95, 60, 105, 40, 75, 115][text]))
                    .scaleEffect(y: isPlaying ? 1.0 : 0.15, anchor: .center)
                    .animation(
                        isPlaying ? .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(text) * 0.03) : .default,
                        value: isPlaying
                    )
            }
        }
        .frame(height: 160)
    }
}
