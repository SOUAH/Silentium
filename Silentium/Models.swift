//
//  Models.swift
//  Silentium
//
//  Created by Souha Aouididi on 03/06/26.
//

import Foundation

struct MaskingSound: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let description: String
    let category: String // "White", "Pink", "Brown"
    let systemIcon: String
}
