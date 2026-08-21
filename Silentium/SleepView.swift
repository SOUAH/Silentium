//
//  SleepView.swift
//  Silentium
//
//  Created by Souha Aouididi on 22/05/26.
//

import SwiftUI

struct SleepSound: Identifiable {
    var id: String { key }
    let title: String
    let subtitle: String
    let icon: String
    let key: String
}

struct SleepView: View {
    @ObservedObject var engine: TinnitusAppEngine
    @AppStorage("sleepNotchAttenuation") private var isNotchAttenuated = true
    
    // Core definition layout for our specialized medical sleep soundscapes
    let fallAsleepSounds: [SleepSound] = [
        SleepSound(
            title: "Deep Brown Noise",
            subtitle: "Deep waterfall rumble. Perfect for masking high-frequency ringing.",
            icon: "water.waves",
            key: "brown_sleep"
        ),
        SleepSound(
            title: "Sub-Delta Modulation",
            subtitle: "Fluid 10s breathing swells that coax your brain into deep sleep.",
            icon: "waveform.path.ecg",
            key: "sub_delta"
        )
    ]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Fall Asleep")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppTheme.text)
                            .padding(.horizontal, 20)
                        
                        VStack(spacing: 14) {
                            ForEach(fallAsleepSounds) { sound in
                                let isThisCardActive = engine.activeSoundscapeName == sound.key
                                
                                Button(action: {
                                    let impact = UIImpactFeedbackGenerator(style: .medium)
                                    impact.impactOccurred()
                                    
                                    // Set up target sound tracking data
                                    engine.currentSelectedSoundMetadata = (
                                        title: sound.title,
                                        subtitle: sound.subtitle,
                                        key: sound.key
                                    )
                                    
                                    // Spin up audio nodes and launch master player view overlay panel
                                    engine.startSound(type: sound.key)
                                    engine.isPlayerPresentedFullScreen = true
                                }) {
                                    HStack(alignment: .top, spacing: 16) {
                                        Image(systemName: sound.icon)
                                            .font(.system(size: 24))
                                            .foregroundStyle(AppTheme.accentGradient)
                                            .frame(width: 32)
                                            .padding(.top, 2)
                                        
                                        VStack(alignment: .leading, spacing: 6) {
                                            Text(sound.title)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(AppTheme.text)
                                            
                                            Text(sound.subtitle)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(AppTheme.text.opacity(0.5))
                                                .multilineTextAlignment(.leading)
                                                .fixedSize(horizontal: false, vertical: true)
                                        }
                                        
                                        Spacer()
                                        
                                        if isThisCardActive && engine.isPlaying {
                                            Image(systemName: "waveform")
                                                .font(.system(size: 22, weight: .bold))
                                                .foregroundStyle(AppTheme.accentGradient)
                                                .padding(.top, 4)
                                        } else {
                                            Image(systemName: "play.circle.fill")
                                                .font(.system(size: 26))
                                                .foregroundColor(AppTheme.text.opacity(0.2))
                                                .padding(.top, 2)
                                        }
                                    }
                                    .padding(20)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(AppTheme.cardBackground)
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
                    
                    // Clinical Notch Filter Configuration Group
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Notch & Quiet Tuning")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(AppTheme.text)
                        
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
                                            .foregroundColor(AppTheme.text)
                                        Text("Drop background spectrum -3dB around your pitch")
                                            .font(.system(size: 13))
                                            .foregroundColor(AppTheme.text.opacity(0.5))
                                    }
                                }
                            }
                            .tint(.orange)
                        }
                        .padding(20)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(20)
                        
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Spacer()
                            Image(systemName: "info.circle.fill")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundStyle(.yellow)
                            
                            Text("Melatonin Preservation: Displays adjust contrast levels based on target environment.")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(AppTheme.text.opacity(0.4))
                                .multilineTextAlignment(.center)
                            Spacer()
                        }
                        .padding(.top, 4)
                        .padding(.horizontal, 10)
                    }
                    .padding(.horizontal, 20)
                    
                    Spacer()
                }
                .padding(.top, 16)
                .padding(.bottom, 30)
            }
        }
    }
}   
