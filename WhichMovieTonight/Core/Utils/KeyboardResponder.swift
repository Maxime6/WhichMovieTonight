//
//  KeyboardResponder.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 22/07/2025.
//

import Combine
import SwiftUI
import UIKit

final class KeyboardResponder: ObservableObject {
    @Published var currentHeight: CGFloat = 0

    private var cancellables: Set<AnyCancellable> = []

    var keyboardWillShowNotification = NotificationCenter.default.publisher(
        for: UIResponder.keyboardWillShowNotification
    )
    var keyboardWillHideNotification = NotificationCenter.default.publisher(
        for: UIResponder.keyboardWillHideNotification
    )

    init() {
        keyboardWillShowNotification.map { notification in
            CGFloat((notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect)?.height ?? 0)
        }
        .assign(to: \.currentHeight, on: self)
        .store(in: &cancellables)

        keyboardWillHideNotification.map { _ in
            CGFloat(0)
        }
        .assign(to: \.currentHeight, on: self)
        .store(in: &cancellables)
    }
}

struct KeyboardAdaptive: ViewModifier {
    @ObservedObject private var keyboard = KeyboardResponder()

    func body(content: Content) -> some View {
        content
            .padding(.bottom, keyboard.currentHeight)
            .animation(.easeInOut(duration: 0.16), value: keyboard.currentHeight)
    }
}
