//
//  SoundsView.swift
//  Silentium
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct SoundsView: View {
    @EnvironmentObject var engine: TinnitusAppEngine
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedNoise: MaskingSound? = MaskingSound(
        name: "Torrential Downpour",
        description: "Heavy rain flattening water or striking bare rock surfaces.",
        category: "White",
        systemIcon: "cloud.heavyrain.fill"
    )
    @State private var showingSettings = false
    @State private var horizontalSwipeOffset: CGFloat = 0
    
    struct SoundCategory: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let colors: [Color]
        let systemIcon: String
    }
    
    let categories = [
        SoundCategory(name: "White", description: "High-frequency emphasis for masking sharp ringing.", colors: [Color(red: 0.15, green: 0.25, blue: 0.45), Color(red: 0.25, green: 0.45, blue: 0.75)], systemIcon: "waveform.path"),
        SoundCategory(name: "Pink", description: "Balanced leafy distributions for deeper natural blend.", colors: [Color(red: 0.85, green: 0.35, blue: 0.45), Color(red: 0.95, green: 0.55, blue: 0.65)], systemIcon: "tree.fill"),
        SoundCategory(name: "Brown", description: "Deep, roaring bass rumbles for heavy symptom coverage.", colors: [Color(red: 0.40, green: 0.20, blue: 0.15), Color(red: 0.65, green: 0.35, blue: 0.25)], systemIcon: "bolt.shield.fill")
    ]
    
    let totalSoundBank: [MaskingSound] = [
        MaskingSound(name: "Torrential Downpour", description: "Heavy rain flattening water or striking bare rock surfaces.", category: "White", systemIcon: "cloud.heavyrain.fill"),
        MaskingSound(name: "Rhythmic Ocean Swells", description: "Deep ocean waves breaking on a shore with a therapeutic rise-and-fall rhythm.", category: "Pink", systemIcon: "waveform.path"),
        MaskingSound(name: "Wind Through Pine Needles", description: "Steady breeze passing through soft needles acting as dampeners.", category: "Pink", systemIcon: "tree.fill"),
        MaskingSound(name: "Distant Rolling Thunder", description: "Low-frequency rumble of a remote lightning storm.", category: "Brown", systemIcon: "cloud.bolt.rain.fill"),
        MaskingSound(name: "Subterranean Canyon Rift", description: "Deep, sweeping sub-bass echoes for low-pitch masking.", category: "Brown", systemIcon: "mountain.2.fill")
    ]
    
    private var recommendedSounds: [MaskingSound] {
        let currentFreq = engine.calibratedFrequency
        if currentFreq >= 8000.0 {
            return totalSoundBank.filter { $0.category == "White" }
        } else if currentFreq >= 3000.0 {
            return totalSoundBank.filter { $0.category == "Pink" }
        } else {
            return totalSoundBank.filter { $0.category == "Brown" }
        }
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
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 28) {
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sounds")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .foregroundColor(AppTheme.text)
                            
                            Text("Notch Active: \(Int(engine.calibratedFrequency)) Hz")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.text.opacity(0.6))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    
                    NavigationLink(destination: ToneFinderView(engine: engine, isFirstTime: false)) {
                        HStack(spacing: 16) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(AppTheme.accentGradient)
                                Image(systemName: "tuningfork")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            .frame(width: 52, height: 52)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Calibrate Tinnitus Pitch")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.text)
                                Text("Match the diagnostic dial tone to your ringing.")
                                    .font(.footnote)
                                    .foregroundColor(AppTheme.text.opacity(0.6))
                                    .multilineTextAlignment(.leading)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.text.opacity(0.2))
                        }
                        .padding(16)
                        .background(AppTheme.cardBackground)
                        .cornerRadius(16)
                        .padding(.horizontal, 20)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Recommended For Your Tinnitus")
                            .font(.headline)
                            .foregroundColor(AppTheme.text)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 14) {
                                ForEach(recommendedSounds) { sound in
                                    let isThisSelected = selectedNoise?.name == sound.name
                                    let isThisPlaying = isThisSelected && engine.isPlaying
                                    
                                    Button(action: {
                                        let selectorFeedback = UISelectionFeedbackGenerator()
                                        selectorFeedback.selectionChanged()
                                        selectedNoise = sound
                                        engine.startProceduralSound(type: sound.name)
                                        engine.isPlayerPresentedFullScreen = true
                                    }) {
                                        VStack(alignment: .leading, spacing: 10) {
                                            HStack {
                                                ZStack {
                                                    Circle()
                                                        .fill(isThisSelected ? colorForCategory(sound.category).opacity(0.1) : AppTheme.text.opacity(0.05))
                                                    Image(systemName: sound.systemIcon)
                                                        .font(.system(size: 18, weight: .bold))
                                                        .foregroundColor(isThisSelected ? colorForCategory(sound.category) : AppTheme.text.opacity(0.6))
                                                }
                                                .frame(width: 40, height: 40)
                                                
                                                Spacer()
                                                
                                                Image(systemName: isThisPlaying ? "waveform" : "play.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(isThisPlaying ? colorForCategory(sound.category) : AppTheme.text.opacity(0.3))
                                            }
                                            
                                            Spacer()
                                            
                                            Text(sound.name)
                                                .font(.system(size: 15, weight: .bold))
                                                .foregroundColor(AppTheme.text)
                                                .lineLimit(1)
                                            Text(sound.description)
                                                .font(.system(size: 11))
                                                .foregroundColor(AppTheme.text.opacity(0.5))
                                                .lineLimit(2)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .padding(14)
                                        .frame(width: 155, height: 145)
                                        .background(AppTheme.cardBackground)
                                        .cornerRadius(16)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 16)
                                                .stroke(isThisSelected ? colorForCategory(sound.category).opacity(0.4) : Color.clear, lineWidth: 1.5)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Browse Spectral Categories")
                            .font(.headline)
                            .foregroundColor(AppTheme.text)
                            .padding(.horizontal, 20)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(categories) { category in
                                    NavigationLink(destination: SoundCategoryListView(categoryName: category.name, engine: engine, selectedNoise: $selectedNoise)) {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Image(systemName: category.systemIcon)
                                                    .font(.system(size: 24, weight: .semibold))
                                                    .foregroundColor(.white)
                                                Spacer()
                                                Image(systemName: "arrow.up.forward.circle.fill")
                                                    .font(.system(size: 20))
                                                    .foregroundColor(.white.opacity(0.6))
                                            }
                                            Spacer()
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text("\(category.name) Noise")
                                                    .font(.system(size: 20, weight: .bold))
                                                    .foregroundColor(.white)
                                                Text(category.description)
                                                    .font(.system(size: 12, weight: .medium))
                                                    .foregroundColor(.white.opacity(0.8))
                                                    .multilineTextAlignment(.leading)
                                                    .lineLimit(2)
                                            }
                                        }
                                        .padding(16)
                                        .frame(width: 160, height: 180)
                                        .background(
                                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                                .fill(LinearGradient(colors: category.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                                        )
                                        .shadow(color: category.colors.first?.opacity(0.3) ?? .clear, radius: 8, x: 0, y: 4)
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 10)
                
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
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                        engine.forceQuitEngineTrack()
                                        selectedNoise = nil
                                        horizontalSwipeOffset = 0
                                    }
                                } else {
                                    withAnimation(.spring()) { horizontalSwipeOffset = 0 }
                                }
                            }
                    )
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        let clickFeedback = UIImpactFeedbackGenerator(style: .light)
                        clickFeedback.impactOccurred()
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(AppTheme.accentGradient)
                    }
                    .contentShape(Rectangle())
                }
                .sharedBackgroundVisibility(.hidden)
            }
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView(engine: engine)
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
}
