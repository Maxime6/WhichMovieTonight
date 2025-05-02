//
//  MovieCardView.swift
//  WichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct MovieCardView: View {
    @Environment(\.colorScheme) var colorScheme
    
    let movie: Movie
    
    @State var counter: Int = 0
    @State var origin: CGPoint = .zero
    
    var body: some View {
        VStack(spacing: 16) {
            // TODO: Connect with api datas
//            AsyncImage(url: movie.posterURL) { phase in
//                switch phase {
//                case .empty:
//                    ProgressView()
//                case .success(let image):
//                    image
//                        .resizable()
//                        .scaledToFit()
//                        .frame(height: 300)
//                        .cornerRadius(16)
//                        .shadow(radius: 10)
//                case .failure(_):
//                    placeHolderPoster
//                @unknown default:
//                    placeHolderPoster
//                }
//            }
            
            Image(.inceptionCover)
                .resizable()
                .scaledToFit()
                .frame(height: 350)
                .cornerRadius(16)
                .shadow(color: .primary.opacity(0.2), radius: 10)
                .onPressingChanged { point in
//                    if !isDisabled {
                        if let point {
                            origin = point
                            counter += 1
                        }
//                    }
                }
                .modifier(RippleEffect(at: origin, trigger: counter))
            
            Text(movie.title)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemBackground))
                        .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
                )
                .overlay {
                    AnimatedMeshGradient()
                        .blendMode(colorScheme == .dark ? .colorBurn : .screen)
                }
            
            genreTags
            
            HStack {
                ForEach(movie.streamingPlatforms, id: \.self) { platform in
                    StreamingPlatformLogoView(platform: platform)
                }
            }
            
            Button {
                // open streaming app
            } label: {
                Text("Watch now")
                    .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .cornerRadius(24)
        .padding(.horizontal)
    }
    
    private var placeHolderPoster: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(.gray.opacity(0.2))
            .frame(height: 300)
            .overlay {
                Image(systemName: "film")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 50, height: 50)
                    .foregroundStyle(.secondary)
            }
    }
    
    private var genreTags: some View {
        HStack(spacing: 8) {
            ForEach(movie.genres, id: \.self) { genre in
                Text(genre.id)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .overlay {
                        Capsule()
                            .stroke(.primary.opacity(0.1))
                    }
                
                    .shadow(color: .cyan.opacity(0.3), radius: 2, x: 2, y: 2)
            }
        }
    }
}

#Preview {
    MovieCardView(movie: MockMovie.sample)
}

struct StreamingPlatformLogoView: View {
    let platform: StreamingPlatform

    var body: some View {
        Image(platform.icon)
            .resizable()
            .scaledToFit()
            .frame(width: 32, height: 32)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
    }
}

struct WrapHStack<Content: View>: View {
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: () -> Content

    init(spacing: CGFloat = 8, alignment: HorizontalAlignment = .leading, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        /// Flow layout from SwiftUI-Introspect or custom
        /// Using a LazyVgrid for now
        FlowLayout(spacing: spacing, alignment: alignment, content: content)
    }
}
