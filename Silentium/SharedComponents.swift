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

struct MetricView: View {
    let icon: String
    let label: String
    let value: String
    let color: Color // If this causes an error, use 'Color' explicitly
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon).foregroundColor(color)
            Text(label).font(.caption).foregroundColor(AppTheme.text) // Changed to AppTheme.text
            Text(value).font(.headline).foregroundColor(AppTheme.text) // Added AppTheme.text
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppTheme.cardBackground)
        .cornerRadius(18)
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
                    .foregroundColor(.black) // Added foregroundColor(.black)
                Spacer()
                Text("\(Int(value)) \(unit)").font(.caption).monospacedDigit()
            }
            Slider(value: $value, in: range).accentColor(.orange)
        }
    }
}

