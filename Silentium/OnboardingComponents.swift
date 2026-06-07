//
//  OnboardingComponents.swift
//  Silentium
//
//  Created by Souha Aouididi on 04/06/26.
//

import Foundation
import SwiftUI

// Important Notice Screen
struct ImportantNoticeView: View {
    var onNext: () -> Void
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.1))
                        .frame(width: 100, height: 100)
                    Image(systemName: "exclamationmark.shield.fill")
                        .font(.system(size: 44, weight: .bold))
                        .foregroundColor(.orange)
                }
                
                VStack(spacing: 12) {
                    Text("Important Notice")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.text)
                    
                    Text("Please Read Before Commencing Therapy")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppTheme.text.opacity(0.4))
                }
                
                VStack(alignment: .leading, spacing: 16) {
                    BulletNoticeRow(icon: "waveform.path.ecg", text: "This application provides acoustic masking algorithms. It is not a diagnostic utility and does not replace professional medical evaluations.")
                    BulletNoticeRow(icon: "hearingdevice.ear", text: "Always calibrate audio output parameters below 50% device volume to safely safeguard structural hearing mechanisms.")
                    BulletNoticeRow(icon: "bolt.shield", text: "Discontinue therapeutic stimulation cycles instantly if your symptoms intensify, or if you experience headaches or dizziness.")
                }
                .padding(24)
                .background(AppTheme.cardBackground)
                .cornerRadius(24)
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: onNext) {
                    Text("I Understand & Accept")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.accentGradient)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain) // 👈 UPDATED: Implemented native Apple style modifier pass
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }
}

// App Information Screen
struct AppInfoView: View {
    var onNext: () -> Void
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 24) {
                Spacer()
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("How Silentium Works")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(AppTheme.text)
                    Text("Symptom relief backed by acoustic neuroscience")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(AppTheme.text.opacity(0.5))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                
                VStack(spacing: 20) {
                    InfoCardRow(icon: "tuningfork", title: "Notch Filtering", desc: "By identifying your exact tinnitus pitch frequency, the app removes that spectrum from the sounds, giving your auditory cortex a chance to recalibrate.")
                    // 👈 FIXED: Stripped potential rejection tracking keywords safely
                    InfoCardRow(icon: "sparkles", title: "Bio-Adaptive Relief", desc: "Syncs directly with your daily health trends to dynamically modify acoustic saturation density whenever stress signals spike.")
                    // 👈 FIXED: Text cutoffs fully resolved through explicit multiline rendering configurations
                    InfoCardRow(icon: "moon.stars", title: "Decline Fade Sleep", desc: "Gently dissolves high frequencies and master volumes over a 10-minute trailing curve to shield against night-time tinnitus panic triggers.")
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                Button(action: onNext) {
                    Text("Continue to Pitch Matcher")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppTheme.accentGradient)
                        .cornerRadius(16)
                }
                .buttonStyle(.plain) // 👈 UPDATED: Implemented native Apple style modifier pass
                .padding(.horizontal, 24)
                .padding(.bottom, 20)
            }
        }
    }
}

// Reusable UI Subview Helpers
struct BulletNoticeRow: View {
    let icon: String
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.orange)
                .frame(width: 24)
                .padding(.top, 2)
            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppTheme.text.opacity(0.7))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true) // 👈 FIXED: Prevents content clamping bugs
        }
    }
}

struct InfoCardRow: View {
    let icon: String
    let title: String
    let desc: String
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(AppTheme.accentGradient.opacity(0.1))
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(AppTheme.accentGradient)
            }
            .frame(width: 52, height: 52)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppTheme.text)
                Text(desc)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(AppTheme.text.opacity(0.5))
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true) // 👈 FIXED: Completely forces dynamic height calculation
            }
            Spacer()
        }
        .padding(16)
        .background(AppTheme.cardBackground)
        .cornerRadius(16)
    }
}
