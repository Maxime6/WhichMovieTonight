import SwiftUI

/// Typography system for Findy app
enum FindyTypography {
    // MARK: - Font Styles

    static let largeTitle = Font.system(size: 34, weight: .bold, design: .rounded)
    static let title = Font.system(size: 28, weight: .bold, design: .rounded)
    static let headline = Font.system(size: 20, weight: .semibold, design: .rounded)
    static let body = Font.system(size: 17, weight: .regular, design: .rounded)
    static let caption = Font.system(size: 15, weight: .medium, design: .rounded)

    // MARK: - Line Heights

    static let largeTitleLineHeight: CGFloat = 41
    static let titleLineHeight: CGFloat = 34
    static let headlineLineHeight: CGFloat = 25
    static let bodyLineHeight: CGFloat = 22
    static let captionLineHeight: CGFloat = 20

    // MARK: - Letter Spacing

    static let titleLetterSpacing: CGFloat = 0.35
    static let bodyLetterSpacing: CGFloat = 0.25
}
