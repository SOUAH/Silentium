//
//  BioReliefView.swift
//  Silentium
//

import SwiftUI
import HealthKit

struct BioReliefView: View {
    @EnvironmentObject var engine: TinnitusAppEngine
    @State private var isBreathing = false
    @State private var showingPermissionAlert = false
    @State private var alertErrorMessage = ""

    // Persisted so the toggle state survives app restarts
    @AppStorage("isBiometricTrackingEnabled") private var isTrackingEnabledLocal = false

    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {

                    // ── Header ───────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Bio-Adaptive Relief")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(AppTheme.text)
                        Text("Real-time biometric tinnitus mitigation")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(AppTheme.text.opacity(0.6))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)
                    .padding(.top, 18)

                    // ── Heart Rate Ring ──────────────────────────────────────
                    ZStack {
                        Circle()
                            .stroke(AppTheme.text.opacity(0.04), lineWidth: 24)
                            .frame(width: 190, height: 190)

                        Circle()
                            .stroke(
                                engine.stressLevel == "Spike"
                                    ? AnyShapeStyle(Color.red.opacity(0.7))
                                    : AnyShapeStyle(LinearGradient(
                                        colors: [Color.orange, Color.orange.opacity(0.5)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                      ).opacity(isTrackingEnabledLocal ? 1 : 0.3)),
                                style: StrokeStyle(lineWidth: 20, lineCap: .round)
                            )
                            .frame(width: 190, height: 190)
                            .scaleEffect(isBreathing && isTrackingEnabledLocal ? 1.05 : 1.0)
                            .animation(
                                isTrackingEnabledLocal
                                    ? .easeInOut(duration: 1.5).repeatForever(autoreverses: true)
                                    : .default,
                                value: isBreathing
                            )

                        VStack(spacing: 4) {
                            Image(systemName: isTrackingEnabledLocal ? "heart.text.square.fill" : "heart.slash.fill")
                                .font(.system(size: 28))
                                .foregroundColor(engine.stressLevel == "Spike" ? .red : AppTheme.text.opacity(0.7))

                            Text(!isTrackingEnabledLocal ? "--" : (engine.currentHeartRate == 0 ? "..." : "\(engine.currentHeartRate)"))
                                .font(.system(size: 54, weight: .bold, design: .monospaced))
                                .foregroundColor(AppTheme.text)
                                .contentTransition(.numericText())

                            Text("BPM")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(AppTheme.text.opacity(0.5))
                        }
                    }
                    .frame(height: 210)
                    .onAppear {
                        isBreathing = true
                        // Resume monitoring if the user had it on from a previous session
                        if isTrackingEnabledLocal && HKHealthStore.isHealthDataAvailable() {
                            engine.isBiometricTrackingEnabled = true
                            engine.startHealthKitMonitoring()
                        }
                    }

                    // ── Apple Watch Sync Toggle ──────────────────────────────
                    VStack(spacing: 12) {
                        Toggle(isOn: $isTrackingEnabledLocal) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Sync Apple Watch")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppTheme.text)
                                Text("Adapt audio therapy to real-time stress responses")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.text.opacity(0.5))
                            }
                        }
                        .tint(.orange)
                        .onChange(of: isTrackingEnabledLocal) { _, newValue in
                            if newValue {
                                // Request HealthKit authorization, then start monitoring
                                engine.requestHealthKitPermission { success, error in
                                    DispatchQueue.main.async {
                                        if success {
                                            engine.startHealthKitMonitoring()
                                            engine.hapticNotification(.success)
                                        } else {
                                            // Roll back toggle if permission denied
                                            isTrackingEnabledLocal = false
                                            engine.stopHealthKitMonitoring()
                                            engine.hapticNotification(.error)
                                            if let error = error {
                                                alertErrorMessage = error.localizedDescription
                                                showingPermissionAlert = true
                                            } else {
                                                // Denied without error = user tapped "Don't Allow"
                                                alertErrorMessage = ""
                                                showingPermissionAlert = true
                                            }
                                        }
                                    }
                                }
                            } else {
                                engine.stopHealthKitMonitoring()
                                engine.hapticImpact(.light)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // ── Room Compensation Toggle ─────────────────────────────
                    VStack(spacing: 12) {
                        Toggle(isOn: Binding(
                            get: { engine.isRoomCompensationActive },
                            set: { engine.setRoomCompensationActive($0) }
                        )) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Reactive Room Compensation")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(AppTheme.text)
                                Text("Shapes audio to compensate for room acoustics and reflections")
                                    .font(.system(size: 13))
                                    .foregroundColor(AppTheme.text.opacity(0.5))
                            }
                        }
                        .tint(.blue)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    .background(AppTheme.cardBackground)
                    .cornerRadius(20)
                    .padding(.horizontal)

                    // ── Metrics Card ─────────────────────────────────────────
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

                        Divider().background(AppTheme.text.opacity(0.08))

                        MetricRow(
                            title: "Room Compensation",
                            value: engine.isRoomCompensationActive ? "Active" : "Off",
                            statusColor: engine.isRoomCompensationActive ? .blue : AppTheme.text.opacity(0.4),
                            icon: "speaker.wave.3.fill"
                        )
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(AppTheme.cardBackground)
                            .shadow(color: .black.opacity(0.03), radius: 8, y: 4)
                    )
                    .padding(.horizontal)

                    Spacer(minLength: 32)
                }
            }
        }
        .alert("Health Access Required", isPresented: $showingPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(
                alertErrorMessage.isEmpty
                    ? "Please enable Heart Rate access in Settings → Privacy & Security → Health → Silentium."
                    : alertErrorMessage
            )
        }
    }

    // MARK: - Helpers
    private func stressLevelColor(for level: String) -> Color {
        guard isTrackingEnabledLocal else { return .gray }
        switch level {
        case "Spike":    return .red
        case "Elevated": return .orange
        case "Stable":   return .green
        default:         return .gray
        }
    }

    private func adaptiveCompensationText(for level: String) -> String {
        guard isTrackingEnabledLocal else { return "Inactive" }
        switch level {
        case "Spike":    return "+15% Extra Masking"
        case "Elevated": return "+5% Masking"
        case "Stable":   return "Optimal Depth"
        default:         return "Calibrating..."
        }
    }
}
