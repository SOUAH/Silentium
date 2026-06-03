//
//  CoherenceBreathingView.swift
//  Silentium
//
//  Created by Souha Aouididi on 22/05/26.
//

import SwiftUI

enum BreathMethod: String, CaseIterable, Identifiable {
    case resonant = "resonant"
    case box = "box"
    case fourSevenEight = "fourSevenEight"

    var id: String { rawValue }

    var name: String {
        switch self {
        case .resonant: return "Resonant Breathing"
        case .box: return "Box Breathing"
        case .fourSevenEight: return "4-7-8 Breathing"
        }
    }

    var icon: String {
        switch self {
        case .resonant: return "waveform.path.ecg"
        case .box: return "square"
        case .fourSevenEight: return "lungs.fill"
        }
    }

    var themeColor: Color {
        switch self {
        case .resonant: return Color(red: 0.96, green: 0.34, blue: 0.42)
        case .box: return Color(red: 0.07, green: 0.60, blue: 0.56)
        case .fourSevenEight: return Color(red: 0.46, green: 0.29, blue: 0.64)
        }
    }

    var gradient: [Color] {
        switch self {
        case .resonant: return [Color(red: 0.94, green: 0.58, blue: 0.98), Color(red: 0.96, green: 0.34, blue: 0.42)]
        case .box: return [Color(red: 0.07, green: 0.60, blue: 0.56), Color(red: 0.22, green: 0.94, blue: 0.49)]
        case .fourSevenEight: return [Color(red: 0.40, green: 0.49, blue: 0.92), Color(red: 0.46, green: 0.29, blue: 0.64)]
        }
    }

    var phases: (inhale: Int, hold1: Int, exhale: Int, hold2: Int) {
        switch self {
        case .resonant: return (5, 0, 5, 0)
        case .box: return (4, 4, 4, 4)
        case .fourSevenEight: return (4, 7, 8, 0)
        }
    }
}

struct BreathingView: View {
    @ObservedObject var engine: TinnitusAppEngine
    
    @State private var selectedTechnique: BreathMethod = .resonant
    @State private var isSessionActive = false
    @State private var currentPhaseText = "Ready"
    @State private var secondsRemainingInPhase = 0
    @State private var circleScale: CGFloat = 1.0
    @State private var circleOpacity: Double = 0.4
    @State private var phaseTimer: Timer? = nil
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Vagus Regulation")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.black)
                        Text("Calm your body to drop tinnitus focus")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.black.opacity(0.6))
                    }
                    .padding(.top, 20)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 20)
                .padding(.bottom, 10)
                
                if !isSessionActive {
                    Spacer(minLength: 10)
                    
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: selectedTechnique.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 240, height: 240)
                            .scaleEffect(circleScale)
                            .opacity(circleOpacity * 0.2)
                        
                        Circle()
                            .fill(LinearGradient(colors: selectedTechnique.gradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 200, height: 200)
                            .scaleEffect(circleScale)
                            .opacity(circleOpacity)
                        
                        VStack(spacing: 8) {
                            Image(systemName: selectedTechnique.icon)
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(.white)
                            
                            Text(currentPhaseText.uppercased())
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                                .tracking(2)
                            
                            if secondsRemainingInPhase > 0 {
                                Text("\(secondsRemainingInPhase)s")
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .frame(height: 250)
                    
                    Spacer(minLength: 15)
                    
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 10) {
                            ForEach(BreathMethod.allCases) { technique in
                                Button(action: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        selectedTechnique = technique
                                    }
                                }) {
                                    HStack(spacing: 16) {
                                        Image(systemName: technique.icon)
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(technique.themeColor)
                                            .frame(width: 30)
                                        
                                        Text(technique.name)
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(.black)
                                        
                                        Spacer()
                                        
                                        if selectedTechnique == technique {
                                            Image(systemName: "checkmark.circle.fill")
                                                .font(.system(size: 18, weight: .bold))
                                                .foregroundStyle(AppTheme.accentGradient)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                    .frame(height: 50)
                                    .background(selectedTechnique == technique ? Color.white : Color.white.opacity(0.4))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedTechnique == technique ? Color.black : Color.clear, lineWidth: 1.5)
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    .frame(maxHeight: 200)
                    
                    Spacer(minLength: 20)
                    
                } else {
                    Spacer()
                    ZStack {
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
                            
                            if secondsRemainingInPhase > 0 {
                                Text("\(secondsRemainingInPhase)s")
                                    .font(.system(size: 26, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white.opacity(0.9))
                            }
                        }
                    }
                    .frame(height: 270)
                    Spacer()
                }
                
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
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 54)
                    .background(
                        Capsule()
                            .fill(AppTheme.accentGradient)
                            .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
            }
        }
    }
    
    private func startBreathingSession() {
        let cyclePhases = selectedTechnique.phases
        var currentCycleIndex = 0
        
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
                targetScale = 1.25
                targetOpacity = 0.8
            case 1:
                phaseDuration = cyclePhases.hold1
                phaseName = cyclePhases.hold1 > 0 ? "Hold" : ""
                targetScale = 1.25
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
        withAnimation(.fileUnwrappedOptional) {
            currentPhaseText = "Ready"
            secondsRemainingInPhase = 0
            circleScale = 1.0
            circleOpacity = 0.4
        }
    }
}

extension Animation {
    static var fileUnwrappedOptional: Animation { .easeOut(duration: 0.3) }
}
