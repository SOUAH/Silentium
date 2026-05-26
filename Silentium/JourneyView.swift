//
//  SettingsView.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 26/05/26.
//

import SwiftUI

struct SettingsView: View {
    // Persistent state hooks saving user selection selections app-wide
    @AppStorage("isHighContrastEnabled") private var isHighContrastEnabled = false
    @AppStorage("isHapticFeedbackEnabled") private var isHapticFeedbackEnabled = true
    @AppStorage("selectedButtonSize") private var selectedButtonSize = "Standard"
    
    // Core navigation presentation alerts
    @State private var showingPrivacyPolicy = false
    @State private var showingTermsOfUse = false
    @State private var expandedFAQ: UUID? = nil
    
    let buttonSizes = ["Standard", "Large", "Extra Large"]
    
    // Structured FAQ dataset entity rows
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
                // 1. HIG Large Title Header
                HStack {
                    Text("Settings")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.text)
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 12)
                
                ScrollView(.vertical, showsIndicators: true) {
                    VStack(spacing: 22) {
                        
                        // 2. Accessibility Group Plate
                        SettingsSectionCard(title: "Accessibility") {
                            VStack(spacing: 0) {
                                ToggleRowStyle(
                                    title: "High Contrast",
                                    description: "Increase contrast weights for text elements.",
                                    systemIcon: "eye.inverse",
                                    isOn: $isHighContrastEnabled
                                )
                                
                                Divider().background(AppTheme.text.opacity(0.06)).padding(.leading, 44)
                                
                                ToggleRowStyle(
                                    title: "Haptic Feedback",
                                    description: "Enhanced physical feedback on interactions.",
                                    systemIcon: "waveform.feedback",
                                    isOn: $isHapticFeedbackEnabled
                                )
                            }
                        }
                        
                        // 3. Button Size Segment Picker
                        SettingsSectionCard(title: "Button Size") {
                            VStack(alignment: .leading, spacing: 14) {
                                Text("Adjust interactive element scaling targets system-wide.")
                                    .font(.footnote)
                                    .foregroundColor(AppTheme.text.opacity(0.5))
                                
                                HStack(spacing: 8) {
                                    ForEach(buttonSizes, id: \.self) { size in
                                        Button(action: {
                                            if isHapticFeedbackEnabled { UIImpactFeedbackGenerator(style: .light).impactOccurred() }
                                            selectedButtonSize = size
                                        }) {
                                            Text(size)
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(selectedButtonSize == size ? AppTheme.background : AppTheme.text)
                                                .frame(maxWidth: .infinity)
                                                .frame(height: 40) // Target metric check
                                                .background(selectedButtonSize == size ? AppTheme.text : AppTheme.background.opacity(0.6))
                                                .cornerRadius(10)
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        
                        // 4. Frequently Asked Questions (FAQ Accordion Matrix)
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
                        
                        // 5. Legal Group Links Panel
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
                        
                        // 6. Mandatory Medical Disclaimer Box Block
                        VStack(alignment: .center, spacing: 8) {
                            HStack(spacing: 6) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.footnote)
                                    .foregroundColor(.amberCustom)
                                
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
                            
                
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        // Native Link Web/Sheet Presentation fallbacks
        .sheet(isPresented: $showingPrivacyPolicy) { SafariFallbackTemplateView(title: "Privacy Policy") }
        .sheet(isPresented: $showingTermsOfUse) { SafariFallbackTemplateView(title: "Terms of Use") }
    }
}

// Reusable Setting Element Wrappers

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

// Custom configuration extensions to match systemic UI components cleanly
extension Toggle {
    func switchToggleStyle(onColor: Color) -> some View {
        self.toggleStyle(SwitchToggleStyle(tint: onColor))
    }
}

extension Color {
    static let amberCustom = Color(red: 0.96, green: 0.65, blue: 0.14) // #F3A60E
}

//Dummy Component Presenters
struct SafariFallbackTemplateView: View {
    let title: String
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.background.ignoresSafeArea()
                Text("App Bundle Web Asset Container for \(title).\n\nReplace this modal container call with an active Link out or a localized text stack block safely.")
                    .font(.callout)
                    .foregroundColor(AppTheme.text.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(32)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(trailing: Button("Done") { presentationMode.wrappedValue.dismiss() }.foregroundColor(AppTheme.text))
        }
    }
}
