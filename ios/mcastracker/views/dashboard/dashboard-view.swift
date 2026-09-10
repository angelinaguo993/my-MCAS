import SwiftUI

/// Core Flow 1: user opens the dashboard, sees days since their last
/// episode, and taps "Record Episode" to start the survey.
struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingEpisodeLog = false

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.stats == nil {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            daysSinceCard
                            totalLoggedCard
                            recordButton
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("MCAS Tracker")
            .task { await viewModel.loadDashboard() }
            .refreshable { await viewModel.loadDashboard() }
            .sheet(isPresented: $showingEpisodeLog, onDismiss: {
                Task { await viewModel.loadDashboard() }
            }) {
                EpisodeLogView()
            }
        }
    }

    private var daysSinceCard: some View {
        VStack(spacing: 8) {
            Text("Days Since Last Episode")
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.7))

            if let days = viewModel.stats?.daysSinceLastEpisode {
                Text("\(days)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primary)
            } else {
                Text("—")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(Theme.primary)
                Text("No episodes logged yet")
                    .font(.footnote)
                    .foregroundColor(Theme.textPrimary.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var totalLoggedCard: some View {
        HStack {
            Text("Total episodes logged")
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text("\(viewModel.stats?.totalEpisodesLogged ?? 0)")
                .font(.subheadline.bold())
                .foregroundColor(Theme.textPrimary)
        }
        .cardStyle()
    }

    private var recordButton: some View {
        Button {
            showingEpisodeLog = true
        } label: {
            Text("Record Episode")
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Theme.accent)
                .cornerRadius(Theme.cardCornerRadius)
        }
    }
}

#Preview {
    DashboardView()
}
