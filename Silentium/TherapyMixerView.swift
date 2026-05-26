//
//  TherapyMixerView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

//Masking Sound Soundscape Entity Model
struct MaskingSound: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let category: String // "White", "Pink", "Brown"
    let systemIcon: String
}

struct TherapyMixerView: View {
    @ObservedObject var engine: TinnitusAppEngine
    
    // Default to the first procedural model sound
    @State private var selectedNoise: MaskingSound = MaskingSound(
        name: "Torrential Downpour",
        description: "Heavy rain flattening water or striking bare rock surfaces.",
        category: "White",
        systemIcon: "cloud.heavyrain.fill"
    )
    @State private var selectedMode = "Focus"
    @State private var isPlaying = false
    @State private var showingTest = false
    @State private var showingSleepView = false
    @State private var showingBreathingExercise = false
    
    // HIG Semantic Dataset of your 30 requested sound variations
    let soundRegistry: [MaskingSound] = [
        // Natural White Noise Variants
        MaskingSound(name: "Torrential Downpour", description: "Heavy rain flattening water or striking bare rock surfaces.", category: "White", systemIcon: "cloud.heavyrain.fill"),
        MaskingSound(name: "Up-Close Waterfall", description: "Standing directly at the base of a roaring waterfall plunge pool.", category: "White", systemIcon: "water.waves"),
        MaskingSound(name: "High-Velocity Shallow Rapids", description: "Intense hiss of a fast-moving, shallow river crashing over rocks.", category: "White", systemIcon: "waveform.path"),
        MaskingSound(name: "Blizzard Winds", description: "Severe, high-speed arctic winds howling across flat frozen plains.", category: "White", systemIcon: "wind"),
        MaskingSound(name: "Hailstones on a Lake", description: "Chaotic, sharp, metallic-sounding hiss of millions of icy hailstones.", category: "White", systemIcon: "cloud.hail.fill"),
        MaskingSound(name: "High-Pressure Geyser Eruption", description: "Intense, high-pitched hiss of superheated steam escaping geothermal vents.", category: "White", systemIcon: "smoke.fill"),
        MaskingSound(name: "Desert Sandstorm", description: "Abrasive, sharp whispering sound of billions of fine sand grains.", category: "White", systemIcon: "wind.snow"),
        MaskingSound(name: "Up-Close Cicada Chorus", description: "Thick tree canopy during emergence where calls saturate the air.", category: "White", systemIcon: "waveform"),
        MaskingSound(name: "Crashing Sea Foam", description: "Bright, fizzy sound of tiny air bubbles popping after a wave breaks.", category: "White", systemIcon: "ocean.waves.fill"),
        MaskingSound(name: "Roaring Forest Fire", description: "Sharp, chaotic, high-frequency crackling and snapping of dry branches.", category: "White", systemIcon: "flame.fill"),
        
        // Natural Pink Noise Variants
        MaskingSound(name: "Steady Canopy Rain", description: "Moderate rain filtering down through a thick layer of leaves.", category: "Pink", systemIcon: "cloud.rain"),
        MaskingSound(name: "Wind Through Pine Needles", description: "Steady breeze passing through thin, soft needles acting as dampeners.", category: "Pink", systemIcon: "tree.fill"),
        MaskingSound(name: "A Babbling Brook", description: "Gentle, cascading stream where water flows smoothly without harsh hiss.", category: "Pink", systemIcon: "drop.fill"),
        MaskingSound(name: "Swaying Meadow Grasses", description: "Collective, rhythmic swish of tall wild grass moving in the wind.", category: "Pink", systemIcon: "leaf.arrow.triangle.circlepath"),
        MaskingSound(name: "Rustling Autumn Leaves", description: "Soft, papery, collective fluttering of dry leaves on branches.", category: "Pink", systemIcon: "leaf.fill"),
        MaskingSound(name: "Distant Ocean Waves", description: "Continuous, ambient hum where sharp high-pitched cracks have faded.", category: "Pink", systemIcon: "waves.reversing"),
        MaskingSound(name: "A Distant Bird Colony", description: "Soft, blurred murmur of thousands of seabirds nesting on cliffs.", category: "Pink", systemIcon: "bird.fill"),
        MaskingSound(name: "Wind Over Sand Dunes", description: "Moderate, steady desert wind creating warm, whispering friction.", category: "Pink", systemIcon: "sun.max.fill"),
        MaskingSound(name: "Soft Winter Snowfall", description: "Quiet, muted rustle of heavy, wet snow falling through trees.", category: "Pink", systemIcon: "snowflake"),
        MaskingSound(name: "Distant Waterfall", description: "Softened, medium-pitched rush filtered through a quarter-mile of forest.", category: "Pink", systemIcon: "humidity.fill"),
        
        // Natural Brown Noise Variants
        MaskingSound(name: "Distant Rolling Thunder", description: "Low-frequency, deep, continuous rumbling of a remote storm.", category: "Brown", systemIcon: "cloud.bolt.rain.fill"),
        MaskingSound(name: "Heavy Ocean Surf", description: "Powerful, deep, booming crash of massive waves violently hitting cliffs.", category: "Brown", systemIcon: "bolt.shield.fill"),
        MaskingSound(name: "Niagara-Scale Waterfall", description: "Deep, echoing, low-pitched boom heard from a mile away.", category: "Brown", systemIcon: "speaker.wave.3.fill"),
        MaskingSound(name: "Wind in a Rocky Canyon", description: "Strong winds howling through a massive, deep desert canyon rift.", category: "Brown", systemIcon: "mountain.2.fill"),
        MaskingSound(name: "Subterranean Mud Pots", description: "Low-frequency, thick, heavy bubbling of boiling volcanic mud.", category: "Brown", systemIcon: "medical.thermometer.fill"),
        MaskingSound(name: "Glacial Calving", description: "Deep, booming rumble when a massive chunk of ice breaks into the sea.", category: "Brown", systemIcon: "square.stack.3d.forward.dottedline.fill"),
        MaskingSound(name: "Avalanche or Landslide", description: "Terrifyingly deep, low-pitched roar of tons of moving snow down slopes.", category: "Brown", systemIcon: "triangle.fill"),
        MaskingSound(name: "Earthquake Tremors", description: "Ultra-low frequency subterranean grinding of tectonic plates.", category: "Brown", systemIcon: "shaker.3f"),
        MaskingSound(name: "Distant Hurricane Wall", description: "Heavy, oppressive, low-frequency wall of sound heard from indoors.", category: "Brown", systemIcon: "tornado"),
        MaskingSound(name: "Deep Ocean Undercurrents", description: "Low-frequency, sweeping rumble of massive volumes shifting deep down.", category: "Brown", systemIcon: "eye.inverse")
    ]
    
