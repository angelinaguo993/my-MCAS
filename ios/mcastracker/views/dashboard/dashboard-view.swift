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
                            if let error = viewModel.errorMessage {
                                errorBanner(error)
                            }
                            daysSinceCard
                            totalLoggedCard
                            if let insights = viewModel.insights {
                                insightsSection(insights)
                            }
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

    @ViewBuilder
    private func insightsSection(_ insights: InsightsResponse) -> some View {
        if !insights.hasEnoughData {
            notEnoughDataCard(insights)
        } else {
            topTriggersCard(insights.topTriggers)
            topSymptomsCard(insights.topSymptomCategories)
            medicationsUsedCard(insights.medicationEffectiveness)
        }
    }

    private func notEnoughDataCard(_ insights: InsightsResponse) -> some View {
        VStack(spacing: 6) {
            Text("Not enough data yet")
                .font(.subheadline.bold())
                .foregroundColor(Theme.textPrimary)
            Text("Log \(insights.episodesNeeded) more episode\(insights.episodesNeeded == 1 ? "" : "s") to start seeing your patterns.")
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(Theme.textPrimary.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private func topTriggersCard(_ triggers: [FrequencyStat]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Most Common Triggers")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if triggers.isEmpty {
                Text("No triggers logged yet").font(.caption).foregroundColor(.gray)
            } else {
                ForEach(triggers) { stat in
                    insightRow(
                        icon: Trigger.from(rawValue: stat.name)?.iconName ?? "questionmark.circle.fill",
                        label: Trigger.from(rawValue: stat.name)?.displayName ?? stat.name,
                        proportion: stat.proportion
                    )
                }
            }
        }
        .cardStyle()
    }

    private func topSymptomsCard(_ symptoms: [FrequencyStat]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your Most Common Symptoms")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)

            if symptoms.isEmpty {
                Text("No symptoms logged yet").font(.caption).foregroundColor(.gray)
            } else {
                ForEach(symptoms) { stat in
                    insightRow(
                        icon: SymptomCategory(rawValue: stat.name)?.iconName ?? "questionmark.circle.fill",
                        label: SymptomCategory(rawValue: stat.name)?.displayName ?? stat.name,
                        proportion: stat.proportion
                    )
                }
            }
        }
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

    /// One row: icon, name, and how often it shows up (as a rounded percentage).
    /// The confidence interval (stat.lower/upper) is computed but not shown here
    /// to keep the dashboard simple — worth surfacing later in a detail view.
    private func insightRow(icon: String, label: String, proportion: Double) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(Theme.primary)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
                .foregroundColor(Theme.textPrimary)
            Spacer()
            Text("\(Int(proportion * 100))%")
                .font(.caption.bold())
                .foregroundColor(Theme.accent)
        }
    }
}

struct DashboardView_Previews: PreviewProvider {
    static var previews: some View {
        DashboardView()
    }
}