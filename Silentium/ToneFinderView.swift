//
//  ToneFinderView.swift
//  Tinnitus
//
//  Created by Sara Riccone on 07/05/26.
//

import SwiftUI

struct ToneFinderView: View {
    @Environment(\.dismiss) var dismiss
    
    // CHANGE 1: Receive the engine from the parent view.
    // Do not use @StateObject here, or it will create a second "silent" engine.
    @ObservedObject var engine: TinnitusAppEngine
    
    var isFirstTime: Bool = false
    var onComplete: (() -> Void)? = nil
    
    // Initialize sliders with the existing calibrated frequency from the engine.
    @State private var frequency: Double
    @State private var loudness: Double = 40
    
    // Custom init to sync sliders with the engine's current data.
    init(engine: TinnitusAppEngine, isFirstTime: Bool = false, onComplete: (() -> Void)? = nil) {
        self.engine = engine
        self.isFirstTime = isFirstTime
        self.onComplete = onComplete
        // Start the slider at whatever frequency was previously saved in the engine.
        self._frequency = State(initialValue: engine.calibratedFrequency)
    }
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Header Section
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Find Your Tone")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Pinpoint your tinnitus frequency")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .padding(.top, 20) // Moved padding here to affect only the VStack
                    
                    Spacer()
                    
                    // Exit Button is ONLY visible when accessing via Mixer (not first time)
                    if !isFirstTime {
                        Button(action: {
                            engine.stopTestTone() // CHANGE 2: Use the injected engine
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black.opacity(0.7))
                                .padding(10)
                                .background(Circle().fill(Color.black.opacity(0.05)))
                        }
                        .padding(.top, 20) // Added padding here for consistency
                    }
                }
                .padding(.horizontal, 24) // Apply horizontal padding to the HStack itself
                
                Spacer(minLength: 10)
                
                // 2. Visual Frequency Gauge
                ZStack {
                    Circle()
                        .stroke(Color.black.opacity(0.05), lineWidth: 20)
                    
                    Circle()
                        .trim(from: 0, to: CGFloat((frequency - 100) / 17900))
                        .stroke(AppTheme.accentGradient, style: StrokeStyle(lineWidth: 18, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                        .animation(.interactiveSpring, value: frequency)
                    
                    VStack(spacing: 4) {
                        Text("\(Int(frequency))")
                            .font(.system(size: 44, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                        
                        Text("Hz")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }
                .frame(height: 220)
                .padding(.horizontal, 24) // Added horizontal padding here as well
                
                Spacer(minLength: 10)
                
                // 3. Control Sliders Card
                VStack(spacing: 20) {
                    SliderRow(icon: "tuningfork", label: "Pitch", value: $frequency, range: 100...18000, unit: "Hz")
                        .onChange(of: frequency) { newValue in
                            engine.updateTestTone(frequency: newValue, volume: loudness) // CHANGE 3: Use the injected engine
                        }
                    
                    Divider().background(Color.black.opacity(0.1))
                    
                    SliderRow(icon: "speaker.wave.2.fill", label: "Loudness", value: $loudness, range: 0...100, unit: "%")
                        .onChange(of: loudness) { newValue in
                            engine.updateTestTone(frequency: frequency, volume: newValue) // CHANGE 4: Use the injected engine
                        }
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppTheme.cardBackground)
                        .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
                )
                .padding(.horizontal, 24) // Added horizontal padding here
                
                Spacer(minLength: 20)
                
                // 4. Save Button
                Button(action: {
                    // CHANGE 5: Save the real data to the engine
                    engine.setFinalCalibratedFrequency(frequency)
                    engine.stopTestTone() // CHANGE 6: Use the injected engine
                    
                    if isFirstTime {
                        onComplete?()
                    } else {
                        dismiss()
                    }
                }) {
                    Text(isFirstTime ? "Finish Setup" : "Save & Done")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.accentGradient)
                        .cornerRadius(14)
                }
                .padding(.horizontal, 24) // Added horizontal padding here
            }
            .padding(.bottom, 20) // Keep bottom padding for the whole VStack
        }
        .onAppear {
            engine.startTestTone(frequency: frequency, volume: loudness) // CHANGE 7: Use the injected engine
        }
        .onDisappear {
            engine.stopTestTone() // CHANGE 8: Use the injected engine
        }
    }
}
