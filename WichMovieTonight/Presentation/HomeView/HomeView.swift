//
//  HomeView.swift
//  WichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    var body: some View {
        VStack {
            headerView
            
            Spacer()
            
            if let movie = viewModel.selectedMovie {
                MovieCardView(movie: movie)
            } else {
                emptyStateView
            }
            
            Spacer()
        }
        .padding()
//        .background(GlassBackgroundView())
        .onAppear {
            viewModel.fetchUser()
        }
    }
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Hi \(viewModel.userName),")
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                
                Text("What are you in the mood for tonight ?")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "person.crop.circle")
                .resizable()
                .frame(width: 40, height: 40)
                .foregroundStyle(.primary)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundStyle(.ultraThickMaterial)
            
            Text("No movie selected yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text("Tap below to let AI find the perfect movie for tonight !")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
            
            Button {
                Task {
                    try await viewModel.findTonightMovie()
                }
            } label: {
                Text("Find a Movie")
                    .fontWeight(.bold)
                    .padding()
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(GlassButtonStyle())
            .padding(.top, 12)
        }
        .padding()
//        .background(GlassCard())
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 10)
    }
}

#Preview {
    HomeView()
}

struct GlassCard: View {
    var cornerRadius: CGFloat = 24
    
    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(.ultraThinMaterial)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.1), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct GlassButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.primary)
            .padding()
            .frame(maxWidth: .infinity)
            .background(
                ZStack {
                    AnimatedMeshGradient()
                        .mask(
                            Capsule()
                                .stroke(lineWidth: 16)
                                .blur(radius: 8)
                        )
                        .overlay(
                            Capsule()
                                .stroke(.white, lineWidth: 3)
                                .blur(radius: 2)
                                .blendMode(.overlay)
                        )
                        .overlay(
                            Capsule()
                                .stroke(.white, lineWidth: 1)
                                .blur(radius: 1)
                                .blendMode(.overlay)
                        )
                }
            )
            .background(.ultraThinMaterial.opacity(0.7))
            .clipShape(.capsule)
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }
}

struct GlassBackgroundView: View {
    var body: some View {
        LinearGradient(colors: [Color.purple.opacity(0.15),
                                Color.blue.opacity(0.15),
                                Color.indigo.opacity(0.2)],
                       startPoint: .topLeading,
                       endPoint: .bottomTrailing)
            .ignoresSafeArea()
            .background(.ultraThinMaterial)
    }
}
