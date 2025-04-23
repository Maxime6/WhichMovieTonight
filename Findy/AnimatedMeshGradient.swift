//
//  AnimatedMeshGradient.swift
//  Notes
//
//  Created by Maxime Tanter on 18/02/2025.
//

import SwiftUI

struct AnimatedMeshGradient: View {
    @State var appear: Bool = false
    @State var appear2: Bool = false
    
    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0.0, 0.0], [appear2 ? 0.5 : 1.0, 0.0], [1.0, 0.0],
                [0.0, 0.5], appear ? [0.1, 0.5] : [0.8, 0.2], [1.0, -0.5],
                [0.0, 1.0], [1.0, appear2 ? 2.0 : 1.0], [1.0, 1.0]
            ], colors: [
                appear2 ? .red : .mint, appear2 ? .yellow : .cyan, .orange,
                appear ? .blue : .red, appear ? .cyan : .white, appear ? .red : .purple,
                appear ? .red : .cyan, appear ? .mint : .blue, appear2 ? .red : .blue
            ]
        )
        .onAppear {
            withAnimation(.easeOut(duration: 1).repeatForever(autoreverses: true)) {
                appear.toggle()
            }
            withAnimation(.easeOut(duration: 2).repeatForever(autoreverses: true)) {
                appear2.toggle()
            }
        }
    }
}

#Preview {
    AnimatedMeshGradient()
        .ignoresSafeArea()
}
