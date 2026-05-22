//
//  ToneFinderView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct ToneFinderView: View {
    @Environment(\.dismiss) var dismiss
    
    // Receive the shared engine from parent view
    @ObservedObject var engine: TinnitusAppEngine
    
    var isFirstTime: Bool = false
    var onComplete: (() -> Void)? = nil
    
    // Interactive Frequency Tracking State
    @State private var frequency: Double
    
    // Constant clinical baseline amplitude since loudness control was removed
    private let fixedLoudnessBaseline: Double = 40.0
    
    // Frequency range boundaries
    private let minFrequency: Double = 100.0
    private let maxFrequency: Double = 18000.0
    
    // Custom initializer syncing internal properties with the active engine profile
    init(engine: TinnitusAppEngine, isFirstTime: Bool = false, onComplete: (() -> Void)? = nil) {
        self.engine = engine
        self.isFirstTime = isFirstTime
        self.onComplete = onComplete
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
                        
                        Text("Rotate the outer dial to match your tinnitus pitch")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .padding(.top, 20)
                    
                    Spacer()
                    
                    if !isFirstTime {
                        Button(action: {
                            engine.stopTestTone()
                            dismiss()
                        }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.black.opacity(0.7))
                                .padding(10)
                                .background(Circle().fill(Color.black.opacity(0.05)))
                        }
                        .padding(.top, 20)
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 30)
                
                // 2. Interactive Circular Dial (Replaced Sliders Card)
                ZStack {
                    // Track Background ring
                    Circle()
                        .stroke(Color.black.opacity(0.05), lineWidth: 24)
                        .frame(width: 270, height: 270)
                    
                    // Filled progressive arc tracking the current frequency location
                    Circle()
                        .trim(from: 0, to: CGFloat((frequency - minFrequency) / (maxFrequency - minFrequency)))
                        .stroke(AppTheme.accentGradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 270, height: 270)
                        .rotationEffect(.degrees(-90))
                    
                    // Drag Indicator Handle Thumb Button Node
                    GeometryReader { geometry in
                        let size = geometry.size
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let radius = min(size.width, size.height) / 2
                        
                        // Mathematics plotting target radial translation coordinates natively
                        let angleInRadians = radiansForCurrentFrequency()
                        let handlePositionX = center.x + CGFloat(cos(angleInRadians)) * (radius - 12)
                        let handlePositionY = center.y + CGFloat(sin(angleInRadians)) * (radius - 12)
                        
                        Circle()
                            .fill(Color.white)
                            .frame(width: 36, height: 36)
                            .shadow(color: Color.black.opacity(0.18), radius: 6, y: 3)
                            .position(x: handlePositionX, y: handlePositionY)
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { gestureDetails in
                                        evaluateFrequencyFromTouch(gestureDetails.location, frameSize: size)
                                    }
                            )
                    }
                    .frame(width: 270, height: 270)
                    
                    // Central Numeric Status Text Label View Metrics
                    VStack(spacing: 4) {
                        Text("\(Int(frequency))")
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                        
                        Text("Hz")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black.opacity(0.4))
                    }
                }
                .frame(width: 290, height: 290)
                
                Spacer(minLength: 40)
                
                // 3. Informational Diagnostic Instructions
                VStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.orange)
                    
                    Text("Set volume to 50% for safety. Then slowly rotate the indicator around the circle ring contour boundaries to calibrate adjustments seamlessly.")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.black.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer(minLength: 30)
                
                // 4. Save Button
                Button(action: {
                    engine.setFinalCalibratedFrequency(frequency)
                    engine.stopTestTone()
                    
                    if isFirstTime {
                        onComplete?()
                    } else {
                        dismiss()
                    }
                }) {
                    Text(isFirstTime ? "Finish Setup" : "Save Calibration")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.accentGradient)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 20)
        }
        .onAppear {
            engine.startTestTone(frequency: frequency, volume: fixedLoudnessBaseline)
        }
        .onDisappear {
            engine.stopTestTone()
        }
    }
    
    // Translates the standard frequency progression scalar curve scale back into circular radians
    private func radiansForCurrentFrequency() -> Double {
        let linearRatio = (frequency - minFrequency) / (maxFrequency - minFrequency)
        let totalDegrees = (linearRatio * 360.0) - 90.0 // Offset -90 to center origin point vertical top at 12 o'clock
        return totalDegrees * .pi / 180.0
    }
    
    // Calculates the touch target locations down into native software system audio variables
    private func evaluateFrequencyFromTouch(_ location: CGPoint, frameSize: CGSize) {
        let centerPoint = CGPoint(x: frameSize.width / 2, y: frameSize.height / 2)
        let horizontalVector = Double(location.x - centerPoint.x)
        let verticalVector = Double(location.y - centerPoint.y)
        
        var polarAngleDegrees = atan2(verticalVector, horizontalVector) * 180.0 / .pi
        polarAngleDegrees += 90.0 // Readjust angle reference matrix configuration back to standard matching top track offset
        
        if polarAngleDegrees < 0 {
            polarAngleDegrees += 360.0
        }
        
        let circularPercentage = polarAngleDegrees / 360.0
        let transformedFrequencyOutput = minFrequency + (circularPercentage * (maxFrequency - minFrequency))
        
        // Clamping mutations tightly into structural constraint thresholds before setting state
        self.frequency = max(minFrequency, min(maxFrequency, transformedFrequencyOutput))
        
        // Pass updates instantly into system DSP audio hardware card layers
        engine.updateTestTone(frequency: self.frequency, volume: fixedLoudnessBaseline)
    }
}
