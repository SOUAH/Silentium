//
//  SoundCategoryListView.swift
//  Silentium
//

import SwiftUI

// MARK: - Shared Sound Bank
// Single source of truth used by both SoundsView and SoundCategoryListView.
// Procedural DSP sounds + new file-backed mixkit sounds with their categories.
let allSounds: [MaskingSound] = [
    // ── White ─────────────────────────────────────────────────────────────
    MaskingSound(name: "Torrential Downpour",    description: "Heavy rain flattening water or striking bare rock surfaces.",          category: "White", systemIcon: "cloud.heavyrain.fill"),
    MaskingSound(name: "Misty Waterfall Veil",   description: "The soft, deep hiss of water atomizing continuously in the air.",      category: "White", systemIcon: "drop.halffull"),
    MaskingSound(name: "Heavy Rain Storm",        description: "Intense rain on surfaces – file-based, seamlessly looped.",            category: "White", systemIcon: "cloud.rain.fill"),
    MaskingSound(name: "Thunder & Light Rain",    description: "Rolling thunder layered over steady light rain.",                     category: "White", systemIcon: "cloud.bolt.rain.fill"),

    // ── Pink ──────────────────────────────────────────────────────────────
    MaskingSound(name: "Rhythmic Ocean Swells",  description: "Deep ocean waves with a therapeutic rise-and-fall rhythm.",            category: "Pink",  systemIcon: "waveform.path"),
    MaskingSound(name: "Wind Through Pine Needles", description: "Steady breeze through soft forest pines.",                          category: "Pink",  systemIcon: "tree.fill"),
    MaskingSound(name: "Gentle Meadow Stream",   description: "Crisp freshwater tumbling over smooth river stones.",                  category: "Pink",  systemIcon: "water.waves"),
    MaskingSound(name: "Birds & Jungle Morning", description: "Dawn chorus from a dense jungle canopy – seamlessly looped.",          category: "Pink",  systemIcon: "bird.fill"),
    MaskingSound(name: "Dry Autumn Leaves",      description: "Wind-rustled dry leaves in a quiet park – file-based loop.",           category: "Pink",  systemIcon: "leaf.fill"),
    MaskingSound(name: "Liquid Bubble Flow",     description: "Gentle liquid bubbling stream – calming mid-range texture.",           category: "Pink",  systemIcon: "drop.fill"),

    // ── Brown ─────────────────────────────────────────────────────────────
    MaskingSound(name: "Distant Rolling Thunder", description: "Low-frequency rumble of a remote lightning storm.",                   category: "Brown", systemIcon: "cloud.bolt.fill"),
    MaskingSound(name: "Subterranean Canyon Rift", description: "Deep, sweeping sub-bass echoes for low-pitch masking.",              category: "Brown", systemIcon: "mountain.2.fill"),
    MaskingSound(name: "Interstellar Cabin Hum",  description: "Ultra-low cosmic engine drone to calm chaotic neural paths.",         category: "Brown", systemIcon: "airplane.arrival"),
    MaskingSound(name: "Strong Wild Wind",        description: "Powerful storm-force wind gusts – file-based seamless loop.",         category: "Brown", systemIcon: "wind"),
    MaskingSound(name: "Thunder Strike Storm",    description: "Heavy thunder strikes over a raging storm – deep bass-heavy loop.",   category: "Brown", systemIcon: "bolt.fill"),
]

struct SoundCategoryListView: View {
    let categoryName: String
    @ObservedObject var engine: TinnitusAppEngine
    @Binding var selectedNoise: MaskingSound?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var horizontalSwipeOffset: CGFloat = 0
    // Local flag owned by this view – avoids race condition where engine flag
    // is set before selectedNoise propagates, causing the sheet to flash.
    @State private var showPlayer = false

    private var filteredSounds: [MaskingSound] {
        allSounds.filter { $0.category == categoryName }
    }

    private var recommendedCategory: String {
        let freq = engine.calibratedFrequency
        if freq >= 8000.0      { return "White" }
        else if freq >= 3000.0 { return "Pink"  }
        else                   { return "Brown" }
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "White": return .blue
        case "Pink":  return .pink
        case "Brown": return .brown
        default:      return .orange
        }
    }

    private var accentColor: Color { colorForCategory(categoryName) }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppTheme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
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

                        // Sound list
                        VStack(spacing: 14) {
                            ForEach(filteredSounds) { sound in
                                let isThisSelected = selectedNoise?.name == sound.name
                                let isThisPlaying  = isThisSelected && engine.isPlaying

                                // iOS HIG: use .plain style on a styled label
                                // (avoids default Button highlight which fights card styling)
                                Button {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    selectedNoise = sound
                                    engine.startProceduralSound(type: sound.name)
                                    showPlayer = true
                                } label: {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(isThisSelected ? accentColor.opacity(0.1) : AppTheme.text.opacity(0.04))
                                            Image(systemName: sound.systemIcon)
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundColor(isThisSelected ? accentColor : AppTheme.text.opacity(0.6))
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
                                            .foregroundColor(isThisPlaying ? accentColor : AppTheme.text.opacity(0.3))
                                    }
                                    .padding(16)
                                    .background(AppTheme.cardBackground)
                                    .cornerRadius(16)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(isThisSelected ? accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
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

            // Mini player bar
            if let activeSound = selectedNoise, engine.activeSoundscapeName != "None" {
                miniPlayerBar(activeSound: activeSound)
            }
        }
        .sheet(isPresented: $showPlayer) {
            if let activeSound = selectedNoise {
                PlayerView(
                    engine: engine,
                    title: activeSound.name,
                    subtitle: "\(activeSound.category) Masking Soundscape",
                    soundType: activeSound.name
                )
                .presentationDetents([.large])
                .presentationBackground(AppTheme.background)
                .presentationDragIndicator(.visible)
            }
        }
    }

    // MARK: - Mini Player (inline builder to keep body readable)
    @ViewBuilder
    private func miniPlayerBar(activeSound: MaskingSound) -> some View {
        HStack(spacing: 14) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(accentColor.opacity(0.15))
                    Image(systemName: activeSound.systemIcon)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(accentColor)
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
                showPlayer = true
            }

            Spacer()

            Button {
                engine.isPlaying.toggle()
                if engine.isPlaying {
                    engine.startProceduralSound(type: activeSound.name)
                } else {
                    engine.stopMaskingSound()
                }
            } label: {
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
                .shadow(
                    color: Color.black.opacity(colorScheme == .dark ? 0.45 : 0.12),
                    radius: 12, x: 0, y: 6
                )
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
