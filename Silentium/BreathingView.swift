//
//  CoherenceBreathingView.swift
//  Silentium
//
//  Created by Souha Aouididi on 22/05/26.
//

import SwiftUI

//Local Breathing Technique Configuration Engine
enum BreathMethod: String, CaseIterable, Identifiable {
    case resonant = "resonant"
    case box = "box"
    case fourSevenEight = "fourSevenEight"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .resonant: "Resonant Breathing"
        case .box: "Box Breathing"
        case .fourSevenEight: "4-7-8 Breathing"
        }
    }

    var icon: String {
        switch self {
        case .resonant: "waveform.path.ecg"
        case .box: "square"
        case .fourSevenEight: "lungs.fill"
        }
    }

    var themeColor: Color {
        switch self {
        case .resonant: Color(red: 0.96, green: 0.34, blue: 0.42)
        case .box: Color(red: 0.07, green: 0.60, blue: 0.56)
        case .fourSevenEight: Color(red: 0.46, green: 0.29, blue: 0.64)
        }
    }

    var gradient: [Color] {
        switch self {
        case .resonant: [Color(red: 0.94, green: 0.58, blue: 0.98), Color(red: 0.96, green: 0.34, blue: 0.42)]
        case .box: [Color(red: 0.07, green: 0.60, blue: 0.56), Color(red: 0.22, green: 0.94, blue: 0.49)]
        case .fourSevenEight: [Color(red: 0.40, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]
        }
    }

    var phases: (inhale: Int, hold1: Int, exhale: Int, hold2: Int) {
        switch self {
        case .resonant: (5, 0, 5, 0)
        case .box: (4, 4, 4, 4)
        case .fourSevenEight: (4, 7, 8, 0)
        }
    }
}

