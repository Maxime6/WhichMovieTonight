//
//  TestsUI.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 18/04/2025.
//

import SwiftUI

struct TestsUI: View {
    var body: some View {
        ZStack {
            LinearGradient(gradient: Gradient(colors: [Color.blue.opacity(0.4), Color.purple.opacity(0.2), Color.cyan.opacity(0.4), Color.purple.opacity(0.2)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            .ignoresSafeArea()
                            .blur(radius: 10)
            
            VStack(spacing: 32) {
                Text("Tonight’s Movie")
                    .font(.title)
                    .foregroundColor(.primary)
                
                MovieCardTest(movie: .preview)
                
                WMTButton(title: "Watch Now") { }
            }
            .padding()
        }
    }
}

#Preview {
    TestsUI()
}

struct MovieCardTest: View {
    let movie: Movie
    let streamingPlatforms: [ImageResource] = [.netflixLogo, .primeVideoLogo, .disneyPlusLogo]

    var body: some View {
        VStack(spacing: 8) {
            
            Image(.inceptionCover)
                .resizable()
                .scaledToFit()
                .clipShape(RoundedRectangle(cornerRadius: 20))

            Text(movie.title)
                .font(.headline)
                .foregroundStyle(.primary)

            HStack {
                ForEach(movie.genres, id: \.self) { genre in
                    Text(genre)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(6)
                        .cornerRadius(10)
                        .background {
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .shadow(color: .secondary.opacity(0.1), radius: 2, x: 0, y: 4)
                        }
                }
            }
            
            HStack {
                ForEach(streamingPlatforms, id: \.self) { image in
                    Image(image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 40, height: 30)
                        .shadow(color: .secondary.opacity(0.1), radius: 2, x: 0, y: 4)
                }
            }
            .padding(.top, 10)
        }
        .padding()
        .background(.ultraThinMaterial.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: .secondary.opacity(0.2), radius: 15, x: 0, y: 10)
    }
}

struct WMTButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .overlay {
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(.white, lineWidth: 1)
                }
                .shadow(color: .secondary.opacity(0.2), radius: 15, x: 0, y: 10)
        }
        .background(
            ZStack {
                AnimatedMeshGradient()
                    .mask(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(lineWidth: 16)
                            .blur(radius: 8)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white, lineWidth: 3)
                            .blur(radius: 2)
                            .blendMode(.overlay)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(.white, lineWidth: 1)
                            .blur(radius: 1)
                            .blendMode(.overlay)
                    )
            }
        )
        .background(.ultraThinMaterial.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 25))
    }
}

struct GlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: 25)
                    .fill(Color.wmtGlassBackground)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(Color.white.opacity(0.1), lineWidth: 0.8)
            )
    }
}

extension Color {
    static let wmtBackground = Color("WMTBackground") // ex: #D8DEE9 ou light glass background
    static let wmtGradientStart = Color(red: 0.34, green: 0.89, blue: 0.98) // bleu
    static let wmtGradientEnd = Color(red: 0.64, green: 0.36, blue: 0.97) // violet

    static let wmtButton = LinearGradient(
        colors: [.wmtGradientStart, .wmtGradientEnd],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let wmtGlassBackground = Color.white.opacity(0.05)
    static let wmtTextPrimary = Color.white
    static let wmtTextSecondary = Color.white.opacity(0.7)
}

extension Font {
    static let wmtTitle = Font.system(size: 28, weight: .bold, design: .rounded)
    static let wmtSubtitle = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let wmtBody = Font.system(size: 16, weight: .regular, design: .rounded)
}
