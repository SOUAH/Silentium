//
//  SoundCategoryListView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct SoundCategoryListView: View {
    let categoryName: String
    @ObservedObject var engine: TinnitusAppEngine
    @Binding var selectedNoise: MaskingSound?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var horizontalSwipeOffset: CGFloat = 0
    
    let totalSoundBank: [MaskingSound] = [
        MaskingSound(name: "Torrential Downpour", description: "Heavy rain flattening water or striking bare rock surfaces.", category: "White", systemIcon: "cloud.heavyrain.fill"),
        MaskingSound(name: "Rhythmic Ocean Swells", description: "Deep ocean waves breaking on a shore with a therapeutic rise-and-fall rhythm.", category: "Pink", systemIcon: "waveform.path"),
        MaskingSound(name: "Wind Through Pine Needles", description: "Steady breeze passing through soft needles acting as dampeners.", category: "Pink", systemIcon: "tree.fill"),
        MaskingSound(name: "Distant Rolling Thunder", description: "Low-frequency rumble of a remote lightning storm.", category: "Brown", systemIcon: "cloud.bolt.rain.fill"),
        MaskingSound(name: "Subterranean Canyon Rift", description: "Deep, sweeping sub-bass echoes for low-pitch masking.", category: "Brown", systemIcon: "mountain.2.fill"),
        MaskingSound(name: "Interstellar Cabin Hum", description: "A smooth, ultra-low cosmic engine drone to calm chaotic neural paths.", category: "Brown", systemIcon: "airplane.arrival")
    ]
    
    private var filteredSounds: [MaskingSound] {
        totalSoundBank.filter { $0.category == categoryName }
    }
    
    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "White": return Color.blue
        case "Pink": return Color.pink
        case "Brown": return Color.brown
        default: return Color.orange
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 24) {
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text("\(categoryName) Therapy")
                                .font(.system(size: 34, weight: .bold))
                                .foregroundColor(AppTheme.text)
                            
                            Text("Select a calibrated track to establish your mixing point.")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(AppTheme.text.opacity(0.5))
                        }
                        .padding(.horizontal, 24)
                        .padding(.top, 16)
                        
                        VStack(spacing: 14) {
                            ForEach(filteredSounds) { sound in
                                let isThisSelected = selectedNoise?.name == sound.name
                                let isThisPlaying = isThisSelected && engine.isPlaying
                                
                                Button(action: {
                                    let clickHaptics = UISelectionFeedbackGenerator()
                                    clickHaptics.selectionChanged()
                                    
                                    selectedNoise = sound
                                    engine.startProceduralSound(type: sound.name)
                                    engine.isPlayerPresentedFullScreen = true
                                }) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(isThisSelected ? colorForCategory(sound.category).opacity(0.1) : AppTheme.text.opacity(0.04))
                                            Image(systemName: sound.systemIcon)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(isThisSelected ? colorForCategory(sound.category) : AppTheme.text.opacity(0.6))
                                        }
                                        .frame(width: 44, height: 44)
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(sound.name)
                                                .font(.system(size: 17, weight: .bold))
                                                .foregroundColor(AppTheme.text)
                                                .multilineTextAlignment(.leading)
                                            
                                            Text(sound.description)
                                                .font(.system(size: 14, weight: .medium))
                                                .foregroundColor(AppTheme.text.opacity(0.5))
                                                .multilineTextAlignment(.leading)
                                                .lineLimit(2)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: isThisPlaying ? "waveform" : "play.circle.fill")
                                            .font(.system(size: 20))
                                            .foregroundColor(isThisPlaying ? colorForCategory(sound.category) : AppTheme.text.opacity(0.3))
                                    }
                                    .padding(16)
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(isThisSelected ? colorForCategory(sound.category).opacity(0.4) : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 110)
                    }
                    .padding(.vertical, 10)
                }
            }
            
            if let activeSound = selectedNoise, engine.activeSoundscapeName != "None" {
                HStack(spacing: 14) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(activeSound.category == "White" ? Color.blue.opacity(0.15) : (activeSound.category == "Pink" ? Color.pink.opacity(0.15) : Color.brown.opacity(0.15)))
                            
                            Image(systemName: activeSound.systemIcon)
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(activeSound.category == "White" ? .blue : (activeSound.category == "Pink" ? .pink : .brown))
                        }
                        .frame(width: 40, height: 40)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(activeSound.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.text)
                                .lineLimit(1)
                            
                            Text("\(activeSound.category) Masking Noise")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(AppTheme.text.opacity(0.5))
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        engine.isPlayerPresentedFullScreen = true
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        engine.isPlaying.toggle()
                        if engine.isPlaying {
                            engine.startProceduralSound(type: activeSound.name)
                        } else {
                            engine.stopMaskingSound()
                        }
                    }) {
                        Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(AppTheme.text)
                            .frame(width: 32, height: 32)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(AppTheme.cardBackground)
                        .shadow(color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.12), radius: 12, x: 0, y: 6)
                )
                .padding(.horizontal, 12)
                .padding(.bottom, 64)
                .offset(x: horizontalSwipeOffset)
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            if value.translation.width < 0 { horizontalSwipeOffset = value.translation.width }
                        }
                        .onEnded { value in
                            if value.translation.width < -100 {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { horizontalSwipeOffset = -500 }
                                analyticsSwipeTeardownBridge()
                            } else {
                                withAnimation(.spring()) { horizontalSwipeOffset = 0 }
                            }
                        }
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .sheet(isPresented: $engine.isPlayerPresentedFullScreen) {
            if let activeSound = selectedNoise {
                PlayerView(engine: engine, title: activeSound.name, subtitle: "\(activeSound.category) Masking Soundscape", soundType: activeSound.name)
                    .presentationDetents([.large])
                    .presentationBackground(AppTheme.background)
                    .presentationDragIndicator(.visible)
            }
        }
    }
    
    private func analyticsSwipeTeardownBridge() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            engine.forceQuitEngineTrack()
            selectedNoise = nil
            horizontalSwipeOffset = 0
        }
    }
}
