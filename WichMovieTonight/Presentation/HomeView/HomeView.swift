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
                    VStack {
                        Text("Let me find your movie for you...")
                            .font(.title.bold())
                            .foregroundStyle(.primary)
                            .padding(.top, 40)
                        
                        Spacer()
                    }
                }
                
                AnimatedMeshGradient()
                    .mask(
                        RoundedRectangle(cornerRadius: 44)
                            .stroke(lineWidth: 44)
                            .blur(radius: 22)
                    )
                    .ignoresSafeArea()
            }
            
            AIActionButton(isLoading: viewModel.isLoading, isDisabled: false) {
                Task {
                    try await viewModel.findTonightMovie()
                }
            }
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
