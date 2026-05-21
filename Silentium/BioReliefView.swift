//
//  BioReliefView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct BioReliefView: View {
    // CHANGE THIS LINE: Ensure it says @ObservedObject, NOT @EnvironmentObject
    @ObservedObject var engine: TinnitusAppEngine
    
    @State private var isBreathing = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // 1. Header Section
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bio-Adaptive Relief")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("Real-time biometric tinnitus mitigation")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.black.opacity(0.6))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(.horizontal)
                .padding(.top, 18)
                
                // 2. The Biometric Pulse Ring
                ZStack {
                    Circle()
                        .stroke(Color.black.opacity(0.03), lineWidth: 24)
                        .frame(width: 200, height: 200)
                    
                    // Dynamic color shifts to alert user during stress spikes
                    Circle()
                        .stroke(
                            engine.stressLevel == "Spike" ? AnyShapeStyle(Color.red.opacity(0.6)) : AnyShapeStyle(AppTheme.accentGradient),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 200, height: 200)
                        .scaleEffect(isBreathing ? 1.08 : 1.0)
                        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isBreathing)
                    
                    VStack(spacing: 4) {
                        Image(systemName: "heart.text.square.fill")
                            .font(.system(size: 28))
                            .foregroundColor(engine.stressLevel == "Spike" ? .red : .black)
                        
                        Text(engine.currentHeartRate == 0 ? "--" : "\(engine.currentHeartRate)") // Display "--" if no data
                            .font(.system(size: 54, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                        
                        Text("BPM")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black.opacity(0.5))
                    }
                }
                .frame(height: 220)
                .onAppear {
                    isBreathing = true
                    engine.startHealthKitMonitoring() // Start HealthKit monitoring
                }
                
                // 3. Clinical Metrics Cards
                VStack(spacing: 16) {
                    MetricRow(
                        title: "Nervous System",
                        value: engine.stressLevel,
                        statusColor: stressLevelColor(for: engine.stressLevel),
                        icon: "waveform.path.ecg"
                    )
                    
                    Divider().background(Color.black.opacity(0.08))
                    
                    MetricRow(
                        title: "Adaptive Compensation",
                        value: adaptiveCompensationText(for: engine.stressLevel),
                        statusColor: .black, // This color does not change based on stress level in the original
                        icon: "slider.horizontal.below.square.filled.and.square"
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.white)
                        .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
                )
                .padding(.horizontal)
                
                // 4. Interactive Regulation Module (Vagus Nerve Stimulation)
                VStack(spacing: 12) {
                    Text("Feeling a Tinnitus Spike?")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black.opacity(0.7))
                    
                    Button(action: {
                        // This button can now trigger a breathing exercise UI or guide,
                        // but it should not directly manipulate the engine's biometric states
                        // as they are now driven by HealthKit.
                        // For example:
                        // engine.startBreathingExercise()
                        print("User tapped Begin Coherence Breathing. Implement actual breathing exercise logic.")
                    }) {
                        HStack {
                            Image(systemName: "lungs.fill")
                            Text("Begin Coherence Breathing")
                        }
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.black)
                        .cornerRadius(16)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
            }
        }
    }
    
    // Helper function to determine color based on stress level string
    private func stressLevelColor(for level: String) -> Color {
        switch level {
        case "Spike": return .red
        case "Elevated": return .orange
        case "Stable": return .green
        default: return .gray // For "Unknown" or "No Data"
        }
    }
    
    // Helper function for Adaptive Compensation text
    private func adaptiveCompensationText(for level: String) -> String {
        switch level {
        case "Spike": return "+15% Extra Masking"
        case "Elevated": return "+5% Masking"
        case "Stable": return "Optimal Depth"
        default: return "Calibrating..." // For "Unknown" or "No Data"
        }
    }
}

// Reusable Clinical Row Component
struct MetricRow: View {
    let title: String
    let value: String
    let statusColor: Color
    let icon: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(.black.opacity(0.6))
                .frame(width: 30)
            
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.black.opacity(0.8))
            
            Spacer()
            
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(statusColor)
        }
    }
}

#Preview {
    BioReliefView(engine: TinnitusAppEngine())
}
