//
//  MovieGenreCapsule.swift
//  WichMovieTonight
//
//  Created by Maxime Tanter on 06/05/2025.
//

import SwiftUI

struct MovieGenreCapsule: View {
    var tag: String
    var isSelected: Bool
    
    var body: some View {
        HStack(spacing: 8) {
            Text(tag)
                .font(.callout)
                .foregroundStyle(isSelected ? .white : .primary)
            
            if isSelected {
                Image(systemName: "checkmark.circle")
                    .foregroundStyle(.white)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
            ZStack {
                Capsule()
                    .fill(.background)
                    .opacity(!isSelected ? 1 : 0)
                
                Capsule()
                    .fill(.cyan.gradient)
                    .opacity(isSelected ? 1 : 0)
            }
        }
    }
    
}
