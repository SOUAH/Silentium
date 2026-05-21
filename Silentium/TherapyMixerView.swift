//
//  TherapyMixerView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//


import SwiftUI

struct TherapyMixerView: View {
    // Inject the engine to access real-time calibratedFrequency
    @ObservedObject var engine: TinnitusAppEngine
    
    @State private var selectedNoise = "White" // Match default noise item
    @State private var selectedMode = "Calm"
    @State private var isPlaying = false
    @State private var showingTest = false
    
    let noises = [
        ("White", "cloud.fill", Color.gray),
        ("Rain", "cloud.rain.fill", Color.blue),
        ("Ocean", "water.waves", Color.teal),
        ("Wind", "wind", Color.indigo)
    ]
    
    let modes = [
        ("Calm", "apple.meditate"),
        ("Focus", "target"),
        ("Sleep", "moon.zzz.fill")
    ]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 25) {
                // 1. Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Therapy Mix")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 18)
                    
                    Spacer()
                    
                    Button(action: { showingTest = true }) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 38))
                            .foregroundStyle(AppTheme.accentGradient)
                    }
                }
                .padding(.horizontal)

                // DISPLAY REAL DATA: Accessing engine.calibratedFrequency
                Text("Tinnitus Notch: \(Int(engine.calibratedFrequency)) Hz Active")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black.opacity(0.6))
                
                // 2. Therapy Modes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Therapy Modes")
                        .font(.system(size: 20, weight: .bold))
                        .padding(.horizontal)
                        .foregroundColor(.black)
                    
                    HStack(spacing: 12) {
                        ForEach(modes, id: \.0) { mode in
                            ModeCard(
                                title: mode.0,
                                icon: mode.1,
                                isSelected: selectedMode == mode.0,
                                action: { selectedMode = mode.0 }
                            )
                        }
                    }
                    .padding(.horizontal)
                }

                // 3. Masking Sounds
                VStack(alignment: .leading, spacing: 12) {
                    Text("Masking Sounds")
                        .font(.system(size: 20, weight: .bold))
                        .padding(.horizontal)
                        .foregroundColor(.black)
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(noises, id: \.0) { noise in
                                SoundCard(
                                    title: noise.0,
                                    icon: noise.1,
                                    color: noise.2,
                                    isSelected: selectedNoise == noise.0,
                                    action: {
                                        selectedNoise = noise.0
                                        
                                        // UPDATED: If engine is currently master-playing, switch live synthesis vectors immediately
                                        if isPlaying {
                                            engine.startProceduralSound(type: noise.0)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                
                Spacer()
                
                // 4. Playback Control
                Button(action: {
                    isPlaying.toggle()
                    
                    // UPDATED: Explicit routing into our audio synthesis pipelines
                    if isPlaying {
                        engine.startProceduralSound(type: selectedNoise)
                    } else {
                        engine.stopMaskingSound()
                    }
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 30))
                                .foregroundStyle(AppTheme.accentGradient)
                        )
                        .shadow(color: Color.black.opacity(0.15), radius: 10, y: 5)
                }
                .padding(.bottom, 20)
            }
        }
        .fullScreenCover(isPresented: $showingTest) {
            ToneFinderView(engine: engine, isFirstTime: false)
        }
    }
}

// MARK: - Core Grid and Scrolling UI Elements

struct SoundCard: View {
    let title: String
    let icon: String
    let color: Color
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .bottomLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .frame(width: 150, height: 210)
                
                LinearGradient(
                    gradient: Gradient(colors: [.clear, .black.opacity(0.5)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(12)
                
                VStack(alignment: .leading, spacing: 10) {
                    Image(systemName: icon)
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                    
                    Text(title)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.leading)
                }
                .padding(15)
            }
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isSelected)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ModeCard: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if isSelected {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(Color.white)
                } else {
                    Image(systemName: icon)
                        .font(.system(size: 22))
                        .foregroundStyle(AppTheme.accentGradient)
                }
                
                Text(title)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(isSelected ? .white : .black)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(isSelected ? Color.black : Color.white)
            .cornerRadius(18)
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: 3)
        }
    }
}
