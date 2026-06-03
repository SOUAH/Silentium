//
//  TherapyMixerView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct TherapyMixerView: View {
    @EnvironmentObject var engine: TinnitusAppEngine
    
    @State private var selectedNoise: MaskingSound? = MaskingSound(
        name: "Torrential Downpour",
        description: "Heavy rain flattening water or striking bare rock surfaces.",
        category: "White",
        systemIcon: "cloud.heavyrain.fill"
    )
    @State private var showingSettings = false
    
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
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                VStack(spacing: 0) {
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
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                    
                    ScrollView(.vertical, showsIndicators: true) {
                        VStack(spacing: 24) {
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
                                Text("Browse Spectral Categories")
                                    .font(.headline)
                                    .foregroundColor(AppTheme.text)
                                    .padding(.horizontal, 20)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 16) {
                                        ForEach(categories) { category in
                                            NavigationLink(destination: SoundCategoryListView(categoryName: category.name, engine: engine, selectedNoise: $selectedNoise, isPlaying: $engine.isPlaying)) {
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
                                    .padding(.bottom, 10)
                                }
                            }
                        }
                        .padding(.vertical, 10)
                    }
                    
                    if let activeSound = selectedNoise {
                        VStack {
                            Divider()
                                .background(AppTheme.text.opacity(0.08))
                            
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(activeSound.name)
                                        .font(.callout)
                                        .fontWeight(.semibold)
                                        .foregroundColor(AppTheme.text)
                                        .lineLimit(1)
                                    
                                    Text("\(activeSound.category) Masking Noise")
                                        .font(.caption)
                                        .foregroundColor(AppTheme.text.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
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
                                    ZStack {
                                        Circle().fill(AppTheme.text)
                                        Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                                            .font(.system(size: 18, weight: .bold))
                                            .foregroundColor(AppTheme.background)
                                            .offset(x: engine.isPlaying ? 0 : 1)
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
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 22, weight: .semibold))
                            .foregroundStyle(AppTheme.accentGradient)
                    }
                }.sharedBackgroundVisibility(.hidden)
            }
            .fullScreenCover(isPresented: $showingSettings) {
                SettingsView(engine: engine)
            }
        }
    }
}
