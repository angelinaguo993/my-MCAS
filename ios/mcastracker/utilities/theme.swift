import SwiftUI

/// Central place for the app's design system so colors/fonts are never
/// hardcoded inline in views — change a color once here, it updates everywhere.
enum Theme {
    static let primary = Color(hex: "5BC0EB")
    static let background = Color(hex: "FDECEF")
    static let accent = Color(hex: "E43F6F")
    static let success = Color(hex: "B4D89C")
    static let textPrimary = Color(hex: "333333")

    static let cardCornerRadius: CGFloat = 16
    static let cardPadding: CGFloat = 16
}

extension Color {
    /// Lets us write Color(hex: "5BC0EB") instead of manually converting RGB.
    init(hex: String) {
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)

        let r = Double((rgb & 0xFF0000) >> 16) / 255
        let g = Double((rgb & 0x00FF00) >> 8) / 255
        let b = Double(rgb & 0x0000FF) / 255

        self.init(red: r, green: g, blue: b)
    }
}

/// Reusable card container so every screen's "cards" look consistent.
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(Theme.cardPadding)
            .background(Color.white)
            .cornerRadius(Theme.cardCornerRadius)
            .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardBackground())
    }
}
