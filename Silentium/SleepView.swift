//
//  SleepView.swift
//  Silentium
//
//  Created by Souha Aouididi on 22/05/26.
//

import SwiftUI

struct SleepView: View {
    @ObservedObject var engine: TinnitusAppEngine
    @AppStorage("sleepNotchAttenuation") private var isNotchAttenuated = true
    @State private var selectedTimerMinutes: Int? = nil
    
    let fallAsleepSounds = [
        ("Deep Brown Noise", "Deep waterfall rumble. Perfect for masking high-frequency ringing.", "water.waves", "brown_sleep"),
        ("Sub-Delta Modulation", "Fluid 10s breathing swells that coax your brain into deep sleep.", "waveform.path.ecg", "sub_delta")
    ]
    
    let timerOptions = [15, 30, 45, 60]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Fall Asleep")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 14) {
                            ForEach(fallAsleepSounds, id: \.0) { sound in
                                let isThisCardActive = engine.activeSoundscapeName == sound.3
                                
                                Button(action: {
                                    if isThisCardActive && engine.isPlaying {
                                        engine.stopMaskingSound()
                                    } else {
                                        engine.startProceduralSound(type: sound.3)
                                    }
                                }) {
                                    HStack(alignment: .top, spacing: 16) {
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
                                        
                                        if isThisCardActive && engine.isPlaying {
                                            Image(systemName: "pause.fill")
                                                .font(.system(size: 30))
                                                .foregroundStyle(AppTheme.accentGradient)
                                        } else {
                                            Image(systemName: "play.fill")
                                                .font(.system(size: 30))
                                                .foregroundStyle(AppTheme.accentGradient)
                                        }
                                    }
                                    .padding(20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color(white: 0.12))
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(isThisCardActive ? AppTheme.accentGradient : LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom), lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                    
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
                    
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notch & Quiet Tuning")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                        
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
    }
}
