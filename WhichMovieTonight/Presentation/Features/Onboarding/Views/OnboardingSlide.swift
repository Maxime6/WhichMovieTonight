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
    let isGenreSelection: Bool
    let isActorSelection: Bool
    let isStreamingPlatformSelection: Bool
    let isNotificationPermission: Bool

    init(image: String, title: String, description: String, isGenreSelection: Bool = false, isActorSelection: Bool = false, isStreamingPlatformSelection: Bool = false, isNotificationPermission: Bool = false) {
        self.image = image
        self.title = title
        self.description = description
        self.isGenreSelection = isGenreSelection
        self.isActorSelection = isActorSelection
        self.isStreamingPlatformSelection = isStreamingPlatformSelection
        self.isNotificationPermission = isNotificationPermission
    }
}

extension OnboardingSlide {
    static let slides: [OnboardingSlide] = [
        OnboardingSlide(image: "movieclapper", title: "Bienvenue sur WMT", description: "Trouvez le film parfait pour votre soirée grâce à l'IA"),
        OnboardingSlide(image: "wand.and.stars", title: "Recommandations Personnalisées", description: "Décrivez vos envies et recevez des suggestions sur mesure"),
        OnboardingSlide(image: "star.fill", title: "Gérez vos films", description: "Sauvegardez vos films préférés et gardez une trace de vos coups de cœur"),
        OnboardingSlide(image: "tv.fill", title: "Sélectionnez vos plateformes de streaming", description: "Choisissez les services auxquels vous avez accès pour des recommandations disponibles", isStreamingPlatformSelection: true),
        OnboardingSlide(image: "list.bullet", title: "Sélectionnez vos genres préférés", description: "Aidez-nous à vous proposer des films adaptés à vos goûts", isGenreSelection: true),
        OnboardingSlide(image: "person.2.fill", title: "Ajoutez vos acteurs préférés", description: "Dites-nous quels acteurs vous aimez pour des recommandations encore plus personnalisées", isActorSelection: true),
        OnboardingSlide(image: "bell.fill", title: "Restez connecté !", description: "🍿 Want to never miss amazing movie recommendations? We'll send you a few friendly reminders daily to keep your watchlist fresh! We promise not to be annoying - just helpful movie buddies! 🎬", isNotificationPermission: true),
    ]
}
