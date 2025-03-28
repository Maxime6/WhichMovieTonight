//
//  ContentView.swift
//  Findy
//
//  Created by Maxime Tanter on 28/03/2025.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        ZStack {
            // Background
            FindyColors.backgroundPrimary
                .ignoresSafeArea()

            // Content
            ScrollView {
                VStack(spacing: FindyLayout.largeSpacing) {
                    // Title
                    Text("Findy")
                        .font(FindyTypography.largeTitle)
                        .foregroundColor(FindyColors.textPrimary)
                        .neonGlow()

                    // Card Example
                    FindyCard {
                        VStack(alignment: .leading, spacing: FindyLayout.spacing) {
                            Text("Movie Recommendation")
                                .font(FindyTypography.headline)
                                .foregroundColor(FindyColors.textPrimary)

                            Text("Based on your preferences, we think you'll love this movie!")
                                .font(FindyTypography.body)
                                .foregroundColor(FindyColors.textSecondary)
                        }
                    }

                    // Buttons Example
                    VStack(spacing: FindyLayout.spacing) {
                        FindyButton("Primary Action") {
                            print("Primary tapped")
                        }

                        FindyButton("Secondary Action", style: .secondary) {
                            print("Secondary tapped")
                        }

                        FindyButton("Ghost Action", style: .ghost) {
                            print("Ghost tapped")
                        }
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    ContentView()
}
