import SwiftUI

/// Analytics tab: "most common triggers," "most common symptoms," and
/// (in the future) other pattern-detection insights. Medication
/// effectiveness stays on the Home tab for now, per the current layout.
struct AnalyticsView: View {
    @StateObject private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.insights == nil {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            if let error = viewModel.errorMessage {
                                errorBanner(error)
                            }

                            if let insights = viewModel.insights {
                                if !insights.hasEnoughData {
                                    notEnoughDataCard(insights)
                                } else {
                                    topTriggersCard(insights.topTriggers)
                                    topSymptomsCard(insights.topSymptomCategories)
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Analytics")
            .task { await viewModel.loadInsights() }
            .refreshable { await viewModel.loadInsights() }
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
                Task { await viewModel.loadInsights() }
            }
            .font(.caption.bold())
            .foregroundColor(Theme.primary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
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

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
}
