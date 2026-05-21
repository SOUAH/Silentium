//
//  JourneyView.swift
//  Tinnitus
//
//  Created by Sara Riccone on 07/05/26.
//

import SwiftUI

struct JourneyView: View {
    var body: some View {
        ZStack {
            AppTheme.background.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 25) {
                HeaderComponent(
                    title: "Your Journey",
                    subtitle: "Consistent habituation over time."
                ).foregroundColor(.black)
                
                // Chart Box Visual
                VStack(alignment: .leading, spacing: 12) {
                    Text("Tinnitus Severity Trend")
                        .font(.headline)
                        .foregroundColor(AppTheme.text)
                        .padding(.leading, 4)
                    
                    ZStack {
                        RoundedRectangle(cornerRadius: 20)
                            .fill(AppTheme.cardBackground)
                        
                        Image(systemName: "chart.xyaxis.line")
                            .resizable()
                            .padding(40)
                            .foregroundStyle(AppTheme.accentGradient)
                            .opacity(0.15)
                    }
                    .frame(height: 200)
                }
                
                // Milestone Info Bar
                HStack(spacing: 15) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Total Masking Time")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("152 minutes")
                            .font(.title2.bold())
                            .foregroundColor(AppTheme.text)
                    }
                    Spacer()
                    Image(systemName: "calendar.badge.clock")
                        .font(.largeTitle)
                        .foregroundStyle(AppTheme.accentGradient)
                }
                .padding()
                .background(AppTheme.cardBackground)
                .cornerRadius(15)
                
                Spacer()
            }
            .padding()
        }
    }
}
