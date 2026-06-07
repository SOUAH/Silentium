//
//  BioReliefView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct BioReliefView: View {
    @EnvironmentObject var engine: TinnitusAppEngine
    @State private var isBreathing = false
    @State private var showingPermissionAlert = false
    @State private var alertErrorMessage = ""
    
    @AppStorage("isBiometricTrackingEnabled") private var isTrackingEnabledLocal = false
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 25) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bio-Adaptive Relief")
                        .font(.system(size: 34, weight: .bold))
                        .foregroundColor(AppTheme.text)
                    
                    Text("Real-time biometric tinnitus mitigation")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(AppTheme.text.opacity(0.6))
                }
                .padding(.horizontal)
                .padding(.top, 18)
                
                ZStack {
                    Circle()
                        .stroke(AppTheme.text.opacity(0.03), lineWidth: 24)
                        .frame(width: 190, height: 190)
                    
                    Circle()
                        .stroke(
                            engine.stressLevel == "Spike" ? Color.red.opacity(0.6) : AppTheme.text,
                            style: StrokeStyle(lineWidth: 20, lineCap: .round)
                        )
                        .frame(width: 190, height: 190)
                        .scaleEffect(isBreathing && isTrackingEnabledLocal ? 1.05 : 1.0)
                        .animation(isTrackingEnabledLocal ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true) : .default, value: isBreathing)
                    
                    VStack(spacing: 4) {
                        Image(systemName: isTrackingEnabledLocal ? "heart.text.square.fill" : "heart.slash.fill")
                            .font(.system(size: 28))
                            .foregroundColor(engine.stressLevel == "Spike" ? .red : AppTheme.text.opacity(0.7))
                        
                        Text(!isTrackingEnabledLocal ? "--" : (engine.currentHeartRate == 0 ? "..." : "\(engine.currentHeartRate)"))
                            .font(.system(size: 54, weight: .bold, design: .monospaced))
                            .foregroundColor(AppTheme.text)
                        
                        Text("BPM")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.text.opacity(0.5))
                    }
                }
                .frame(height: 200)
                .onAppear {
                    isBreathing = true
                    if isTrackingEnabledLocal {
                        engine.startHealthKitMonitoring()
                    }
                }
                
                VStack(spacing: 12) {
                    Toggle(isOn: $isTrackingEnabledLocal) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Sync Apple Watch")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(AppTheme.text)
                            Text("Adapt audio therapy to stress responses")
                                .font(.system(size: 13))
                                .foregroundColor(AppTheme.text.opacity(0.5))
                        }
                    }
                    .tint(.orange)
                    .onChange(of: isTrackingEnabledLocal) { oldValue, newValue in
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
                .background(AppTheme.cardBackground)
                .cornerRadius(20)
                .padding(.horizontal)
                
                VStack(spacing: 16) {
                    MetricRow(
                        title: "Nervous System",
                        value: !isTrackingEnabledLocal ? "Disabled" : engine.stressLevel,
                        statusColor: stressLevelColor(for: engine.stressLevel),
                        icon: "waveform.path.ecg"
                    )
                    
                    Divider().background(AppTheme.text.opacity(0.08))
                    
                    MetricRow(
                        title: "Adaptive Compensation",
                        value: !isTrackingEnabledLocal ? "Inactive" : adaptiveCompensationText(for: engine.stressLevel),
                        statusColor: AppTheme.text,
                        icon: "slider.horizontal.below.square.filled.and.square"
                    )
                }
                .padding(20)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(AppTheme.cardBackground)
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
}

