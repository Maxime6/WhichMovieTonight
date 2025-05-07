//
//  HomeView.swift
//  WichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    
    @State private var actorsInput: String = ""
    @State private var genresSelected: [MovieGenre] = []
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color(.systemGray6).edgesIgnoringSafeArea(.all)
            
            VStack {
                headerView
                
                Spacer()
                
                if let movie = viewModel.selectedMovie {
                    MovieCardView(movie: movie)
                        .onAppear {
                            triggerHaptic()
                        }
                } else {
                    emptyStateView
                }
                
                Spacer()
            }
            .padding()
            .blur(radius: viewModel.isLoading ? 10 : 0)
            .onAppear {
                viewModel.fetchUser()
            }
            
            if viewModel.isLoading {
                ZStack {
                    AnimatedMeshGradient()
                        .mask(
                            RoundedRectangle(cornerRadius: 55)
                                .stroke(lineWidth: 25)
                                .blur(radius: 10)
                        )
                        .ignoresSafeArea()
                    
                    VStack {
                        Text("Looking for a particular theme ?")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                            .padding(.top, 40)
                        
                        MovieGenreSelectionView(tags: MovieGenre.allCases) { tag, isSelected in
                            MovieGenreCapsule(tag: tag.rawValue, isSelected: isSelected)
                        } didChangeSelection: { selection in
                            viewModel.selectedGenres = selection
                        }
                        .padding(.horizontal, 30)
                        .padding(.vertical, 20)
                        
                        Text("Or any actors ?")
                            .font(.title3.bold())
                            .foregroundStyle(.primary)
                            .padding(.top, 40)
                        
                        TextEditor(text: $actorsInput)
                            .frame(maxHeight: 100)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(.primary.opacity(0.1), lineWidth: 1)
                            )
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color(.systemBackground))
                                    .shadow(color: .black.opacity(0.05), radius: 15, x: 0, y: 5)
                            )
                            .padding(.horizontal, 30)

                        
                        Spacer()
                    }
                    
                    
                }
            }
            
            AIActionButton(buttonState: viewModel.state, isDisabled: false) {
                switch viewModel.state {
                case .idle:
                    viewModel.setResearchInfos()
                case .selectingGenres:
                    Task {
                        try await viewModel.findTonightMovie()
                    }
                default:
                    break
                }
                
            }
            
//            if viewModel.isLoading {
//                AIActionButton(title: "") {
//                    Task {
//                        try await viewModel.findTonightMovie()
//                    }
//                }
//            }
        }
        .animation(.easeInOut, value: viewModel.isLoading)
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
            Image(systemName: "movieclapper")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundStyle(.ultraThickMaterial)
            
            Text("No movie selected yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            
            Text("Tap below to let AI find the perfect movie for tonight !")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
        .padding()
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(radius: 10)
    }
    
    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

#Preview {
    HomeView()
}

struct WaveRenderer: TextRenderer {
    var strength: Double
    var frequency: Double
    var animatableData: Double {
        get { strength }
        set { strength = newValue }
    }
    
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            for run in line {
                for (index, glyph) in run.enumerated() {
                    let yOffset = strength * sin(Double(index) * frequency)
                    var copy = context
                    copy.translateBy(x: 0, y: yOffset)
                    copy.draw(glyph, options: .disablesSubpixelQuantization)
                }
            }
        }
    }
}
