//
//  OnboardingSlideView.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 21/05/2025.
//

import SwiftUI

struct OnboardingSlideView: View {
    let slide: OnboardingSlide
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: slide.image)
                .resizable()
                .scaledToFit()
                .frame(width: 150, height: 150)
            
            Text(slide.title)
                .font(.title)
                .bold()
                .multilineTextAlignment(.center)
            
            Text(slide.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .padding()
    }
}

#Preview {
    OnboardingSlideView(slide: OnboardingSlide(image: "movieclapper", title: "Bienvenue sur WMT", description: "Trouvez le film parfait pour votre soirée grâce à l'IA"))
}
