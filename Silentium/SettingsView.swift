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
    
    @State private var showingBioRelief = false
    @State private var showingToneFinder = false
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfUse = false
    @State private var expandedFAQ: UUID? = nil
    
    let buttonSizes = ["Standard", "Large", "Extra Large"]
    
    struct FAQItem: Identifiable {
        let id = UUID()
        let question: String
        let answer: String
    }
    
    let faqRegistry = [
        FAQItem(question: "How does Notched Therapy work?", answer: "Silentium identifies your exact tinnitus pitch and digitally cuts that frequency out of your masking soundscapes. This starves hyperactive neurons in your auditory cortex, training your brain to ignore the sound over time."),
        FAQItem(question: "Is this app a registered medical device?", answer: "No. Silentium is an acoustic wellness and sound therapy helper utility. It does not replace clinical audiology treatments or prescription hearing instruments. Consult an ENT for specialized evaluation."),
        FAQItem(question: "How often should I use the therapy soundscapes?", answer: "For optimal neural habituation, we recommend using the custom notched soundscapes for 1 to 2 hours daily during quiet work, reading, or sleep preparation intervals.")
    ]
    
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // 1. Title Header Row with Modern Native Xmark Dismiss Button
                HStack(alignment: .center) {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.text)
                    
                    Spacer()
                    
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppTheme.text.opacity(0.7))
                            .padding(12)
                            .background(Circle().fill(AppTheme.text.opacity(0.05)))
                    }
                    .buttonStyle(PlainButtonStyle())
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 12)
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 22) {
                        
                        // 2. Tuning Controls Panel (Launches sub-views perfectly)
                        SettingsSectionCard(title: "Tuning Controls") {
                            VStack(spacing: 0) {
                                NavigationLinkRow(title: "Bio-Adaptive Relief Monitoring", systemIcon: "heart.text.square.fill") {
                                    showingBioRelief = true
                                }
                            }
                        }
                        
                        // 3. Accessibility Controls Card Group
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
                        
                        // 5. Frequently Asked Questions Section
                        SettingsSectionCard(title: "FAQs") {
                            VStack(spacing: 0) {
                                ForEach(faqRegistry) { faq in
                                    FAQRowStyle(
                                        faq: faq,
                                        isExpanded: expandedFAQ == faq.id,
                                        action: {
                                            withAnimation(.spring(response: 0.25, dampingFraction: 0.8)) {
                                                expandedFAQ = (expandedFAQ == faq.id) ? nil : faq.id
                                            }
                                        }
                                    )
                                    if faq.id != faqRegistry.last?.id {
                                        Divider().background(AppTheme.text.opacity(0.06)).padding(.leading, 44)
                                    }
                                }
                            }
                        }
                        
                        // 6. Privacy & Terms Documents Panel
                        SettingsSectionCard(title: "Legal") {
                            VStack(spacing: 0) {
                                NavigationLinkRow(title: "Privacy Policy", systemIcon: "hand.raised.fill") {
                                    showingPrivacyPolicy = true
                                }
                                
                                Divider().background(AppTheme.text.opacity(0.06)).padding(.leading, 44)
                                
                                NavigationLinkRow(title: "Terms of Use", systemIcon: "doc.plaintext.fill") {
                                    showingTermsOfUse = true
                                }
                            }
                        }
                        
                        // 7. Medical Legal Disclaimer Sheet Layout Box
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
                    .padding(.vertical, 8)
                }
            }
        }
        .fullScreenCover(isPresented: $showingToneFinder) {
            ToneFinderView(engine: engine, isFirstTime: false)
        }
        .sheet(isPresented: $showingBioRelief) {
            BioReliefView() // 👈 FIXED: Dropped manual init parameters
                .environmentObject(engine) //  FIXED: Injected active instance via environment tree modifier
        }
        .sheet(isPresented: $showingPrivacyPolicy) { SafariFallbackTemplateView(title: "Privacy Policy") }
        .sheet(isPresented: $showingTermsOfUse) { SafariFallbackTemplateView(title: "Terms of Use") }
    }
}

// Reusable Setting UI Cards

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

struct ToggleRowStyle: View {
    let title: String
    let description: String
    let systemIcon: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.text.opacity(0.04))
                Image(systemName: systemIcon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppTheme.text.opacity(0.7))
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
            }
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: AppTheme.text))
                .labelsHidden()
        }
        .frame(minHeight: 48)
    }
}

struct FAQRowStyle: View {
    let faq: SettingsView.FAQItem
    let isExpanded: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 14) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(AppTheme.text.opacity(0.04))
                        Image(systemName: "questionmark.circle.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(AppTheme.accentGradient)
                    }
                    .frame(width: 32, height: 32)
                    
                    Text(faq.question)
                        .font(.body)
                        .fontWeight(.semibold)
                        .foregroundColor(AppTheme.text)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(AppTheme.text.opacity(0.2))
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                
                if isExpanded {
                    Text(faq.answer)
                        .font(.footnote)
                        .foregroundColor(AppTheme.text.opacity(0.6))
                        .lineSpacing(4)
                        .padding(.leading, 46)
                        .padding(.bottom, 4)
                        .transition(.opacity)
                }
            }
            .frame(minHeight: 48)
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
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
                        .fill(AppTheme.text.opacity(0.04))
                    Image(systemName: systemIcon)
                        .font(.system(size: 15))
                        .foregroundColor(AppTheme.text.opacity(0.7))
                }
                .frame(width: 32, height: 32)
                
                Text(title)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.text)
                
                Spacer()
                
                Image(systemName: "arrow.up.forward")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppTheme.text.opacity(0.2))
            }
            .frame(minHeight: 48)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct SafariFallbackTemplateView: View {
    let title: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                Text("Localized document asset container for \(title).")
                    .font(.callout)
                    .foregroundColor(AppTheme.text.opacity(0.5))
                    .padding(32)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(AppTheme.text))
        }
    }
}
