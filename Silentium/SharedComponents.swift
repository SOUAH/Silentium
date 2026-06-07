//
//  SharedComponents.swift
//  Silentium
//

import SwiftUI

// MARK: - iOS HIG Button Styles

/// The primary CTA button — matches the capsule shape of the WelcomeView
/// "Let's get started" button, filled with the dark pink → orange gradient.
/// Use for: "Finish Setup", "Save Calibration", "Continue to Pitch Matcher",
///          "I Understand & Accept", and any other full-width primary action.
struct GradientCapsuleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                Capsule()
                    .fill(AppTheme.accentGradient)
                    .shadow(color: Color.pink.opacity(configuration.isPressed ? 0.1 : 0.28),
                            radius: 12, x: 0, y: 6)
            )
            .opacity(configuration.isPressed ? 0.82 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

/// Subtle scale-down effect for card-style and icon buttons (sound cards, tiles).
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

// MARK: - Reusable UI Components

struct MetricRow: View {
    let title: String
    let value: String
    let statusColor: Color
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(AppTheme.text.opacity(0.6))
                .frame(width: 30)
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(AppTheme.text.opacity(0.8))
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(statusColor)
        }
    }
}

struct SliderRow: View {
    let icon: String
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Image(systemName: icon).foregroundStyle(AppTheme.accentGradient)
                Text(label)
                    .font(.subheadline.bold())
                    .foregroundColor(AppTheme.text)
                Spacer()
                Text("\(Int(value)) \(unit)")
                    .font(.caption)
                    .monospacedDigit()
                    .foregroundColor(AppTheme.text.opacity(0.6))
            }
            Slider(value: $value, in: range)
                .tint(Color.orange)
        }
    }
}
