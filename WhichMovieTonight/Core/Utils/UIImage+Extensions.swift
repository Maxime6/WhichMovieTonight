//
//  UIImage+Extensions.swift
//  WhichMovieTonight
//
//  Created by AI Assistant on 25/04/2025.
//

import UIKit

extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            // Calculate aspect ratio to maintain proportions
            let aspectRatio = self.size.width / self.size.height
            let targetAspectRatio = size.width / size.height

            var drawRect: CGRect

            if aspectRatio > targetAspectRatio {
                // Image is wider than target - fit to height
                let drawHeight = size.height
                let drawWidth = drawHeight * aspectRatio
                let drawX = (size.width - drawWidth) / 2
                drawRect = CGRect(x: drawX, y: 0, width: drawWidth, height: drawHeight)
            } else {
                // Image is taller than target - fit to width
                let drawWidth = size.width
                let drawHeight = drawWidth / aspectRatio
                let drawY = (size.height - drawHeight) / 2
                drawRect = CGRect(x: 0, y: drawY, width: drawWidth, height: drawHeight)
            }

            self.draw(in: drawRect)
        }
    }
}
