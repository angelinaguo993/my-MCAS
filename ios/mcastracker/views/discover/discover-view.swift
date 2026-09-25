import SwiftUI

/// Discover tab: will eventually hold MCAS facts and related articles.
/// Placeholder for now — no content yet.
struct DiscoverView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()
                Text("Coming soon")
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary.opacity(0.5))
            }
            .navigationTitle("Discover")
        }
    }
}

struct DiscoverView_Previews: PreviewProvider {
    static var previews: some View {
        DiscoverView()
    }
}
