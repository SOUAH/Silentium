//
//  SleepView.swift
//  Silentium
//
//  Created by Souha Aouididi on 22/05/26.
//

import SwiftUI

struct SleepView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var engine: TinnitusAppEngine
    
    // Player and layout selection targets
    @State private var selectedPlayerSound: (title: String, subtitle: String, key: String)? = nil
    @State private var showingPlayerSheet = false
    @State private var selectedTimerMinutes: Int? = nil
    @AppStorage("sleepNotchAttenuation") private var isNotchAttenuated = true
    
    // Custom Generated Sound Data Source (Stacked Vertically & Full Width)
    let fallAsleepSounds = [
        ("Deep Brown Noise", "Deep waterfall rumble. Perfect for masking high-frequency ringing.", "water.waves", "brown_sleep"),
        ("Sub-Delta Modulation", "Fluid 10s breathing swells that coax your brain into deep sleep.", "waveform.path.ecg", "sub_delta")
    ]
    
    let timerOptions = [15, 30, 45, 60]
    
    var body: some View {
        ZStack {
            // Immersive native pure black background
            Color.black.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) { // Changed spacing from 5 to 0
                    
                    // 1. Navigation Header Row
                    HStack {
                        Spacer() // Pushes the button to the right
                        
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 18, weight: .bold)) // Adjusted font size for 'xmark'
                                .foregroundColor(.white.opacity(0.7)) // White for contrast on dark background
                                .padding(12)
                                .background(Circle().fill(Color.white.opacity(0.05))) // Light background for dark theme
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    
                    // 2. "Fall Asleep" - Full-Width Vertical Sound Cards Stack
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Fall Asleep")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 14) {
                            ForEach(fallAsleepSounds, id: \.0) { sound in
                                // Determine if this specific sound card represents the currently selected sound.
                                let isThisCardSelected = selectedPlayerSound?.key == sound.3
                                // Determine if this specific sound card represents the sound that is currently playing.
                                let isThisSoundPlaying = isThisCardSelected && engine.isPlaying
                                
                                Button(action: {
                                    if isThisSoundPlaying {
                                        // If this sound is currently playing, stop it (effectively pausing it).
                                        engine.stopMaskingSound()
                                        // The sheet remains presented, SleepPlayerView should update its state.
                                    } else {
                                        // If this sound is not currently playing:
                                        // 1. Stop any other sound that might be playing.
                                        // 2. Set this sound as the selected one.
                                        // 3. Start playing this sound.
                                        
                                        // Only stop if the engine is currently playing something, to avoid unnecessary calls.
                                        if engine.isPlaying {
                                            engine.stopMaskingSound()
                                        }
                                        
                                        // Assign parameters for the *new* selection
                                        selectedPlayerSound = (title: sound.0, subtitle: sound.1, key: sound.3)
                                        showingPlayerSheet = true // Always show the sheet when a sound is selected to play
                                        
                                        // Instantly start generating the hardware signal thread for the new sound
                                        engine.startProceduralSound(type: sound.3)
                                    }
                                }) {
                                    HStack(alignment: .top, spacing: 16) {
                                        // App signature gradient icon container
                                        Image(systemName: sound.2)
                                            .font(.system(size: 24))
                                            .foregroundStyle(AppTheme.accentGradient)
                                            .frame(width: 32)
                                            .padding(.top, 2)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(sound.0)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(.white)
                                            
                                            Text(sound.1)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(.white.opacity(0.5))
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        
                                        Spacer()
                                        
                                        // Icon logic for play/pause
                                        if isThisSoundPlaying {
                                            Image(systemName: "pause.fill")
                                                .font(.system(size: 30))
                                                .foregroundStyle(AppTheme.accentGradient)
                                        } else if isThisCardSelected { // This sound is selected but not playing (i.e., paused)
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 30))
                                                .foregroundStyle(AppTheme.accentGradient)
                                        }
                                        // If not selected, no icon is shown
                                    }
                                    .padding(20)
                                    .frame(maxWidth: .infinity, alignment: .leading) // Stretches box horizontally full
                                    .background(Color(white: 0.12))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            // The overlay stroke now highlights the card if it's selected, whether playing or paused.
                                            .stroke(isThisCardSelected ? AnyShapeStyle(AppTheme.accentGradient) : AnyShapeStyle(Color.clear), lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // 3. Smart Automated Sleep Timers Block Card
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Sleep Timer")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Audio transitions will smoothly fade to complete silence during the last 5 minutes to prevent sudden tinnitus snaps.")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .fixedSize(horizontal: false, vertical: true)
                        
                        HStack(spacing: 12) {
                            ForEach(timerOptions, id: \.self) { minutes in
                                let isTimerSelected = selectedTimerMinutes == minutes
                                
                                Button(action: {
                                    selectedTimerMinutes = isTimerSelected ? nil : minutes
                                }) {
                                    Text("\(minutes) Min")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(isTimerSelected ? .black : .white)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 14)
                                        .background(isTimerSelected ? Color.white : Color(white: 0.12))
                                        .cornerRadius(12)
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 20)
                    
                    // 4. Custom Medical Notch & Dimming Parameters Card Block
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notch & Quiet Tuning")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
                        // The Active Toggle Box (Kept intact)
                        VStack(spacing: 16) {
                            Toggle(isOn: $isNotchAttenuated) {
                                HStack(spacing: 16) {
                                    Image(systemName: "tuningfork")
                                        .font(.system(size: 20))
                                        .foregroundStyle(AppTheme.accentGradient)
                                        .frame(width: 24)
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Acoustic Notch Target")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.white)
                                        Text("Drop background spectrum -3dB around your pitch")
                                            .font(.system(size: 13))
                                            .foregroundColor(.white.opacity(0.5))
                                    }
                                }
                            }
                            .tint(.orange)
                        }
                        .padding(20)
                        .background(Color(white: 0.12))
                        .cornerRadius(20)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Spacer()
                            
                            Image(systemName: "info.circle")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.yellow)
                            
                            Text("Melatonin Preservation: Pure black pixels decrease blue light exposure.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                                .multilineTextAlignment(.center)
                            
                            Spacer()
                        }
                        .padding(.top, 4)
                        .padding(.horizontal, 10)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.bottom, 30)
            }
        }
        .navigationBarHidden(true)
        // Modern modal sheet overlay that binds right to player states
//        .sheet(isPresented: $showingPlayerSheet) {
//            if let explicitSound = selectedPlayerSound {
//                SleepPlayerView(
//                    engine: engine,
//                    title: explicitSound.title,
//                    subtitle: explicitSound.subtitle,
//                    soundType: explicitSound.key
//                )
//                .presentationDetents([.medium, .large])
//            }
//        }
    }
}

#Preview {
    SleepView(engine: TinnitusAppEngine())
}
