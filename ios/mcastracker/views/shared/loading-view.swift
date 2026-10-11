import SwiftUI

/// loading view when waiting on network call
struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
                .tint(Theme.primary)
            Text("Loading...")
                .font(.nFootnote)
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
