//
//  SoundsView.swift
//  Silentium
//

import SwiftUI

struct SoundsView: View {
    @EnvironmentObject var engine: TinnitusAppEngine
    @Environment(\.colorScheme) private var colorScheme

    // FIX: Start with nil so the mini-player / sheet only appear after the
    // user explicitly picks a sound. An initial non-nil value caused the
    // sheet to be presented the instant the view appeared (the flash bug).
    @State private var selectedNoise: MaskingSound? = nil
    @State private var showingSettings = false
    @State private var showPlayer = false
    @State private var horizontalSwipeOffset: CGFloat = 0

    struct SoundCategory: Identifiable {
        let id = UUID()
        let name: String
        let description: String
        let colors: [Color]
        let systemIcon: String
    }

    let categories = [
        SoundCategory(
            name: "White",
            description: "High-frequency emphasis for masking sharp ringing.",
            colors: [Color(red: 0.15, green: 0.25, blue: 0.45), Color(red: 0.25, green: 0.45, blue: 0.75)],
            systemIcon: "waveform.path"
        ),
        SoundCategory(
            name: "Pink",
            description: "Balanced leafy distributions for deeper natural blend.",
            colors: [Color(red: 0.85, green: 0.35, blue: 0.45), Color(red: 0.95, green: 0.55, blue: 0.65)],
            systemIcon: "tree.fill"
        ),
        SoundCategory(
            name: "Brown",
            description: "Deep, roaring bass rumbles for heavy symptom coverage.",
            colors: [Color(red: 0.40, green: 0.20, blue: 0.15), Color(red: 0.65, green: 0.35, blue: 0.25)],
            systemIcon: "bolt.shield.fill"
        )
    ]

    // Full sound bank – procedural DSP + new file-backed mixkit sounds
    let totalSoundBank: [MaskingSound] = allSounds

    private var recommendedSounds: [MaskingSound] {
        let freq = engine.calibratedFrequency
        let cat: String
        if freq >= 8000.0       { cat = "White" }
        else if freq >= 3000.0  { cat = "Pink"  }
        else                    { cat = "Brown" }
        return totalSoundBank.filter { $0.category == cat }
    }

    private func colorForCategory(_ category: String) -> Color {
        switch category {
        case "White": return .blue
        case "Pink":  return .pink
        case "Brown": return .brown
        default:      return .orange
        }
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                AppTheme.background.ignoresSafeArea()

                VStack(spacing: 28) {
                    // ── Header ──────────────────────────────────────────────
                    HStack(alignment: .center) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Sounds")
                                .font(.largeTitle.bold())
                                .foregroundColor(AppTheme.text)
                            Text("Notch Active: \(Int(engine.calibratedFrequency)) Hz")
                                .font(.subheadline.weight(.medium))
                                .foregroundColor(AppTheme.text.opacity(0.6))
                        }
                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)

                    // ── Calibrate card ───────────────────────────────────────
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
                                    let isSelected = selectedNoise?.name == sound.name
                                    let isThisPlaying = isSelected && engine.isPlaying

                                    Button {
                                        engine.hapticSelection()
                                        selectedNoise = sound
                                        engine.startSound(type: sound.name) // Updated to new startSound method
                                        showPlayer = true
                                    } label: {
                                        SoundCard(
                                            sound: sound,
                                            isSelected: isSelected,
                                            isPlaying: isThisPlaying,
                                            accentColor: colorForCategory(sound.category)
                                        )
                                    }
                                    .buttonStyle(ScaleButtonStyle())
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                    }

                    // ── Browse categories ────────────────────────────────────
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Browse Spectral Categories")
                            .font(.headline)
                            .foregroundColor(AppTheme.text)
                            .padding(.horizontal, 20)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(categories) { category in
                                    NavigationLink(
                                        destination: SoundCategoryListView(
                                            categoryName: category.name,
                                            engine: engine,
                                            selectedNoise: $selectedNoise
                                        )
                                    ) {
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
                                                .fill(LinearGradient(
                                                    colors: category.colors,
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ))
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

                // ── Mini player bar ──────────────────────────────────────────
                MiniPlayerBar(
                    selectedNoise: $selectedNoise,
                    horizontalSwipeOffset: $horizontalSwipeOffset,
                    showPlayer: $showPlayer,
                    engine: engine,
                    colorScheme: colorScheme
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        showingSettings = true
                    } label: {
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
        // FIX: Guard the sheet with a Binding that stays false until
        // selectedNoise is non-nil. This eliminates the flash where
        // the sheet appears then disappears because `selectedNoise` was
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
}

// MARK: - Sound Card Subview
private struct SoundCard: View {
    let sound: MaskingSound
    let isSelected: Bool
    let isPlaying: Bool
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    Circle()
                        .fill(isSelected ? accentColor.opacity(0.1) : AppTheme.text.opacity(0.05))
                    Image(systemName: sound.systemIcon)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(isSelected ? accentColor : AppTheme.text.opacity(0.6))
                }
                .frame(width: 40, height: 40)

                Spacer()

                Image(systemName: isPlaying ? "waveform" : "play.circle.fill")
                    .font(.system(size: 20))
                    .foregroundColor(isPlaying ? accentColor : AppTheme.text.opacity(0.3))
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
        .frame(width: 155, height: 155)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(isSelected ? accentColor.opacity(0.4) : Color.clear, lineWidth: 1.5)
        )
    }
}

// MARK: - Mini Player Bar (extracted to avoid closure capture issues)
private struct MiniPlayerBar: View {
    @Binding var selectedNoise: MaskingSound?
    @Binding var horizontalSwipeOffset: CGFloat
    @Binding var showPlayer: Bool
    @ObservedObject var engine: TinnitusAppEngine
    let colorScheme: ColorScheme

    private func accentColor(for category: String) -> Color {
        switch category {
        case "White": return .blue
        case "Pink":  return .pink
        case "Brown": return .brown
        default:      return .orange
        }
    }

    var body: some View {
        if let activeSound = selectedNoise, engine.activeSoundscapeName != "None" {
            HStack(spacing: 14) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(accentColor(for: activeSound.category).opacity(0.15))
                        Image(systemName: activeSound.systemIcon)
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(accentColor(for: activeSound.category))
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

                Button {
                    engine.isPlaying.toggle()
                    if engine.isPlaying {
                        engine.startSound(type: activeSound.name) // Updated to new startSound method
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
}

