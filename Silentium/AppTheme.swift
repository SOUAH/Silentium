//
//  Colors.swift
//  Tinnitus
//
//  Created by Sara Riccone on 07/05/26.
//

import SwiftUI

struct AppTheme {
    static let background = Color(hex: "F5F2EF")
    static let text = Color.black
    static let accentGradient = LinearGradient(
        colors: [Color(red: 0.8, green: 0.1, blue: 0.4), .orange],
        startPoint: .leading,
        endPoint: .trailing
    )
    // Make sure this is exactly 'cardBackground' with a lowercase 'c'
    static let cardBackground = Color.white.opacity(0.8)
    static let amberCustom = Color(hex: "FFC107") // Added amberCustom color
}

extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
