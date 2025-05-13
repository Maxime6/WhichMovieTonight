//
//  FlowLayout.swift
//  WhichMovieTonight
//
//  Created by Maxime Tanter on 25/04/2025.
//

import SwiftUI

struct FlowLayout<Content: View>: View {
    let spacing: CGFloat
    let alignment: HorizontalAlignment
    let content: () -> Content

    @State private var totalHeight: CGFloat = .zero

    init(spacing: CGFloat = 8, alignment: HorizontalAlignment = .leading, @ViewBuilder content: @escaping () -> Content) {
        self.spacing = spacing
        self.alignment = alignment
        self.content = content
    }

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            GeometryReader { geometry in
                self.generateWrappedContent(in: geometry)
            }
        }
        .frame(height: totalHeight)
    }

    private func generateWrappedContent(in geometry: GeometryProxy) -> some View {
        var width = CGFloat.zero
        var height = CGFloat.zero

        return ZStack(alignment: Alignment(horizontal: alignment, vertical: .top)) {
            content()
                .background(
                    GeometryReader { itemGeo in
                        Color.clear.onAppear {
                            let itemSize = itemGeo.size

                            if width + itemSize.width > geometry.size.width {
                                width = 0
                                height += itemSize.height + spacing
                            }

                            DispatchQueue.main.async {
                                totalHeight = height + itemSize.height
                            }
                            width += itemSize.width + spacing
                        }
                    }
                )
                .alignmentGuide(.leading) { _ in width }
                .alignmentGuide(.top) { _ in height }
        }
    }
}

//#Preview {
//    FlowLayout()
//}
