//
//  SoundCategoryListView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct SoundCategoryListView: View {
    @Environment(\.dismiss) var dismiss
    let categoryName: String
    
    @ObservedObject var engine: TinnitusAppEngine
    @Binding var selectedNoise: MaskingSound?
    @Binding var isPlaying: Bool
    
    // Core structural reference of all highly successful filtered soundscapes
    let soundRegistry: [MaskingSound] = [
        // Natural White Noise Variants
        MaskingSound(name: "Torrential Downpour", description: "Heavy rain flattening water or striking bare rock surfaces.", category: "White", systemIcon: "cloud.heavyrain.fill"),
        MaskingSound(name: "Steam Vent Meditation", description: "Continuous, ambient geothermal steam hiss to mask high frequencies.", category: "White", systemIcon: "smoke.fill"),
        
        // Natural Pink Noise Variants
        MaskingSound(name: "Wind Through Pine Needles", description: "Steady breeze passing through soft needles acting as dampeners.", category: "Pink", systemIcon: "tree.fill"),
        MaskingSound(name: "Steady Canopy Rain", description: "Moderate rain filtering down through a thick layer of leaves.", category: "Pink", systemIcon: "cloud.rain"),
        
        // Natural Brown Noise Variants
        MaskingSound(name: "Distant Rolling Thunder", description: "Low-frequency, deep, continuous rumbling of a remote storm.", category: "Brown", systemIcon: "cloud.bolt.rain.fill"),
        MaskingSound(name: "Subterranean Canyon Rift", description: "Deep, heavy acoustic cavern winds moving at a restful pace.", category: "Brown", systemIcon: "mountain.2.fill")
    ]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header layout mimicking Spotify list architectures
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(categoryName) Therapy")
                            .font(.largeTitle.bold())
                            .foregroundColor(AppTheme.text)
                        Text("Select a calibrated track to establish your mixing point.")
                            .font(.subheadline)
                            .foregroundColor(AppTheme.text.opacity(0.6))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 12) {
                        ForEach(soundRegistry.filter { $0.category == categoryName }) { sound in
                            let isThisCurrent = selectedNoise == sound
                            let isThisPlaying = isThisCurrent && isPlaying
                            let recommendationText = engine.getRecommendationReason(for: sound.name)
                            
                            Button(action: {
                                selectedNoise = sound
                                isPlaying = true
                                engine.startProceduralSound(type: sound.name)
                                engine.isPlayerPresentedFullScreen = true 
                            }) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 16) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                .fill(AppTheme.text.opacity(0.05))
                                            
                                            if isThisCurrent {
                                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                                    .fill(AppTheme.accentGradient)
                                            }
                                            
                                            Image(systemName: isThisPlaying ? "waveform" : sound.systemIcon)
                                                .font(.system(size: 20, weight: .medium))
                                                .foregroundColor(isThisCurrent ? .white : AppTheme.text.opacity(0.7))
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
                                        
                                        if isThisCurrent {
                                            Image(systemName: isThisPlaying ? "pause.circle.fill" : "play.circle.fill")
                                                .font(.system(size: 24, weight: .bold))
                                                .foregroundStyle(AppTheme.accentGradient)
                                        }
                                    }
                                    
                                    // Custom Notch Matching Recommendation System
                                    if let reasonText = recommendationText {
                                        HStack(spacing: 6) {
                                            Image(systemName: "sparkles")
                                                .font(.caption)
                                                .foregroundColor(.orange)
                                            Text(reasonText)
                                                .font(.caption)
                                                .fontWeight(.bold)
                                                .foregroundColor(.orange)
                                                .multilineTextAlignment(.leading)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(Color.orange.opacity(0.08))
                                        .cornerRadius(8)
                                        .padding(.leading, 64)
                                    }
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity)
                                .background(AppTheme.cardBackground)
                                .cornerRadius(14)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(isThisCurrent ? AppTheme.text.opacity(0.15) : Color.clear, lineWidth: 1)
                                )
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black.opacity(0.7))
                }
            }
        }
    }
}
