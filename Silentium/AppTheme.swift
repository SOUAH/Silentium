//
//  Colors.swift
//  Tinnitus
//
//  Created by Souha Aouididi on 07/05/26.
//

import SwiftUI
import UIKit

struct AppTheme {
    static var background: Color {
        Color(UIColor { traitCollection in
            // Automatically samples system appearance environment changes
            if traitCollection.userInterfaceStyle == .dark {
                // Returns clean OLED Midnight Navy when system Dark Mode is ON
                return UIColor(red: 0.05, green: 0.06, blue: 0.08, alpha: 1.0)
            } else {
                return UIColor(red: 245/255, green: 242/255, blue: 239/255, alpha: 1.0)
            }
        })
    }
    
    static var text: Color {
        Color(UIColor { traitCollection in
            return traitCollection.userInterfaceStyle == .dark ? .white : .black
        })
    }
    
    static var cardBackground: Color {
        Color(UIColor { traitCollection in
            if traitCollection.userInterfaceStyle == .dark {
                return UIColor(red: 0.11, green: 0.13, blue: 0.16, alpha: 1.0) // Frosted Dark card
            } else {
                return .white // Premium light surface card
            }
        })
    }
    
    static let accentGradient = LinearGradient(
        colors: [Color.pink, Color.orange],
        startPoint: .leading, endPoint: .trailing
    )
    
    static let amberCustom = Color.orange
}
