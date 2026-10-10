import SwiftUI

/// To try another family (e.g. Roboto Slab),
/// change these four strings and add that family's .ttf files.
enum AppFont {
    static let regular = "Nunito-Regular"
    static let semiBold = "Nunito-SemiBold"
    static let bold = "Nunito-Bold"
    static let extraBold = "Nunito-ExtraBold"
}

extension Font {
    /// `relativeTo` keeps Dynamic Type (the user's text-size setting) working.
    static func app(_ name: String, size: CGFloat, relativeTo style: Font.TextStyle = .body) -> Font {
        .custom(name, size: size, relativeTo: style)
    }

    static let nLargeTitle = Font.app(AppFont.extraBold, size: 34, relativeTo: .largeTitle)
    static let nTitle2 = Font.app(AppFont.bold, size: 22, relativeTo: .title2)
    static let nHeadline = Font.app(AppFont.bold, size: 17, relativeTo: .headline)
    static let nSubheadline = Font.app(AppFont.regular, size: 15, relativeTo: .subheadline)
    static let nSubheadlineBold = Font.app(AppFont.bold, size: 15, relativeTo: .subheadline)
    static let nFootnote = Font.app(AppFont.regular, size: 13, relativeTo: .footnote)
    static let nCaption = Font.app(AppFont.regular, size: 12, relativeTo: .caption)
    static let nCaptionBold = Font.app(AppFont.bold, size: 12, relativeTo: .caption)
}
