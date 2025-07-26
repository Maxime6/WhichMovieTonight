//
//  RatingStarsView.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 31/12/2024.
//

import SwiftUI

struct RatingStarsView: View {
    @Binding var rating: Int
    let maxRating: Int
    let starSize: CGFloat
    let spacing: CGFloat

    @State private var animatedRating: Double = 0

    init(rating: Binding<Int>, maxRating: Int = 5, starSize: CGFloat = 32, spacing: CGFloat = 8) {
        _rating = rating
        self.maxRating = maxRating
        self.starSize = starSize
        self.spacing = spacing
    }

    var body: some View {
        HStack(spacing: spacing) {
            ForEach(1 ... maxRating, id: \.self) { starIndex in
                StarView(
                    isFilled: starIndex <= rating,
                    isAnimated: starIndex == rating,
                    size: starSize
                )
                .onTapGesture {
                    withAnimation(DesignSystem.springAnimation) {
                        rating = starIndex
                    }
                }
            }
        }
        .onAppear {
            animatedRating = Double(rating)
        }
        .onChange(of: rating) { _, newRating in
            withAnimation(DesignSystem.springAnimation) {
                animatedRating = Double(newRating)
            }
        }
    }
}

struct StarView: View {
    let isFilled: Bool
    let isAnimated: Bool
    let size: CGFloat

    @State private var scale: CGFloat = 1.0
    @State private var rotation: Double = 0

    var body: some View {
        Image(systemName: isFilled ? "star.fill" : "star")
            .font(.system(size: size, weight: .medium))
            .foregroundStyle(
                isFilled ?
                    .cyan :
                    Color.gray.opacity(0.3)
            )
            .scaleEffect(scale)
            .rotationEffect(.degrees(rotation))
            .onChange(of: isFilled) { _, newValue in
                if newValue && isAnimated {
                    animateStar()
                }
            }
    }

    private func animateStar() {
        withAnimation(DesignSystem.springAnimation) {
            scale = 1.3
            rotation = 15
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(DesignSystem.springAnimation) {
                scale = 1.0
                rotation = 0
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        RatingStarsView(rating: .constant(3))
        RatingStarsView(rating: .constant(5), starSize: 40)
        RatingStarsView(rating: .constant(0), starSize: 24)
    }
    .padding()
}
