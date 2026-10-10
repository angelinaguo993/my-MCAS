import SwiftUI

/// Three blurred color blobs (your green, blue, and pink) that slowly drift.
/// The blobs are anchored from the TOP-LEFT and overflow upward, so the top
/// edge is always fully covered. The bottom fades into the page background.
struct GradientHeroBackground: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var drift = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            ZStack(alignment: .topLeading) {
                Circle().fill(Theme.success)
                    .frame(width: w * 0.95)
                    .offset(x: drift ? -w * 0.50 : -w * 0.40,
                            y: drift ? -w * 0.30 : -w * 0.40)
                Circle().fill(Theme.primary)
                    .frame(width: w * 0.90)
                    .offset(x: drift ? w * 0.08 : w * 0.20,
                            y: drift ? -w * 0.35 : -w * 0.20)
                Circle().fill(Theme.accent)
                    .frame(width: w * 0.85)
                    .offset(x: drift ? w * 0.60 : w * 0.48,
                            y: drift ? -w * 0.25 : -w * 0.10)
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            .blur(radius: 55)
            .clipped()
        }
        .background(Theme.background)
        .mask(
            LinearGradient(
                stops: [
                    .init(color: .black, location: 0),
                    .init(color: .black, location: 0.65),
                    .init(color: .clear, location: 1)
                ],
                startPoint: .top, endPoint: .bottom
            )
        )
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeInOut(duration: 7).repeatForever(autoreverses: true)) {
                drift.toggle()
            }
        }
    }
}

/// Just the greeting text and gear button. The gradient is drawn behind the
/// scroll view (see dashboard-view.swift), not inside this header.
struct HomeHeroHeader: View {
    let name: String?
    let onSettingsTap: () -> Void

    private var dateText: String {
        Date().formatted(.dateTime.weekday(.wide).month(.abbreviated).day())
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Spacer()
                Button(action: onSettingsTap) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(Theme.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(.ultraThinMaterial, in: Circle())
                }
            }

            Spacer(minLength: 50)

            Text(dateText)
                .font(.nCaptionBold)
                .tracking(1.5)
                .textCase(.uppercase)
                .foregroundColor(Theme.textPrimary.opacity(0.65))
            Text("Welcome,")
                .font(.app(AppFont.semiBold, size: 26, relativeTo: .title2))
                .foregroundColor(Theme.textPrimary.opacity(0.8))
            Text(name?.isEmpty == false ? name! : "back")
                .font(.app(AppFont.extraBold, size: 54, relativeTo: .largeTitle))
                .foregroundColor(Theme.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity, minHeight: 300, alignment: .topLeading)
    }
}
