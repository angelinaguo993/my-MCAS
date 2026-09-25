import SwiftUI

/// Home tab: user opens the dashboard, sees days since their last
/// episode, and taps "Record Episode" to start the survey. Also shows
/// which medications the user uses (trigger/symptom pattern cards live
/// on the Analytics tab instead — see analytics-view.swift).
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
                            if let error = viewModel.errorMessage {
                                errorBanner(error)
                            }
                            daysSinceCard
                            totalLoggedCard
                            if let insights = viewModel.insights, insights.hasEnoughData {
                                medicationsUsedCard(insights.medicationEffectiveness)
                            }
                            recordButton
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Home")
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

    private func errorBanner(_ message: String) -> some View {
        VStack(spacing: 8) {
            Text("Couldn't load your data")
                .font(.subheadline.bold())
                .foregroundColor(Theme.accent)
            Text("The server may be waking up after being idle — this can take up to a minute on the free tier.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textPrimary.opacity(0.7))
            Button("Try Again") {
                Task { await viewModel.loadDashboard() }
            }
            .font(.caption.bold())
            .foregroundColor(Theme.primary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private func medicationsUsedCard(_ medications: [FrequencyStat]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Medications You Use")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if medications.isEmpty {
                Text("No medications logged yet").font(.caption).foregroundColor(.gray)
            } else {
                ForEach(medications) { stat in
                    HStack {
                        Image(systemName: "pills.fill")
                            .foregroundColor(Theme.primary)
                            .frame(width: 24)
                        Text(stat.name)
                            .font(.subheadline)
                            .foregroundColor(Theme.textPrimary)
                        Spacer()
                        Text("\(Int(stat.proportion * 100))% helped")
                            .font(.caption)
                            .foregroundColor(Theme.success)
                    }
                }
            }
        }
        .cardStyle()
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}
