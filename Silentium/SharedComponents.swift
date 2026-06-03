//
//  SharedComponents.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI

struct HeaderComponent: View {
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.largeTitle.bold())
            Text(subtitle).font(.subheadline).foregroundColor(.black)
        }.frame(maxWidth: .infinity, alignment: .leading)
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

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
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
                Image(systemName: icon).foregroundColor(.orange)
                Text(label)
                    .font(.subheadline)
                    .bold()
                    .foregroundColor(.black)
                Spacer()
                Text("\(Int(value)) \(unit)").font(.caption).monospacedDigit()
            }
            Slider(value: $value, in: range).accentColor(.orange)
        }
    }
}

