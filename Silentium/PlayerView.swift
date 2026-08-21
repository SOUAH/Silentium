//
//  PlayerView.swift
//  Silentium
//

import SwiftUI

enum BreathingPattern {
    case none, resonant, sleep478
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
    @State private var totalSeconds:     Int = 2700
    @State private var masterTimer: Timer? = nil
    @State private var isTimerRunning = false

    private var isSleepCategoryTrack: Bool {
        soundType == "brown_sleep" || soundType == "sub_delta"
    }

    private var soundColors: [Color] {
        switch soundType {
        case "Torrential Downpour", "Misty Waterfall Veil", "Heavy Rain Storm",
             "Thunder & Light Rain", "white_sleep":
            return [Color(red: 0.12, green: 0.35, blue: 0.75), Color(red: 0.35, green: 0.62, blue: 0.95)]
        case "Rhythmic Ocean Swells", "Wind Through Pine Needles", "Gentle Meadow Stream",
             "Birds & Jungle Morning", "Dry Autumn Leaves", "Liquid Bubble Flow":
            return [Color(red: 0.78, green: 0.24, blue: 0.44), Color(red: 0.92, green: 0.48, blue: 0.62)]
        default:
            return [Color(red: 0.42, green: 0.26, blue: 0.16), Color(red: 0.68, green: 0.48, blue: 0.32)]
        }
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [soundColors.first?.opacity(colorScheme == .dark ? 0.5 : 0.25) ?? .clear, AppTheme.background],
                startPoint: .topLeading,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Close button – iOS HIG: .plain on a circular button
                HStack {
                    Spacer()
                    Button {
                        engine.isPlayerPresentedFullScreen = false
                        dismiss()
                    } label: {
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
                    breathingPanel
                        .transition(.opacity)
                } else {
                    mainPanel
                        .transition(.opacity)
                }

                Spacer()
            }
        }
        .onAppear {
            // Only auto-start timer if audio is already playing
            if engine.isPlaying { activateSleepTimerSequence() }
        }
        .onDisappear {
            masterTimer?.invalidate()
            masterTimer = nil
        }
    }

    // MARK: - Main Panel
    private var mainPanel: some View {
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

            // Progress bar
            VStack(spacing: 8) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(AppTheme.text.opacity(0.12)).frame(height: 4)
                        Capsule()
                            .fill(LinearGradient(colors: soundColors, startPoint: .leading, endPoint: .trailing))
                            .frame(width: geo.size.width * progress, height: 4)
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

            // Transport controls
            HStack(spacing: 50) {
                // Timer picker – iOS HIG: Menu label behaves like a tappable button
                Menu {
                    ForEach([15, 30, 45, 60, 90], id: \.self) { mins in
                        Button("\(mins) minutes") {
                            sessionMinutes  = mins
                            remainingSeconds = mins * 60
                            totalSeconds    = mins * 60
                        }
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "timer").font(.system(size: 20))
                        Text("\(sessionMinutes)m").font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(AppTheme.text.opacity(0.7))
                }

                // Play / Stop – iOS HIG: prominent filled-circle button
                Button {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    if engine.isPlaying {
                        deactivateSleepTimerSequence()
                    } else {
                        engine.startSound(type: soundType) // Updated to new startSound method
                        activateSleepTimerSequence()
                    }
                } label: {
                    Image(systemName: engine.isPlaying
                          ? "stop.fill"
                          : (isSleepCategoryTrack ? "moon.stars.fill" : "play.fill"))
                        .font(.system(size: 30))
                        .foregroundColor(AppTheme.background)
                        .frame(width: 76, height: 76)
                        .background(Circle().fill(AppTheme.text))
                }
                .buttonStyle(.plain)

                // Breathing button
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
    }

    // Breathing Panel
    private var breathingPanel: some View {
        VStack(spacing: 40) {
            VStack(spacing: 6) {
                Text(dynamicBreathingMode == .resonant ? "Resonant Coherence Tuning" : "4-7-8 Sleep Induction")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppTheme.text)
                Text(dynamicBreathingMode == .resonant
                     ? "Balances the autonomic nervous system to reduce focus on your tinnitus"
                     : "Triggers the parasympathetic shift for instant rest")
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

            // iOS HIG: secondary button as a bordered capsule
            Button {
                stopBreathingExerciseBridge(shouldStartTimer: dynamicBreathingMode == .sleep478)
            } label: {
                Text(dynamicBreathingMode == .sleep478 ? "Skip to Sleep Mode" : "Return to Player")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.text.opacity(0.6))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Capsule().stroke(AppTheme.text.opacity(0.2), lineWidth: 1))
            }
            .buttonStyle(.plain)
        }
    }

    // Helpers
    private var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(Double(totalSeconds - remainingSeconds) / Double(totalSeconds))
    }

    private var elapsedTime: String {
        let elapsed = totalSeconds - remainingSeconds
        return String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
    }

    private func timeString(from seconds: Int) -> String {
        String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }

    // Breathing Logic
    private func startBreathingExerciseBridge(mode: BreathingPattern) {
        breathingCirclePhase = 0
        withAnimation(.easeInOut(duration: 0.4)) { dynamicBreathingMode = mode }
        engine.startSound(type: soundType) // Updated to new startSound method
        executeBreathingAnimationLoop()
    }

    private func stopBreathingExerciseBridge(shouldStartTimer: Bool) {
        withAnimation(.easeInOut(duration: 0.4)) { dynamicBreathingMode = .none }
        if shouldStartTimer { activateSleepTimerSequence() }
        else { engine.stopMaskingSound() }
    }

    private func executeBreathingAnimationLoop() {
        guard dynamicBreathingMode != .none else { return }
        if dynamicBreathingMode == .resonant {
            if breathingCirclePhase == 0 {
                breathingText = "Inhale"
                withAnimation(.linear(duration: 5.0)) { breathScale = 1.35 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    breathingCirclePhase = 2; executeBreathingAnimationLoop()
                }
            } else {
                breathingText = "Exhale"
                withAnimation(.easeInOut(duration: 5.0)) { breathScale = 1.0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    breathingCirclePhase = 0; executeBreathingAnimationLoop()
                }
            }
        } else if dynamicBreathingMode == .sleep478 {
            if breathingCirclePhase == 0 {
                textFade("Inhale")
                withAnimation(.linear(duration: 4.0)) { breathScale = 1.35 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                    breathingCirclePhase = 1; executeBreathingAnimationLoop()
                }
            } else if breathingCirclePhase == 1 {
                textFade("Hold")
                DispatchQueue.main.asyncAfter(deadline: .now() + 7.0) {
                    breathingCirclePhase = 2; executeBreathingAnimationLoop()
                }
            } else {
                textFade("Exhale")
                withAnimation(.easeInOut(duration: 8.0)) { breathScale = 1.0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 8.0) {
                    breathingCirclePhase = 0
                    stopBreathingExerciseBridge(shouldStartTimer: true)
                }
            }
        }
    }

    private func textFade(_ text: String) {
        withAnimation(.easeOut(duration: 0.2)) { breathingText = text }
    }

    // Timer
    private func activateSleepTimerSequence() {
        masterTimer?.invalidate()
        isTimerRunning = true
        masterTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            guard engine.isPlaying else { return }
            if remainingSeconds > 0 {
                remainingSeconds -= 1
                if remainingSeconds == 600 { engine.startIntelligentSleepFade(durationMinutes: 10) }
            } else {
                deactivateSleepTimerSequence()
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
    private let barHeights: [CGFloat] = [45, 90, 120, 65, 140, 70, 110, 50, 85, 130, 95, 60, 105, 40, 75, 115]

    var body: some View {
        HStack(spacing: 6) {
            ForEach(Array(barHeights.enumerated()), id: \.offset) { index, height in
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: soundColors, startPoint: .top, endPoint: .bottom))
                    .frame(width: 6, height: height)
                    .scaleEffect(y: isPlaying ? 1.0 : 0.15, anchor: .center)
                    .animation(
                        isPlaying
                            ? .easeInOut(duration: 0.45).repeatForever(autoreverses: true).delay(Double(index) * 0.03)
                            : .default,
                        value: isPlaying
                    )
            }
        }
        .frame(height: 160)
    }
}

