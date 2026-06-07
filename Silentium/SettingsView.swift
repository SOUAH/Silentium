//
//  SettingsView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var engine: TinnitusAppEngine
    
    @AppStorage("isHighContrastEnabled") private var isHighContrastEnabled = false
    @AppStorage("isHapticFeedbackEnabled") private var isHapticFeedbackEnabled = true
    @AppStorage("selectedButtonSize") private var selectedButtonSize = "Standard"
    
    // Core Engine State Binding for Room Compensation Feature
    @AppStorage("isReactiveRoomCompensationEnabled") private var isReactiveRoomCompensationEnabled = false
    
    @State private var showingBioRelief = false
    @State private var showingFAQSheet = false // Expanded Sheet trigger
    
    struct FAQItem: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }
    
    // Expanded, complete clinical and technical registry for the specialized FAQ sheet container
    let expandedFAQRegistry = [
        FAQItem(question: "How does Notched Therapy work?", answer: "Silentium identifies your exact tinnitus pitch and digitally cuts that frequency out of your masking soundscapes. This starves hyperactive neurons in your auditory cortex, training your brain to ignore the sound over time."),
        FAQItem(question: "What is Reactive Room Compensation?", answer: "This mode samples subtle environmental acoustics via your device's microphone to analyze atmospheric changes. It realigns your sound filters on the fly, keeping target treatment masking clear regardless of whether you're in a echoing hallway or a noisy office."),
        FAQItem(question: "Is this app a registered medical device?", answer: "No. Silentium is an acoustic wellness and sound therapy helper utility. It does not replace clinical audiology treatments or prescription hearing instruments. Consult an ENT for specialized evaluation."),
        FAQItem(question: "How often should I use the therapy soundscapes?", answer: "For optimal neural habituation, we recommend using the custom notched soundscapes for 1 to 2 hours daily during quiet work, reading, or sleep preparation intervals."),
        FAQItem(question: "Can I listen through standard Bluetooth headphones?", answer: "Yes. High-quality wireless or wired headphones with flat frequency response properties are excellent for delivering the notched equalization sound curves directly to your ears."),
        FAQItem(question: "Does the app collect my background microphone audio?", answer: "No. Your privacy is paramount. When Reactive Room Compensation is active, environmental acoustic arrays are processed instantly in short intervals completely on-device. No audio data is ever written to disc or transmitted over the web.")
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 22) {
                        
                        // MARK: - 1. Tuning Controls Panel
                        SettingsSectionCard(title: "Tuning Controls") {
                            VStack(spacing: 0) {
                                NavigationLinkRow(title: "Bio-Adaptive Relief Monitoring", systemIcon: "heart.text.square.fill") {
                                    showingBioRelief = true
                                }
                                
                                Divider().background(AppTheme.text.opacity(0.06)).padding(.leading, 44)
                                
                                ToggleRowStyle(
                                    title: "Reactive Room Compensation",
                                    description: "Optimizes filter curves dynamically based on microphone acoustic profiles.",
                                    systemIcon: "vial.viewfinder",
                                    isOn: $isReactiveRoomCompensationEnabled
                                )
                                .onChange(of: isReactiveRoomCompensationEnabled) { stateFlag in
                                    if isHapticFeedbackEnabled {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                    
                                    let coreEngineReference = self.engine
                                    let dynamicToggleValue = stateFlag
                                    coreEngineReference.setRoomCompensationActive(dynamicToggleValue)
                                }
                            }
                        }
                        
                        // 2. Accessibility Controls
                        SettingsSectionCard(title: "Accessibility") {
                            VStack(spacing: 0) {
                                ToggleRowStyle(
                                    title: "Haptic Feedback",
                                    description: "Enhanced physical feedback on interactions.",
                                    systemIcon: "waveform",
                                    isOn: $isHapticFeedbackEnabled
                                )
                            }
                        }
                        
                        // 3. Consolidated Support & FAQs
                        SettingsSectionCard(title: "Support") {
                            VStack(spacing: 0) {
                                NavigationLinkRow(title: "Frequently Asked Questions", systemIcon: "questionmark.circle.fill") {
                                    showingFAQSheet = true
                                }
                            }
                        }
                        
                        // 4. Contact Support Center
                        SettingsSectionCard(title: "Contact") {
                            VStack(spacing: 0) {
                                Link(destination: URL(string: "mailto:souha.aouidid1@gmail.com")!) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(AppTheme.accentGradient)
                                            Image(systemName: "envelope.fill")
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(.white)
                                        }
                                        .frame(width: 32, height: 32)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("Email Support")
                                                .font(.body)
                                                .fontWeight(.semibold)
                                                .foregroundColor(AppTheme.text)
                                            Text("souha.aouidid1@gmail.com")
                                                .font(.caption)
                                                .foregroundColor(AppTheme.text.opacity(0.4))
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "arrow.up.forward")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(AppTheme.text.opacity(0.2))
                                    }
                                    .frame(minHeight: 48)
                                }
                            }
                        }
                        
                        // 5. Privacy & Terms Documents Panel
                        SettingsSectionCard(title: "Legal") {
                            VStack(spacing: 0) {
                                Link(destination: URL(string: "https://go.fliplink.me/view/FC10FD60-0222-421F-AED2-BE565465F3B9")!) {
                                    ExternalLinkRowStyle(title: "Privacy Policy", systemIcon: "hand.raised.fill")
                                }
                                
                                Divider().background(AppTheme.text.opacity(0.06)).padding(.leading, 44)
                                
                                Link(destination: URL(string: "https://go.fliplink.me/view/0C128AFB-AC9D-4541-A6A9-780BE1F6D54D")!) {
                                    ExternalLinkRowStyle(title: "Terms of Use", systemIcon: "doc.plaintext.fill")
                                }
                            }
                        }
                        
                        //6. Medical Legal Disclaimer Sheet Layout Box
                        VStack(alignment: .center, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.footnote)
                                    .foregroundColor(AppTheme.amberCustom)
                                Text("Medical Disclaimer")
                                    .font(.footnote)
                                    .fontWeight(.bold)
                                    .foregroundColor(AppTheme.text.opacity(0.6))
                            }
                            
                            Text("Silentium is a sound wellness helper tool. It is not a registered medical diagnosis platform or therapeutic medical device. Always consult an ENT doctor or audiologist specialist for ongoing custom clinical tinnitus care paths.")
                                .font(.caption)
                                .foregroundColor(AppTheme.text.opacity(0.4))
                                .multilineTextAlignment(.center)
                                .lineSpacing(3)
                                .padding(.horizontal, 10)
                            
                            Text("Silentium v1.0 (Build 2)")
                                .font(.system(size: 11))
                                .fontWeight(.medium)
                                .foregroundColor(AppTheme.text.opacity(0.3))
                                .padding(.top, 14)
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    .padding(.vertical, 16)
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(AppTheme.text.opacity(0.6))
                            .frame(width: 32, height: 32)
                            .background(Circle().fill(AppTheme.text.opacity(0.05)))
                    }
                }.sharedBackgroundVisibility(.hidden)
            }
            .sheet(isPresented: $showingBioRelief) {
                BioReliefView().environmentObject(engine)
            }
            // Dedicated FAQs Comprehensive List Detail Modal View Sheet Overlay
            .sheet(isPresented: $showingFAQSheet) {
                FAQModalSheetContainerView(items: expandedFAQRegistry)
            }
        }
    }
}

