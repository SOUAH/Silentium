//
//  WelcomeView.swift
//  Tinnitus
//
//  Created by Sara Riccone on 07/05/26.
//

import SwiftUI

struct WelcomeView: View {
    @State private var phase: CGFloat = 0.0
    
    // This is the missing piece: it links back to the @AppStorage in MainTabView
    @Binding var hasStarted: Bool
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                headerSection
                Spacer(minLength: 40)
                
                SilkWaveView(phase: phase)
                
                Spacer(minLength: 60)
                featuresSection
                Spacer(minLength: 40)
                getStartedButton
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 8).repeatForever(autoreverses: false)) {
                phase = .pi * 2
            }
        }
    }
    
    private var headerSection: some View {
            VStack(spacing: 12) { // Adjusted spacing for a cleaner look
                Text("Welcome to Silentium!")
                    .font(.system(size: 30, weight: .bold, design: .default)) // SF Pro Bold
                    .foregroundColor(.black)
                
                Text("A calm path to a quieter world.")
                    .font(.system(size: 18, weight: .medium, design: .default)) // SF Pro Medium
                    .foregroundColor(.gray)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity) // Centers the VStack horizontally
            .padding(.top, 80)
            .padding(.horizontal, 40)
        }
    
    private var featuresSection: some View {
        VStack(alignment: .leading, spacing: 36) {
            FeatureRow(
                symbol: "waveform.badge.minus",
                title: "Notched Sound Therapy",
                desc: "Precisely filters your tinnitus frequency to retrain your auditory cortex."
            )
            
            FeatureRow(
                symbol: "heart.text.square.fill",
                title: "Bio-Responsive Stress Masking",
                desc: "Real-time HealthKit integration adapts audio to your heart rate and stress levels."
            )
        }
        .padding(.horizontal, 35)
    }
    
    private var getStartedButton: some View {
        // Updated action to switch the view
        Button(action: {
            withAnimation {
                hasStarted = true
            }
        }) {
            Text("Let’s get started")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(AppTheme.text)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
                .background(
                    Capsule()
                        .fill(AppTheme.cardBackground)
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                )
        }
        .padding(.horizontal, 40)
        .padding(.bottom, 50)
    }
}

// Sub-views kept to prevent compiler timeouts
struct SilkWaveView: View {
    let phase: CGFloat
    
    var body: some View {
        ZStack {
            ForEach(0..<20) { i in
                let offsetPhase = phase + CGFloat(i) * 0.1
                let amplitude = 8 + CGFloat(i) * 0.5
                let verticalOffset = CGFloat(i) * 1.5
                let lineOpacity = 0.1 + Double(i) * 0.03
                
                WaveShape(phase: offsetPhase, amplitude: amplitude)
                    .stroke(AppTheme.accentGradient, lineWidth: 0.25)
                    .opacity(lineOpacity)
                    .offset(y: verticalOffset)
            }
        }
        .frame(height: 100)
    }
}

struct FeatureRow: View {
    let symbol: String
    let title: String
    let desc: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 22) {
            Image(systemName: symbol)
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(AppTheme.accentGradient)
                .frame(width: 38, alignment: .center)

            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppTheme.text.opacity(0.85))
                Text(desc)
                    .font(.system(size: 15))
                    .foregroundColor(AppTheme.text.opacity(0.6))
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct WaveShape: Shape {
    var phase: CGFloat
    var amplitude: CGFloat
    
    var animatableData: CGFloat {
        get { phase }
        set { phase = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let midHeight = rect.height / 2
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, to: width, by: 1) {
            let relativeX = x / width
            let sine = sin(relativeX * .pi * 2.5 + phase)
            path.addLine(to: CGPoint(x: x, y: midHeight + sine * amplitude))
        }
        return path
    }
}
