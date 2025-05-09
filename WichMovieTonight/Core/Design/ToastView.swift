//
//  MovieGenreSelectionView.swift
//  WichMovieTonight
//
//  Created by Maxime Tanter on 09/05/2025.
//

import SwiftUI

struct ToastView: View {
    let message: String
    var icon: String? = nil
    var duration: Double = 3.0
    var onDismiss: (() -> Void)? = nil

    @Binding var isShowing: Bool
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        if isShowing {
            HStack(spacing: 12) {
                if let icon {
                    Image(systemName: icon)
                        .foregroundColor(.accentColor)
                }
                Text(message)
                    .font(.callout.bold())
                    .foregroundColor(.primary)
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(.systemBackground).opacity(colorScheme == .dark ? 0.85 : 0.95))
                    .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
            )
            .padding(.bottom, 40)
            .transition(.move(edge: .bottom).combined(with: .opacity))
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                    withAnimation {
                        isShowing = false
                        onDismiss?()
                    }
                }
            }
            .onTapGesture {
                withAnimation {
                    isShowing = false
                    onDismiss?()
                }
            }
        }
    }
}

#Preview {
    VStack {
        Spacer()
        ToastView(message: "AI has find your movie", icon: "checkmark.seal.fill", isShowing: .constant(true))
    }
    .background(Color.gray.opacity(0.2))
}