    let modes = [
        ("Focus", "target"),
        ("Sleep", "moon.zzz.fill")
    ]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Header Layout (HIG Compliant Hierarchy & Your Exact Theme Colors)
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Your Therapy Mix")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(AppTheme.text)
                        
                        Text("Notch Active: \(Int(engine.calibratedFrequency)) Hz")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(AppTheme.text.opacity(0.6))
                    }
                    
                    Spacer()
                    
                    // HIG Target Padding Check ($48x48 pt accessible bounding box)
                    Button(action: { showingTest = true }) {
                        Image(systemName: "waveform.circle.fill")
                            .font(.system(size: 32))
                            .foregroundStyle(AppTheme.accentGradient)
                            .frame(width: 48, height: 48, alignment: .trailing)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 28) {
                        
                        // 2. Therapy Modes Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Therapy Modes")
                                .font(.headline)
                                .foregroundColor(AppTheme.text)
                                .padding(.horizontal, 20)
                            
                            HStack(spacing: 12) {
                                ForEach(modes, id: \.0) { mode in
                                    ModeCard(
                                        title: mode.0,
                                        icon: mode.1,
                                        isSelected: selectedMode == mode.0,
                                        action: {
                                            selectedMode = mode.0
                                            if mode.0 == "Focus" {
                                                showingBreathingExercise = true
                                            } else if mode.0 == "Sleep" {
                                                showingSleepView = true
                                                if isPlaying {
                                                    engine.startProceduralSound(type: "sleep")
                                                }
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal, 20)
                        }
                        
                        // 3. Masking Soundscapes Matched to your Design Framework
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Masking Soundscapes")
                                .font(.headline)
                                .foregroundColor(AppTheme.text)
                                .padding(.horizontal, 20)
                            
                            ForEach(["White", "Pink", "Brown"], id: \.self) { cat in
                                VStack(alignment: .leading, spacing: 8) {
                                    //  NEW HIG-COMPLIANT CODE
                                    Text("\(cat) Spectrum Variant Therapy")
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .foregroundColor(AppTheme.text.opacity(0.4))
                                        .textCase(.uppercase) // Changed to the correct SwiftUI token
                                        .padding(.horizontal, 20)
                                    
                                    VStack(spacing: 10) {
                                        ForEach(soundRegistry.filter { $0.category == cat }) { sound in
                                            SoundRowStyle(
                                                sound: sound,
                                                isSelected: selectedNoise == sound,
                                                action: {
                                                    selectedNoise = sound
                                                    if isPlaying {
                                                        engine.startProceduralSound(type: sound.name)
                                                    }
                                                }
                                            )
                                        }
                                    }
                                    .padding(.horizontal, 20)
                                }
                            }
                        }
                    }
                    .padding(.vertical, 10)
                }
                
                // 4. Floating Playback System Dock (Matches your theme text parameters perfectly)
                VStack {
                    Divider()
                        .background(AppTheme.text.opacity(0.08))
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(selectedNoise.name)
                                .font(.callout)
                                .fontWeight(.semibold)
                                .foregroundColor(AppTheme.text)
                                .lineLimit(1)
                            
                            Text("\(selectedNoise.category) Masking Noise")
                                .font(.caption)
                                .foregroundColor(AppTheme.text.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Button(action: {
                            isPlaying.toggle()
                            if isPlaying {
                                engine.startProceduralSound(type: selectedNoise.name)
                            } else {
                                engine.stopMaskingSound()
                            }
                        }) {
                            ZStack {
                                Circle()
                                    .fill(AppTheme.text)
                                
                                Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundColor(AppTheme.background) // Contrast safe layout flip
                                    .offset(x: isPlaying ? 0 : 1)
                            }
                            .frame(width: 54, height: 54)
                        }
                        .buttonStyle(ScaleButtonStyle())
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 12)
                    .padding(.bottom, UIApplication.shared.windows.first?.safeAreaInsets.bottom == 0 ? 12 : 0)
                }
                .background(AppTheme.cardBackground.edgesIgnoringSafeArea(.bottom))
            }
        }
        .fullScreenCover(isPresented: $showingTest) {
            ToneFinderView(engine: engine, isFirstTime: false)
        }
        .fullScreenCover(isPresented: $showingBreathingExercise) {
            BreathingView()
        }
        .fullScreenCover(isPresented: $showingSleepView) {
            SleepView(engine: engine)
        }
    }
}

