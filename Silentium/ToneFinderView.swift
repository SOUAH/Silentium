//
//  ToneFinderView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct ToneFinderView: View {
    @Environment(\.dismiss) var dismiss
    
    // Receive the shared engine from parent view context
    @ObservedObject var engine: TinnitusAppEngine
    
    var isFirstTime: Bool = false
    var onComplete: (() -> Void)? = nil
    
    // Interactive Frequency Tracking State
    @State private var frequency: Double
    
    // Core Activity State Row for Apple HIG Button Synchronization
    @State private var isSavingData = false
    
    // Constant clinical diagnostic scale tracking baseline amplitude
    private let fixedLoudnessBaseline: Double = 40.0
    
    // Frequency range boundaries matching standard audiometric profiles
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
                // 1. Header Section with streamlined text padding properties
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Find Your Tone")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(AppTheme.text)
                        
                        Text("Rotate the outer dial to match your tinnitus pitch")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppTheme.text.opacity(0.6))
                    }
                    .padding(.top, 10)
                    
                    Spacer()
                }
                .padding(.horizontal, 24)
                
                Spacer(minLength: 30)
                
                // 2. Interactive Circular Dial Selector Console
                ZStack {
                    // Track Background track contour
                    Circle()
                        .stroke(AppTheme.text.opacity(0.05), lineWidth: 24)
                        .frame(width: 270, height: 270)
                    
                    // Progressive fill arc tracing the selected frequency locus
                    Circle()
                        .trim(from: 0, to: CGFloat((frequency - minFrequency) / (maxFrequency - minFrequency)))
                        .stroke(AppTheme.accentGradient, style: StrokeStyle(lineWidth: 20, lineCap: .round))
                        .frame(width: 270, height: 270)
                        .rotationEffect(.degrees(-90)) // Aligns beginning point to top vertical 12 o'clock center
                    
                    // Radial Drag Indicator Thumb Handle Node
                    GeometryReader { geometry in
                        let size = geometry.size
                        let center = CGPoint(x: size.width / 2, y: size.height / 2)
                        let radius = min(size.width, size.height) / 2
                        
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
                                        guard !isSavingData else { return }
                                        evaluateFrequencyFromTouch(gestureDetails.location, frameSize: size)
                                    }
                            )
                    }
                    .frame(width: 270, height: 270)
                    
                    // Central Numeric Feedback Display metrics
                    VStack(spacing: 4) {
                        Text("\(Int(frequency))")
                            .font(.system(size: 48, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.text)
                        
                        Text("Hz")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(AppTheme.text.opacity(0.4))
                    }
                }
                .frame(width: 290, height: 290)
                
                Spacer(minLength: 40)
                
                // 3. Clinical Safety and Usage Warning Prompt Card
                VStack(spacing: 8) {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.orange)
                    
                    Text("Set volume to 50% for safety. Then slowly rotate the indicator around the circle ring contour boundaries to calibrate adjustments seamlessly.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(AppTheme.text.opacity(0.45))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer(minLength: 30)
                
                // 4. HIG Platform Consideration Synchronized Button Action Flow
                Button(action: {
                    guard !isSavingData else { return }
                    
                    let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
                    feedbackGenerator.impactOccurred()
                    
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isSavingData = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.25) {
                        engine.setFinalCalibratedFrequency(frequency)
                        engine.stopTestTone()
                        
                        isSavingData = false
                        
                        if isFirstTime {
                            onComplete?()
                        } else {
                            dismiss()
                        }
                    }
                }) {
                    HStack(spacing: 12) {
                        if isSavingData {
                            ProgressView()
                                .tint(.white)
                        }
                        Text(isSavingData ? (isFirstTime ? "Finishing..." : "Saving...") : (isFirstTime ? "Finish Setup" : "Save Calibration"))
                    }
                }
                .buttonStyle(GradientCapsuleButtonStyle())
                .disabled(isSavingData)
                .padding(.horizontal, 24)
            }
            .padding(.bottom, 20)
        }
        // 👈 FIXED: Left custom hardcoded toolbars commented out to let the native system navigation back chevron function seamlessly without overlap
        .onAppear {
            engine.startTestTone(frequency: frequency, volume: fixedLoudnessBaseline)
        }
        .onDisappear {
            engine.stopTestTone()
        }
    }
    
    // MARK: - Internal Calculations Matrix
    
    private func radiansForCurrentFrequency() -> Double {
        let linearRatio = (frequency - minFrequency) / (maxFrequency - minFrequency)
        let totalDegrees = (linearRatio * 360.0) - 90.0
        return totalDegrees * .pi / 180.0
    }
    
    private func evaluateFrequencyFromTouch(_ location: CGPoint, frameSize: CGSize) {
        let centerPoint = CGPoint(x: frameSize.width / 2, y: frameSize.height / 2)
        let horizontalVector = Double(location.x - centerPoint.x)
        let verticalVector = Double(location.y - centerPoint.y)
        
        var polarAngleDegrees = atan2(verticalVector, horizontalVector) * 180.0 / .pi
        polarAngleDegrees += 90.0
        
        if polarAngleDegrees < 0 {
            polarAngleDegrees += 360.0
        }
        
        let circularPercentage = polarAngleDegrees / 360.0
        let transformedFrequencyOutput = minFrequency + (circularPercentage * (maxFrequency - minFrequency))
        
        self.frequency = max(minFrequency, min(maxFrequency, transformedFrequencyOutput))
        engine.updateTestTone(frequency: self.frequency, volume: fixedLoudnessBaseline)
    }
}
