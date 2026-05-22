//
//  BioReliefView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct BioReliefView: View {
    @ObservedObject var engine: TinnitusAppEngine
    @State private var isBreathing = false
    @State private var showingPermissionAlert = false
    @State private var alertErrorMessage = ""
    
    @AppStorage("isBiometricTrackingEnabled") private var isTrackingEnabledLocal = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 25) {
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
                        .frame(width: 190, height: 190)
                    
                    Circle()
                        .stroke(
                            engine.stressLevel == "Spike" ? AnyShapeStyle(Color.red.opacity(0.6)) : AnyShapeStyle(AppTheme.accentGradient),
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 190, height: 190)
                        .scaleEffect(isBreathing && isTrackingEnabledLocal ? 1.05 : 1.0)
                        .animation(isTrackingEnabledLocal ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default, value: isBreathing)
                    
                    VStack(spacing: 4) {
                        Image(systemName: isTrackingEnabledLocal ? "heart.text.square.fill" : "heart.slash.fill")
                            .font(.system(size: 28))
                            .foregroundColor(engine.stressLevel == "Spike" ? .red : .black.opacity(0.7))
                        
                        Text(!isTrackingEnabledLocal ? "--" : (engine.currentHeartRate == 0 ? "..." : "\(engine.currentHeartRate)"))
                            .font(.system(size: 54, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                        
                        Text("BPM")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.black.opacity(0.5))
                    }
                }
                .frame(height: 200)
                .onAppear {
                    isBreathing = true
                    if isTrackingEnabledLocal {
                        engine.startHealthKitMonitoring()
                    }
                }
                
                // 3. Automation Toggle Module
                VStack(spacing: 12) {
                    Toggle(isOn: $isTrackingEnabledLocal) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync Apple Watch")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.black)
                            Text("Adapt audio therapy to stress responses")
                                .font(.system(size: 13))
                                .foregroundColor(.black.opacity(0.5))
                        }
                    }
                    .tint(.orange)
                    .onChange(of: isTrackingEnabledLocal) { newValue in
                        if newValue {
                            engine.requestHealthKitPermission { success, error in
                                if success {
                                    engine.startHealthKitMonitoring()
                                } else {
                                    isTrackingEnabledLocal = false
                                    engine.stopHealthKitMonitoring()
                                    if let error = error {
                                        alertErrorMessage = error.localizedDescription
                                        showingPermissionAlert = true
                                    }
                                }
                            }
                        } else {
                            engine.stopHealthKitMonitoring()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color.white)
                .cornerRadius(20)
                .padding(.horizontal)
                
                // 4. Clinical Metrics Cards
                VStack(spacing: 16) {
                    MetricRow(
                        title: "Nervous System",
                        value: !isTrackingEnabledLocal ? "Disabled" : engine.stressLevel,
                        statusColor: stressLevelColor(for: engine.stressLevel),
                        icon: "waveform.path.ecg"
                    )
                    
                    Divider().background(Color.black.opacity(0.08))
                    
                    MetricRow(
                        title: "Adaptive Compensation",
                        value: !isTrackingEnabledLocal ? "Inactive" : adaptiveCompensationText(for: engine.stressLevel),
                        statusColor: .black,
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
                
                Spacer()
            }
        }
        .alert("Health Access Required", isPresented: $showingPermissionAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertErrorMessage.isEmpty ? "Please enable Heart Rate access permissions inside Apple Health settings." : alertErrorMessage)
        }
    }
    
    private func stressLevelColor(for level: String) -> Color {
        guard isTrackingEnabledLocal else { return .gray }
        switch level {
        case "Spike": return .red
        case "Elevated": return .orange
        case "Stable": return .green
        default: return .gray
        }
    }
    
    private func adaptiveCompensationText(for level: String) -> String {
        guard isTrackingEnabledLocal else { return "Inactive" }
        switch level {
        case "Spike": return "+15% Extra Masking"
        case "Elevated": return "+5% Masking"
        case "Stable": return "Optimal Depth"
        default: return "Calibrating..."
        }
    }
    
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
}