//HIG Elements Using 'AppTheme' Structure Nodes

struct SoundRowStyle: View {
    let sound: MaskingSound
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Gradient or Solid Icon Box Block (Type-Safe Fix)
                ZStack {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(AppTheme.text.opacity(0.05))
                    
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(AppTheme.accentGradient)
                    }
                    
                    Image(systemName: sound.systemIcon)
                        .font(.system(size: 20, weight: .medium))
                        .foregroundColor(isSelected ? .white : AppTheme.text.opacity(0.7))
                }
                .frame(width: 48, height: 48)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(sound.name)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.text)
                        .multilineTextAlignment(.leading)
                    
                    Text(sound.description)
                        .font(.footnote)
                        .foregroundColor(AppTheme.text.opacity(0.5))
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundStyle(AppTheme.accentGradient)
                }
            }
            .padding(12)
            .frame(maxWidth: .infinity)
            .background(AppTheme.cardBackground)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(isSelected ? AppTheme.text.opacity(0.15) : Color.clear, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.02), radius: 6, y: 3)
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
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(isSelected ? AnyShapeStyle(AppTheme.background) : AnyShapeStyle(AppTheme.accentGradient))
                
                Text(title)
                    .font(.callout)
                    .fontWeight(.bold)
                    .foregroundColor(isSelected ? AppTheme.background : AppTheme.text)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(isSelected ? AppTheme.text : AppTheme.cardBackground)
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.02), radius: 6, y: 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

