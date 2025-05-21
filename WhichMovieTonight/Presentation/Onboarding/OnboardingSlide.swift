//
//  OnboardingSlide.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 21/05/2025.
//

import Foundation

struct OnboardingSlide: Identifiable {
    let id = UUID()
    let image: String
    let title: String
    let description: String
}

extension OnboardingSlide {
    static let slides: [OnboardingSlide] = [
        OnboardingSlide(image: "movieclapper", title: "Bienvenue sur WMT", description: "Trouvez le film parfait pour votre soirée grâce à l'IA"),
        OnboardingSlide(image: "wand.and.stars", title: "Recommandations Personnalisées", description: "Décrivez vos envies et recevez des suggestions sur mesure"),
        OnboardingSlide(image: "star.fill", title: "Gérez vos films", description: "Sauvegardez vos films préférés et gardez une trace de vos coups de cœur")
    ]
}
