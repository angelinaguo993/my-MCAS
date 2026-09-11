import SwiftUI

/// Shown while waiting on a network call (dashboard fetch, episode submit,
/// calendar fetch). One component so every screen's loading state looks
/// and behaves the same.
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .tint(Theme.primary)
            Text("Loading...")
                .font(.footnote)
                .foregroundColor(Theme.textPrimary.opacity(0.6))
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoadingView_Previews: PreviewProvider {
    static var previews: some View {
        LoadingView()
    }
}
