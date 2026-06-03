//
//  SleepPlayerView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 22/05/26.
//

import SwiftUI

struct SleepPlayerView: View {
    @ObservedObject var engine: TinnitusAppEngine
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    let title: String
    let subtitle: String
    let soundType: String

    @State private var sessionMinutes: Int = 30
    @State private var dragOffset: CGFloat = 0
    @State private var showBreathing = false
    
    // Timer synchronization states
    @State private var remainingSeconds: Int = 1800
    @State private var totalSeconds: Int = 1800
    @State private var countdownTimer: Timer? = nil
    @State private var isTimerRunning = false

    private var soundColors: [Color] {
        switch soundType {
        case "white_sleep", "Torrential Downpour", "Steam Vent Meditation":
            return [Color(red: 0.15, green: 0.25, blue: 0.45), Color(red: 0.25, green: 0.45, blue: 0.75)]
        case "sub_delta", "Wind Through Pine Needles", "Steady Canopy Rain":
            return [Color(red: 0.40, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]
        default:
            return [Color(red: 0.40, green: 0.20, blue: 0.15), Color(red: 0.65, green: 0.35, blue: 0.25)]
        }
    }
    
    private var progress: CGFloat {
        guard totalSeconds > 0 else { return 0 }
        return CGFloat(totalSeconds - remainingSeconds) / CGFloat(totalSeconds)
    }

    var body: some View {
        ZStack {
            // Full-bleed contextual spectrum background blur
            LinearGradient(
                colors: [
                    soundColors.first?.opacity(colorScheme == .dark ? 0.5 : 0.25) ?? .clear,
                    soundColors.count > 1 ? soundColors[1].opacity(colorScheme == .dark ? 0.25 : 0.12) : .clear,
                    AppTheme.background
                ],
                startPoint: .topLeading, endPoint: .bottom
            ).ignoresSafeArea()

            VStack(spacing: 0) {
                // Top drag indicator indicator
                Capsule()
                    .fill(AppTheme.text.opacity(0.2))
                    .frame(width: 40, height: 5)
                    .padding(.top, 12)

                Spacer()

                // Audio Waveform Render Area
                LargeWaveformVisual(isPlaying: engine.isPlaying, soundColors: soundColors)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 40)

                Spacer().frame(height: 40)

                // Sound Metadata Block
                VStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppTheme.text)
                    Text(subtitle)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.text.opacity(0.6))
                        .multilineTextAlignment(.center)
                    
                    // Live Audio Target Match Recommendation Badge
                    if let reasonText = engine.getRecommendationReason(for: soundType) {
                        HStack(spacing: 6) {
                            Image(systemName: "sparkles")
                            Text(reasonText)
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.orange.opacity(0.12))
                        .cornerRadius(8)
                        .padding(.top, 6)
                    }
                }
                .padding(.horizontal, 40)

                Spacer().frame(height: 32)

                // Timeline Progress Bar
                if isTimerRunning {
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                Capsule()
                                    .fill(AppTheme.text.opacity(0.12))
                                    .frame(height: 4)
                                Capsule()
                                    .fill(LinearGradient(colors: soundColors, startPoint: .leading, endPoint: .trailing))
                                    .frame(width: geo.size.width * progress, height: 4)
                            }
                        }
                        .frame(height: 4)
                        
                        HStack {
                            Text(elapsedTime)
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(AppTheme.text.opacity(0.4))
                            Spacer()
                            Text(timeString(from: remainingSeconds))
                                .font(.system(size: 11, weight: .medium, design: .monospaced))
                                .foregroundColor(AppTheme.text.opacity(0.4))
                        }
                    }
                    .padding(.horizontal, 40)
                }

                Spacer().frame(height: 28)

                // Control Strip
                HStack(spacing: 40) {
                    Menu {
                        ForEach([5, 15, 30, 45, 60], id: \.self) { mins in
                            Button("\(mins) minutes") {
                                sessionMinutes = mins
                                remainingSeconds = mins * 60
                                totalSeconds = mins * 60
                            }
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "timer")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.text.opacity(0.7))
                            Text("\(sessionMinutes)m")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.text.opacity(0.5))
                        }
                    }

                    Button {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()
                        
                        if engine.isPlaying {
                            engine.stopMaskingSound()
                            deactivateLocalTimer()
                        } else {
                            engine.startProceduralSound(type: soundType)
                            activateLocalTimer()
                        }
                    } label: {
                        Image(systemName: engine.isPlaying ? "stop.fill" : "play.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(AppTheme.accentGradient)
                            .frame(width: 72, height: 72)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 10, y: 4)
                            )
                    }

                    Button { showBreathing = true } label: {
                        VStack(spacing: 4) {
                            Image(systemName: "lungs.fill")
                                .font(.system(size: 18))
                                .foregroundColor(AppTheme.text.opacity(0.7))
                            Text("Breathe")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(AppTheme.text.opacity(0.5))
                        }
                    }
                }

                Spacer().frame(height: 32)

                // Volume Deck HUD
                VStack(spacing: 8) {
                    HStack(spacing: 10) {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.text.opacity(0.4))
                        
                        Slider(value: Binding(
                            get: { engine.isPlaying ? 0.7 : 0.0 },
                            set: { _ in }
                        ), in: 0...1)
                        .tint(.orange)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 11))
                            .foregroundColor(AppTheme.text.opacity(0.4))
                    }
                    .padding(.horizontal, 40)
                    
                    Label("Safe Listening ON", systemImage: "shield.checkmark.fill")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color(red: 0.22, green: 0.80, blue: 0.45).opacity(0.8))
                }

                Spacer()
            }
        }
        .gesture(
            DragGesture()
                .onChanged { value in dragOffset = value.translation.height }
                .onEnded { value in
                    if value.translation.height > 120 {
                        engine.isPlayerPresentedFullScreen = false
                        dismiss()
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { dragOffset = 0 }
                    }
                }
        )
        .offset(y: max(0, dragOffset))
        .onAppear {
            remainingSeconds = sessionMinutes * 60
            totalSeconds = sessionMinutes * 60
            if engine.isPlaying {
                activateLocalTimer()
            }
        }
        .onDisappear {
            deactivateLocalTimer()
        }
    }

    // MARK: - Automation Mechanics
    
    private var elapsedTime: String {
        let elapsed = totalSeconds - remainingSeconds
        return String(format: "%02d:%02d", elapsed / 60, elapsed % 60)
    }
    
    private func timeString(from seconds: Int) -> String {
        return String(format: "%02d:%02d", seconds / 60, seconds % 60)
    }
    
    private func activateLocalTimer() {
        isTimerRunning = true
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            if remainingSeconds > 0 {
                remainingSeconds -= 1
            } else {
                engine.stopMaskingSound()
                deactivateLocalTimer()
            }
        }
    }
    
    private func deactivateLocalTimer() {
        isTimerRunning = false
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
}

struct LargeWaveformVisual: View {
    let isPlaying: Bool
    let soundColors: [Color]
    
    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<16) { index in
                RoundedRectangle(cornerRadius: 3)
                    .fill(LinearGradient(colors: soundColors, startPoint: .top, endPoint: .bottom))
                    .frame(width: 6, height: CGFloat([45, 90, 120, 65, 140, 70, 110, 50, 85, 130, 95, 60, 105, 40, 75, 115][index]))
                    .scaleEffect(y: isPlaying ? 1.0 : 0.15, anchor: .center)
                    .animation(
                        isPlaying ? .easeInOut(duration: 0.45)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.03) : .default,
                        value: isPlaying
                    )
            }
        }
        .frame(height: 160)
    }
}
