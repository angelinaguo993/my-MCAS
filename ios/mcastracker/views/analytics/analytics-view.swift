import SwiftUI

private enum AnalyticsPattern: String, CaseIterable, Identifiable {
    case triggers = "Triggers"
    case symptoms = "Symptoms"
    var id: String { rawValue }
}

/// analytics tab: "most common triggers," "most common symptoms," and AI-driven pattern-detection insights
struct AnalyticsView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var viewModel = AnalyticsViewModel()
    @State private var showingExport = false
    @State private var selectedPattern: AnalyticsPattern = .triggers

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.background.ignoresSafeArea()

                if viewModel.isLoading && viewModel.insights == nil {
                    LoadingView()
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 20) {
                            pageIntroduction
                            if let error = viewModel.errorMessage {
                                errorBanner(error)
                            }

                            if let insights = viewModel.insights {
                                if !insights.hasEnoughData {
                                    notEnoughDataCard(insights)
                                } else {
                                    patternOverviewCard(insights)
                                    if !insights.triggerCooccurrence.isEmpty {
                                        triggerCooccurrenceCard(insights.triggerCooccurrence)
                                    }
                                    if !insights.symptomTriggerPairs.isEmpty {
                                        symptomTriggerPairsCard(insights.symptomTriggerPairs)
                                    }
                                    if !insights.severityByTrigger.isEmpty {
                                        severityByTriggerCard(insights.severityByTrigger)
                                    }
                                    
                                    // MARK: - AI Insights Section
                                    aiInsightsSection
                                }
                            }
                            doctorSummaryCard
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Analytics")
            .task { await viewModel.loadInsights() }
            .refreshable { 
                await viewModel.loadInsights() 
            }
            .sheet(isPresented: $showingExport) {
                ExportReportView()
            }
        }
    }

    private var pageIntroduction: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Your patterns")
                .font(.nTitle2)
                .foregroundColor(Theme.textPrimary)
            Text("Explore what appears in the episodes you’ve logged.")
                .font(.nSubheadline)
                .foregroundColor(Theme.textPrimary.opacity(0.75))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 4)
    }

    private func patternOverviewCard(_ insights: InsightsResponse) -> some View {
        let stats = selectedPattern == .triggers ? insights.topTriggers : insights.topSymptomCategories

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                Text("Pattern Frequency")
                    .font(.nHeadline)
                    .foregroundColor(Theme.textPrimary)
                Spacer()
                Image(systemName: "note.text")
                    .font(.title3)
                    .foregroundColor(Theme.accent)
            }

            Text("Frequency across your logged episodes")
                .font(.nCaption)
                .foregroundColor(Theme.textPrimary.opacity(0.7))

            Picker("Pattern type", selection: $selectedPattern) {
                ForEach(AnalyticsPattern.allCases) { pattern in
                    Text(pattern.rawValue).tag(pattern)
                }
            }
            .pickerStyle(.segmented)

            if stats.isEmpty {
                Text(selectedPattern == .triggers ? "No triggers logged in these episodes yet." : "No symptoms logged in these episodes yet.")
                    .font(.nSubheadline)
                    .foregroundColor(Theme.textPrimary.opacity(0.7))
            } else {
                ForEach(stats.prefix(5)) { stat in
                    patternRow(stat, kind: selectedPattern)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
        .animation(reduceMotion ? nil : .easeInOut(duration: 0.18), value: selectedPattern)
    }

    private func patternRow(_ stat: FrequencyStat, kind: AnalyticsPattern) -> some View {
        DisclosureGroup {
            VStack(alignment: .leading, spacing: 4) {
                let occurrenceCount = Int((stat.proportion * Double(stat.sampleSize)).rounded())
                Text("Reported in \(occurrenceCount) of \(stat.sampleSize) episodes.")
                    .font(.nCaption)
                    .foregroundColor(Theme.textPrimary.opacity(0.8))
                Text("Estimated frequency range: \(Int((stat.lower * 100).rounded()))–\(Int((stat.upper * 100).rounded()))%.")
                    .font(.nCaption)
                    .foregroundColor(Theme.textPrimary.opacity(0.7))
            }
            .padding(.top, 6)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 10) {
                    Image(systemName: kind == .triggers
                          ? (Trigger.from(rawValue: stat.name)?.iconName ?? "sparkles")
                          : (SymptomCategory(rawValue: stat.name)?.iconName ?? "waveform.path.ecg"))
                        .foregroundColor(Theme.primary)
                        .frame(width: 24)
                    Text(kind == .triggers
                         ? (Trigger.from(rawValue: stat.name)?.displayName ?? stat.name)
                         : (SymptomCategory(rawValue: stat.name)?.displayName ?? stat.name))
                        .font(.nSubheadlineBold)
                        .foregroundColor(Theme.textPrimary)
                    Spacer(minLength: 8)
                    Text("\(Int((stat.proportion * 100).rounded()))%")
                        .font(.nCaptionBold)
                        .foregroundColor(Theme.accent)
                }
                ProgressView(value: min(max(stat.proportion, 0), 1))
                    .tint(Theme.accent)
                    .accessibilityLabel("Frequency")
                    .accessibilityValue("\(Int((stat.proportion * 100).rounded())) percent")
            }
        }
        .tint(Theme.primary)
    }

    private func errorBanner(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "arrow.clockwise.circle.fill")
                .font(.title3)
                .foregroundColor(Theme.accent)
            VStack(alignment: .leading, spacing: 4) {
                Text("Couldn't load your data")
                    .font(.nSubheadlineBold)
                    .foregroundColor(Theme.textPrimary)
                Text(message)
                    .font(.nCaption)
                    .foregroundColor(Theme.textPrimary.opacity(0.7))
            }
            Spacer(minLength: 4)
            Button("Retry") {
                Task { await viewModel.loadInsights() }
            }
            .font(.nCaptionBold)
            .foregroundColor(Theme.primary)
            .frame(minHeight: 44)
        }
        .cardStyle()
    }

    private func notEnoughDataCard(_ insights: InsightsResponse) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "chart.xyaxis.line")
                .font(.title3)
                .foregroundColor(Theme.primary)
                .frame(width: 42, height: 42)
                .background(Theme.primary.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 5) {
                Text("Your patterns are taking shape")
                    .font(.nSubheadlineBold)
                    .foregroundColor(Theme.textPrimary)
                Text("Log \(insights.episodesNeeded) more episode\(insights.episodesNeeded == 1 ? "" : "s") to start seeing patterns in your entries.")
                    .font(.nCaption)
                    .foregroundColor(Theme.textPrimary.opacity(0.7))
            }
            Spacer(minLength: 0)
        }
        .cardStyle()
    }

    private func triggerCooccurrenceCard(_ pairs: [FrequencyStat]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trigger Combinations")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            Text("How often pairs of triggers show up together in the same episode")
                .font(.nCaption)
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
                        .font(.nSubheadline)
                        .foregroundColor(Theme.textPrimary)
                    Spacer()
                    Text("\(Int(stat.proportion * 100))%")
                        .font(.nCaptionBold)
                        .foregroundColor(Theme.accent)
                }
            }
        }
        .cardStyle()
    }

    private func symptomTriggerPairsCard(_ pairs: [FrequencyStat]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Trigger → Symptom Patterns")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            Text("Tap a trigger to see which symptoms tend to follow it")
                .font(.nCaption)
                .foregroundColor(Theme.textPrimary.opacity(0.6))

            ForEach(groupedByTrigger(pairs), id: \.trigger) { group in
                DisclosureGroup {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(group.symptoms) { stat in
                            HStack {
                                Image(systemName: "arrow.right.circle")
                                    .foregroundColor(Theme.primary)
                                    .frame(width: 24)
                                Text(symptomNameFromPair(stat.name))
                                    .font(.nSubheadline)
                                    .foregroundColor(Theme.textPrimary)
                                Spacer()
                                Text("\(Int(stat.proportion * 100))%")
                                    .font(.nCaptionBold)
                                    .foregroundColor(Theme.accent)
                            }
                        }
                    }
                    .padding(.top, 6)
                } label: {
                    Text(Trigger.from(rawValue: group.trigger)?.displayName ?? group.trigger)
                        .font(.nSubheadlineBold)
                        .foregroundColor(Theme.textPrimary)
                }
                .tint(Theme.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    private var doctorSummaryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "doc.text.fill")
                    .font(.title2)
                    .foregroundColor(Theme.accent)
                    .frame(width: 48, height: 48)
                    .background(Theme.accent.opacity(0.12), in: Circle())
                VStack(alignment: .leading, spacing: 6) {
                    Text("Doctor-Ready Summary")
                        .font(.nHeadline)
                        .foregroundColor(Theme.textPrimary)
                    Text("Turn your logged episodes into a clean PDF with patterns, medication history, and a full log to bring to your next appointment.")
                        .font(.nCaption)
                        .foregroundColor(Theme.textPrimary.opacity(0.78))
                }
            }
            Button {
                showingExport = true
            } label: {
                HStack {
                    Text("Create summary")
                    Spacer()
                    Image(systemName: "arrow.right")
                }
                    .font(.nSubheadlineBold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(minHeight: 44)
                    .padding(.horizontal, 14)
                    .background(Theme.accent)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Theme.cardPadding)
        .background(
            LinearGradient(
                colors: [Theme.primary.opacity(0.2), Theme.accent.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ),
            in: RoundedRectangle(cornerRadius: Theme.cardCornerRadius, style: .continuous)
        )
    }

    private struct TriggerSymptomGroup {
        let trigger: String
        let symptoms: [FrequencyStat]
    }

    private func groupedByTrigger(_ pairs: [FrequencyStat]) -> [TriggerSymptomGroup] {
        var buckets: [String: [FrequencyStat]] = [:]
        for stat in pairs {
            let parts = stat.name.split(separator: "→").map { $0.trimmingCharacters(in: .whitespaces) }
            guard let trigger = parts.first else { continue }
            buckets[trigger, default: []].append(stat)
        }
        return buckets.map { TriggerSymptomGroup(trigger: $0.key, symptoms: $0.value) }
            .sorted { $0.symptoms.count > $1.symptoms.count }
    }

    private func symptomNameFromPair(_ raw: String) -> String {
        let parts = raw.split(separator: "→").map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return raw }
        return SymptomCategory(rawValue: parts[1])?.displayName ?? parts[1]
    }

    private func severityByTriggerCard(_ stats: [SeverityComparisonStat]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Triggers That Make Episodes Worse")
                .font(.nHeadline)
                .foregroundColor(Theme.textPrimary)
            Text("Average severity with this trigger present vs. without it")
                .font(.nCaption)
                .foregroundColor(Theme.textPrimary.opacity(0.6))

            ForEach(stats) { stat in
                VStack(alignment: .leading, spacing: 2) {
                    Text(Trigger.from(rawValue: stat.name)?.displayName ?? stat.name)
                        .font(.nSubheadline)
                        .foregroundColor(Theme.textPrimary)
                    HStack {
                        Text("With: \(stat.avgSeverityWith, specifier: "%.1f")")
                            .foregroundColor(Theme.accent)
                        Text("Without: \(stat.avgSeverityWithout, specifier: "%.1f")")
                            .foregroundColor(Theme.textPrimary.opacity(0.6))
                    }
                    .font(.nCaption)
                }
                .padding(.vertical, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }

    // MARK: - AI view components
    
    @ViewBuilder
    private var aiInsightsSection: some View {
        if viewModel.isAILoading {
            VStack {
                ProgressView()
                    .padding(.bottom, 8)
                Text("AI is analyzing your notes and triggers...")
                    .font(.nCaption)
                    .foregroundColor(Theme.textPrimary.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding()
            .cardStyle()
        } else if let aiResult = viewModel.aiResult {
            VStack(spacing: 16) {
                Text("AI Insights")
                    .font(.nTitle2)
                    .foregroundColor(Theme.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 8)

                aiInsightCard(
                    title: "Triggers to Avoid", 
                    subtitle: "Based on your logged episodes and notes, these triggers appear to be associated with more severe or frequent episodes.",
                    items: aiResult.triggersToAvoid.map { rawValue in
                        if let trigger = Trigger.from(rawValue: rawValue) {
                            return trigger.displayName
                        } else {
                            // e.g.converts "high_histamine_food" -> "High Histamine Food"
                            return rawValue.replacingOccurrences(of: "_", with: " ").capitalized
                        }
                    },
                    icon: "exclamationmark.triangle"
                )
                aiInsightCard(
                    title: "What's New (Last 2 Weeks)",
                    subtitle: "Recently appearing patterns compared with your earlier logs.",
                    items: aiResult.whatsNew,
                    icon: "sparkles"
                )
                aiInsightCard(
                    title: "Weather Comparison",
                    subtitle: "Archived local weather on episode days compared with days without a logged episode.",
                    items: aiResult.weatherInsights,
                    icon: "cloud.sun"
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
                .font(.nHeadline)
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
                    .font(.nHeadline)
                    .foregroundColor(Theme.textPrimary)
            }

            if let subtitle = subtitle {
                Text(subtitle)
                    .font(.nCaption)
                    .foregroundColor(Theme.textPrimary.opacity(0.6))
            }
            
            if items.isEmpty {
                Text("No specific patterns detected yet.")
                    .font(.nSubheadline)
                    .foregroundColor(Theme.textPrimary.opacity(0.7))
            } else {
                ForEach(items.indices, id: \.self) { index in
                    Text("• \(items[index])")
                    .font(.nSubheadline)
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
