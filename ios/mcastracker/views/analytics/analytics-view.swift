import SwiftUI

/// Analytics tab: "most common triggers," "most common symptoms," and
/// AI-driven pattern-detection insights. Medication
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
                                    if !insights.triggerCooccurrence.isEmpty {
                                        triggerCooccurrenceCard(insights.triggerCooccurrence)
                                    }
                                    
                                    // MARK: - AI Insights Section
                                    aiInsightsSection
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
            
            // This line is the crucial change to reveal the true error
            Text(message) 
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

    private func triggerCooccurrenceCard(_ pairs: [FrequencyStat]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trigger Combinations")
                .font(.headline)
                .foregroundColor(Theme.textPrimary)
            Text("How often pairs of triggers show up together in the same episode")
                .font(.caption)
                .foregroundColor(Theme.textPrimary.opacity(0.6))

            ForEach(pairs) { stat in
                HStack {
                    Image(systemName: "link")
                        .foregroundColor(Theme.primary)
                        .frame(width: 24)
                    Text(stat.name.split(separator: "+").map {
                        Trigger.from(rawValue: $0.trimmingCharacters(in: .whitespaces))?.displayName
                        ?? $0.trimmingCharacters(in: .whitespaces)
                    }.joined(separator: " + "))
                        .font(.subheadline)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("\(Int(stat.proportion * 100))%")
                        .font(.caption.bold())
                        .foregroundColor(Theme.accent)
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
    
    // MARK: - AI View Components
    
    @ViewBuilder
    private var aiInsightsSection: some View {
        if viewModel.isAILoading {
            VStack {
                ProgressView()
                    .padding(.bottom, 8)
                Text("AI is analyzing your notes and triggers...")
                    .font(.caption)
                    .foregroundColor(Theme.textPrimary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .cardStyle()
        } else if let aiResult = viewModel.aiResult {
            VStack(spacing: 16) {
                Text("AI Insights")
                    .font(.title2.bold())
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                aiInsightCard(
                    title: "Triggers to Avoid", 
                    subtitle: "Based on your logged episodes and notes, these triggers appear to be associated with more severe or frequent episodes.",
                    items: aiResult.triggersToAvoid, 
                    icon: "exclamationmark.triangle"
                )
                aiInsightCard(
                    title: "Medication Insights", 
                    subtitle: "Based on your logged episodes and notes, these medications appear to be more effective for you personally.*",
                    items: aiResult.medicationInsights, 
                    icon: "pills"
                )
                aiInsightCard(
                    title: "Notes Analysis", 
                    subtitle: "Basd on your logged notes, these are patterns or observations that the AI has detected in your entries.",
                    items: aiResult.notesAnalysis, 
                    icon: "doc.text.magnifyingglass"
                )
            }
        } else {
            Button(action: {
                Task { await viewModel.generateAIInsights() }
            }) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate AI Insights")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Theme.accent)
                .cornerRadius(10)
            }
            .padding(.top, 8)
        }
    }
    
    private func aiInsightCard(title: String, subtitle: String? = nil, items: [String], icon: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(Theme.accent)
                Text(title)
                    .font(.headline)
                    .foregroundColor(Theme.textPrimary)
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Theme.textPrimary.opacity(0.6))
            }
            
            if items.isEmpty {
                Text("No specific patterns detected yet.")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            } else {
                ForEach(items.indices, id: \.self) { index in
                    Text("• \(items[index])")
                    .font(.subheadline)
                    .foregroundColor(Theme.textPrimary.opacity(0.8))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct AnalyticsView_Previews: PreviewProvider {
    static var previews: some View {
        AnalyticsView()
    }
}