// Main Interface Layout
struct BreathingView: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedTechnique: BreathMethod = .resonant
    @State private var isSessionActive = false
    @State private var currentPhaseText = "Ready"
    @State private var secondsRemainingInPhase = 0
    @State private var circleScale: CGFloat = 1.0
    @State private var circleOpacity: Double = 0.4
    
    @State private var phaseTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            // App-standard off-white background coverage
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Navigation Header
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vagus Regulation")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        Text("Calm your body to drop tinnitus focus")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    Spacer()
                    
                    Button(action: {
                        stopBreathingSession()
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.black.opacity(0.7))
                            .padding(12)
                            .background(Circle().fill(Color.black.opacity(0.05)))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                
                Spacer(minLength: 20)
                
                // 2. Interactive Pacing Ring Circle Container
                ZStack {
                    // Outer Pulsing Halos
                    Circle()
                        .fill(LinearGradient(colors: selectedTechnique.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 250, height: 250)
                        .scaleEffect(circleScale)
                        .opacity(circleOpacity * 0.2)
                    
                    Circle()
                        .fill(LinearGradient(colors: selectedTechnique.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 210, height: 210)
                        .scaleEffect(circleScale)
                        .opacity(circleOpacity)
                    
                    VStack(spacing: 8) {
                        Image(systemName: selectedTechnique.icon)
                            .font(.system(size: 34, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        Text(currentPhaseText.uppercased())
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(2)
                        
                        if isSessionActive && secondsRemainingInPhase > 0 {
                            Text("\(secondsRemainingInPhase)s")
                                .font(.system(size: 26, weight: .bold, design: .monospaced))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
                .frame(height: 290)
                
                Spacer(minLength: 20)
                
                // 3. Dynamic Button Cards Selector Stack
                if !isSessionActive {
                    VStack(spacing: 12) {
                        ForEach(BreathMethod.allCases) { technique in
                            Button(action: {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                    selectedTechnique = technique
                                }
                            }) {
                                HStack(spacing: 16) {
                                    Image(systemName: technique.icon)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(technique.themeColor)
                                        .frame(width: 32)
                                    
                                    Text(technique.name)
                                        .font(.system(size: 17, weight: .bold))
                                        .foregroundColor(.black)
                                    
                                    Spacer()
                                    
                                    if selectedTechnique == technique {
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 20, weight: .bold))
                                            // Use AppTheme.accentGradient for the checkmark
                                            .foregroundStyle(AppTheme.accentGradient)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 18)
                                .background(selectedTechnique == technique ? Color.white : Color.white.opacity(0.4))
                                .cornerRadius(16)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(selectedTechnique == technique ? Color.black : Color.clear, lineWidth: 1.5)
                                )
                                .shadow(color: Color.black.opacity(selectedTechnique == technique ? 0.04 : 0.0), radius: 6, y: 3)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(.horizontal, 24)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                } else {
                    // Hidden placeholder container layout spacer during execution state sessions
                    VStack { Spacer() }.frame(height: 196)
                }
                
                Spacer(minLength: 30)
                
                // 4. Primary Master Session Action Controller
                Button(action: {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        isSessionActive.toggle()
                    }
                    if isSessionActive {
                        startBreathingSession()
                    } else {
                        stopBreathingSession()
                    }
                }) {
                    HStack(spacing: 12) {
                        Image(systemName: isSessionActive ? "stop.fill" : "play.fill")
                        Text(isSessionActive ? "End Exercise" : "Begin Session")
                    }
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    // Use AppTheme.accentGradient for the button background
                    .background(AppTheme.accentGradient)
                    .cornerRadius(16)
                    .shadow(color: Color.black.opacity(0.15), radius: 8, y: 4)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
    }
}

// Core Execution Engine Controllers
extension BreathingView {
    
    private func startBreathingSession() {
        let cyclePhases = selectedTechnique.phases
        var currentCycleIndex = 0 // 0: Inhale, 1: Hold1, 2: Exhale, 3: Hold2
        
        func advancePhase() {
            guard isSessionActive else { return }
            if currentCycleIndex > 3 { currentCycleIndex = 0 }
            
            let phaseDuration: Int
            let phaseName: String
            var targetScale: CGFloat = 1.0
            var targetOpacity: Double = 0.4
            
            switch currentCycleIndex {
            case 0:
                phaseDuration = cyclePhases.inhale
                phaseName = "Inhale"
                targetScale = 1.3
                targetOpacity = 0.8
            case 1:
                phaseDuration = cyclePhases.hold1
                phaseName = cyclePhases.hold1 > 0 ? "Hold" : ""
                targetScale = 1.3
                targetOpacity = 0.8
            case 2:
                phaseDuration = cyclePhases.exhale
                phaseName = "Exhale"
                targetScale = 1.0
                targetOpacity = 0.4
            case 3:
                phaseDuration = cyclePhases.hold2
                phaseName = cyclePhases.hold2 > 0 ? "Hold" : ""
                targetScale = 1.0
                targetOpacity = 0.4
            default:
                return
            }
            
            if phaseDuration == 0 {
                currentCycleIndex += 1
                advancePhase()
                return
            }
            
            currentPhaseText = phaseName
            secondsRemainingInPhase = phaseDuration
            
            withAnimation(.easeInOut(duration: Double(phaseDuration))) {
                circleScale = targetScale
                circleOpacity = targetOpacity
            }
            
            phaseTimer?.invalidate()
            phaseTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                secondsRemainingInPhase -= 1
                if secondsRemainingInPhase <= 0 {
                    timer.invalidate()
                    currentCycleIndex += 1
                    advancePhase()
                }
            }
        }
        
        advancePhase()
    }
    
    private func stopBreathingSession() {
        phaseTimer?.invalidate()
        phaseTimer = nil
        withAnimation(.easeOut(duration: 0.3)) {
            currentPhaseText = "Ready"
            secondsRemainingInPhase = 0
            circleScale = 1.0
            circleOpacity = 0.4
        }
    }
}