struct SettingsSectionCard<Content: View>: View {
    let title: String
    let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.footnote)
                .fontWeight(.bold)
                .foregroundColor(AppTheme.text.opacity(0.4))
                .textCase(.uppercase)
                .padding(.horizontal, 34)
            
            VStack(content: content)
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(AppTheme.cardBackground)
                .cornerRadius(16)
                .padding(.horizontal, 20)
        }
    }
}

struct FAQModalSheetContainerView: View {
    let items: [SettingsView.FAQItem]
    @Environment(\.dismiss) private var dismiss
    @State private var openItemIndex: UUID? = nil
    
    var body: some View {
        NavigationStack {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(items) { item in
                            Button(action: {
                                withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                    openItemIndex = (openItemIndex == item.id) ? nil : item.id
                                }
                            }) {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack(spacing: 14) {
                                        ZStack {
                                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                                .fill(AppTheme.accentGradient)
                                            Image(systemName: "questionmark.circle.fill")
                                                .font(.system(size: 15))
                                                .foregroundColor(.white)
                                        }
                                        .frame(width: 32, height: 32)
                                        
                                        Text(item.question)
                                            .font(.system(size: 16, weight: .semibold))
                                            .foregroundColor(AppTheme.text)
                                            .multilineTextAlignment(.leading)
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(AppTheme.text.opacity(0.2))
                                            .rotationEffect(.degrees(openItemIndex == item.id ? 90 : 0))
                                    }
                                    
                                    if openItemIndex == item.id {
                                        Text(item.answer)
                                            .font(.system(size: 14))
                                            .foregroundColor(AppTheme.text.opacity(0.6))
                                            .lineSpacing(4)
                                            .padding(.leading, 46)
                                            .padding(.bottom, 6)
                                            .transition(.opacity)
                                    }
                                }
                                .padding(14)
                                .background(AppTheme.cardBackground)
                                .cornerRadius(14)
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Help & FAQs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.text)
                }
            }
        }
    }
}


struct ToggleRowStyle: View {
    let title: String
    let description: String
    let systemIcon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.accentGradient)
                Image(systemName: systemIcon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
            }
            .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.text)
                Text(description)
                    .font(.caption)
                    .foregroundColor(AppTheme.text.opacity(0.4))
                    .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: Color.orange))
                .labelsHidden()
        }
        .frame(minHeight: 54)
        .padding(.vertical, 4)
    }
}

struct NavigationLinkRow: View {
    let title: String
    let systemIcon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(AppTheme.accentGradient)
                    Image(systemName: systemIcon)
                        .font(.system(size: 15))
                        .foregroundColor(.white)
                }
                .frame(width: 32, height: 32)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.text)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(AppTheme.text.opacity(0.2))
            }
            .frame(minHeight: 48)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ExternalLinkRowStyle: View {
    let title: String
    let systemIcon: String
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.accentGradient)
                Image(systemName: systemIcon)
                    .font(.system(size: 14))
                    .foregroundColor(.white)
            }
            .frame(width: 32, height: 32)
            
            Text(title)
                .font(.body)
                .fontWeight(.semibold)
                .foregroundColor(AppTheme.text)
            
            Spacer()
            
            Image(systemName: "arrow.up.forward")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppTheme.text.opacity(0.2))
        }
        .frame(minHeight: 48)
    }
}
