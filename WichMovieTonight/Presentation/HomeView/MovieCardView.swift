//
//  MovieCardView.swift
//  WichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct MovieCardView: View {
    let movie: Movie
    
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
                .frame(height: 300)
                .cornerRadius(16)
                .shadow(radius: 10)
            
            Text(movie.title)
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
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
            .buttonStyle(GlassButtonStyle())
        }
        .padding()
//        .background(GlassCard())
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
        WrapHStack(spacing: 8, alignment: .leading) {
            ForEach(movie.genres, id: \.self) { genre in
                Text(genre.id)
                    .font(.caption)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .overlay {
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.white.opacity(0.1))
                    }
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

//struct FlowLayout<Content: View>: View {
//    let spacing: CGFloat
//    let alignment: HorizontalAlignment
//    let content: () -> Content
//    
//    @State private var totalHeight: CGFloat = .zero
//    
//    init(
//        spacing: CGFloat = 8,
//        alignment: HorizontalAlignment = .leading,
//        @ViewBuilder content: @escaping () -> Content
//    ) {
//        self.spacing = spacing
//        self.alignment = alignment
//        self.content = content
//    }
//    
//    var body: some View {
//        GeometryReader { geometry in
//            self.generatedContent(in: geometry)
//        }
//        .frame(height: totalHeight)
//    }
//    
//    private func generatedContent(in geometry: GeometryProxy) -> some View {
//        var width = CGFloat.zero
//        var height: CGFloat = .zero
//        
//        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
//            content()
//                .padding(.trailing, spacing)
//                .background(
//                    GeometryReader { itemGeo in
//                        Color.clear.onAppear {
//                            if width + itemGeo.size.width > geometry.size.width {
//                                width = 0
//                                height += itemGeo.size.height + spacing
//                            }
//                            width += itemGeo.size.width + spacing
//                            DispatchQueue.main.async {
//                                totalHeight = height + itemGeo.size.height
//                            }
//                        }
//                    }
//                )
//                .alignmentGuide(.leading) { d in
//                    let result = width
//                    if abs(width - d.width) > geometry.size.width {
//                        width = 0
//                        height += d.height + spacing
//                        return 0
//                    }
//                    width += d.width + spacing
//                    return result
//                }
//                .alignmentGuide(.top) { _ in
//                    let result = height
//                    return result
//                }
//        }
//    }
//}
