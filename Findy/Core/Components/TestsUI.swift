//
//  TestsUI.swift
//  Findy
//
//  Created by Maxime Tanter on 18/04/2025.
//

import SwiftUI

struct TestsUI: View {
    var body: some View {
        VStack(spacing: 32) {
                    Text("Tonight’s Movie")
                        .font(.wmtTitle)
                        .foregroundColor(.wmtTextPrimary)

                    MovieCardTest(movie: .preview)

                    WMTButton(title: "Watch Now") { }
                }
                .padding()
                .background(Color.wmtBackground.ignoresSafeArea())
    }
}

#Preview {
    TestsUI()
}

struct MovieCardTest: View {
    let movie: Movie

    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: movie.posterURL) { image in
                image
                    .resizable()
                    .scaledToFill()
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            } placeholder: {
                Color.gray.opacity(0.2)
                    .frame(height: 240)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
            }

            Text(movie.title)
                .font(.headline)
                .foregroundColor(.wmtTextPrimary)

            HStack {
                ForEach(movie.genres, id: \.self) { genre in
                    Text(genre.id)
                        .font(.caption)
                        .padding(6)
                        .background(Color.white.opacity(0.08))
                        .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 25))
        .shadow(color: .black.opacity(0.2), radius: 15, x: 0, y: 10)
    }
}

struct WMTButton: View {
    var title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .fontWeight(.semibold)
                .foregroundColor(.wmtTextPrimary)
                .padding(.vertical, 14)
                .frame(maxWidth: .infinity)
                .background(.ultraThinMaterial)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.wmtGlassBackground)
                        .blur(radius: 0.5)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.wmtGradientStart.opacity(0.4), lineWidth: 1)
                )
        }
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
