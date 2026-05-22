//
//  SleepPlayerView.swift
//  Silentium
//
//  Created by Souha Aouididi on 22/05/26.
//

import SwiftUI

struct SleepPlayerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var engine: TinnitusAppEngine
    
    let title: String
    let subtitle: String
    let soundType: String // "brown_sleep" or "sub_delta"
    
    @State private var volume: Double = 70.0
    
    var body: some View {
        ZStack {
            // Pure black display for optimal sleep hygiene
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 40) {
                
                // Top Grabber Indicator (Matches standard iOS bottom sheets)
                Capsule()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 36, height: 5)
                    .padding(.top, 12)
                
                Spacer()
                
                // 1. Center Animated Audio Waveform Graphic
                ZStack {
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(white: 0.08))
                        .frame(width: 240, height: 240)
                    
                    HStack(spacing: 6) {
                        // Renders a static beautiful equalizer graphic using your gradient
                        ForEach(0..<8) { index in
                            RoundedRectangle(cornerRadius: 3)
                                .fill(AppTheme.accentGradient)
                                .frame(width: 8, height: CGFloat([60, 110, 140, 90, 120, 150, 80, 50][index]))
                                // Subtle scaling effect if the engine is actively synthesizing sound
                                .scaleEffect(y: engine.isPlaying ? 1.0 : 0.1, anchor: .center)
                                .animation(engine.isPlaying ? .easeInOut(duration: 0.6).repeatForever(autoreverses: true).delay(Double(index) * 0.05) : .default, value: engine.isPlaying)
                        }
                    }
                }
                
                // 2. Metadata Typography Text Block
                VStack(spacing: 8) {
                    Text(title)
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(subtitle)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
                
                // 3. Central Playback Stop Master Button Controller
                Button(action: {
                    if engine.isPlaying {
                        engine.stopMaskingSound()
                    } else {
                        engine.startProceduralSound(type: soundType)
                    }
                }) {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 84, height: 84)
                        .overlay(
                            ZStack {
                                if engine.isPlaying {
                                    // Native standard iOS Stop square vector geometry
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(AppTheme.accentGradient)
                                        .frame(width: 28, height: 28)
                                } else {
                                    // Play triangle vector
                                    Image(systemName: "play.fill")
                                        .font(.system(size: 32))
                                        .foregroundStyle(AppTheme.accentGradient)
                                        .offset(x: 3)
                                }
                            }
                        )
                        .shadow(color: Color.white.opacity(0.03), radius: 10, y: 5)
                }
                
                // 4. Custom Horizontal Native iOS Volume Slider Bar
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "speaker.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                        
                        Slider(value: $volume, in: 0...100) { _ in
                            // If needed, you can bind this value to update engine node gains
                        }
                        .tint(.white)
                        
                        Image(systemName: "speaker.wave.3.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 30)
                    
                    // Safe Listening Badge Indicator
                    HStack(spacing: 6) {
                        Image(systemName: "shield.checkmark.fill")
                            .font(.system(size: 13))
                        Text("Safe Listening ON")
                            .font(.system(size: 13, weight: .bold))
                    }
                    .foregroundColor(Color(red: 0.22, green: 0.80, blue: 0.45))
                    .padding(.top, 4)
                }
                
                Spacer()
            }
        }
    }
}
