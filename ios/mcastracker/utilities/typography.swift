import SwiftUI
import CoreText

/// to change font family: update these FOUR STRINGS, add those family's .ttf files to ios/resources
enum AppFont {
    static let regular = "Nunito-Regular"
    static let semiBold = "Nunito-SemiBold"
    static let bold = "Nunito-Bold"
    static let extraBold = "Nunito-ExtraBold"
}

extension Font {
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

enum FontRegistrar {
    static func registerBundledFonts() {
        guard let root = Bundle.main.resourceURL,
              let enumerator = FileManager.default.enumerator(at: root, includingPropertiesForKeys: nil)
        else { return }

        let fontURLs = enumerator.allObjects
            .compactMap { $0 as? URL }
            .filter { ["ttf", "otf"].contains($0.pathExtension.lowercased()) }

        print("Font files in bundle:", fontURLs.map { $0.lastPathComponent })
        if fontURLs.isEmpty {
            print("⚠️ No .ttf/.otf files in the app bundle. Check Build Phases → Copy Bundle Resources.")
        }

        for url in fontURLs {
            var error: Unmanaged<CFError>?
            // "already registered" error- means Info.plist worked first, can just ignore :)
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }

        for family in UIFont.familyNames.sorted() where family.localizedCaseInsensitiveContains("nunito") {
            print("FAMILY:", family, UIFont.fontNames(forFamilyName: family))
        }
    }
}
