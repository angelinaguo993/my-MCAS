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
                                    let worseningTriggers = insights.severityByTrigger.filter {
                                        $0.avgSeverityWith > $0.avgSeverityWithout
                                    }
                                    if !worseningTriggers.isEmpty {
                                        severityByTriggerCard(worseningTriggers)
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
            Text("How often pairs of triggers show up together in the same episode. Try to avoid being in contact with both of these triggers at the same time.")
                .font(.nCaption)
                .foregroundColor(Theme.textPrimary.opacity(0.6))

            ForEach(pairs) { stat in
                let parts = stat.name.split(separator: "+").map { $0.trimmingCharacters(in: .whitespaces) }
                let formattedParts = parts.enumerated().map { index, rawPart -> String in
                    let name = Trigger.from(rawValue: rawPart)?.displayName 
                        ?? rawPart.replacingOccurrences(of: "_", with: " ").capitalized
                    // Keep the first trigger capitalized, lowercase any subsequent triggers
                    return index == 0 ? name : name.lowercased()
                }

                HStack {
                    Image(systemName: "link")
                        .foregroundColor(Theme.primary)
                        .frame(width: 24)
                    Text(formattedParts.joined(separator: " + "))
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
            Text("Clear connections detected from your entries. The trigger on the left appears to lead to the symptom on the right in your logged episodes.")
                .font(.nCaption)
                .foregroundColor(Theme.textPrimary.opacity(0.6))

            ForEach(pairs.prefix(3)) { stat in
                let parts = stat.name.split(separator: "→").map { $0.trimmingCharacters(in: .whitespaces) }
                let triggerRaw = parts.first ?? ""
                let symptomRaw = parts.count >= 2 ? parts[1] : stat.name
                
                let triggerName = Trigger.from(rawValue: triggerRaw)?.displayName 
                    ?? triggerRaw.replacingOccurrences(of: "_", with: " ").capitalized
                
                // Lowercase the symptom name so it reads naturally inside the sentence card
                let symptomName = (SymptomCategory(rawValue: symptomRaw)?.displayName 
                    ?? symptomRaw.replacingOccurrences(of: "_", with: " ").capitalized).lowercased()
                
                let occurrenceCount = Int((stat.proportion * Double(stat.sampleSize)).rounded())
                let percentage = Int((stat.proportion * 100).rounded())

                PatternInsightCard(
                    triggerName: triggerName,
                    topSymptom: symptomName,
                    occurrenceCount: max(1, occurrenceCount),
                    percentage: percentage
                )
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
                    Text("Doctor-Ready PDF Summary")
                        .font(.nHeadline)
                        .foregroundColor(Theme.textPrimary)
                    Text("Turn your logged episodes into a clean PDF with patterns, medication history, and a full log to bring to your next appointment.")
                        .font(.nCaption)
                        .foregroundColor(Theme.textPrimary.opacity(0.78))
                }
            }
            Button {
                Haptics.play(.medium)
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
            .buttonStyle(ScaleSpringButtonStyle())
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
                weatherComparisonCard(aiResult.weatherInsights)
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
                Haptics.play(.medium)
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
            .buttonStyle(ScaleSpringButtonStyle())
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

    private func weatherComparisonCard(_ items: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "cloud.sun").foregroundColor(Theme.accent)
                Text("Weather Comparison")
                    .font(.nHeadline)
                    .foregroundColor(Theme.textPrimary)
            }
            Text("Archived local weather on episode days compared with days without a logged episode.")
                .font(.nCaption)
                .foregroundColor(Theme.textPrimary.opacity(0.6))

            if items.isEmpty {
                Text("No specific patterns detected yet.")
                    .font(.nSubheadline)
                    .foregroundColor(Theme.textPrimary.opacity(0.7))
            } else {
                ForEach(Array(items.prefix(3).enumerated()), id: \.offset) { _, item in
                    HStack(alignment: .firstTextBaseline, spacing: 8) {
                        Text("•").foregroundColor(Theme.accent)
                        Text(item).foregroundColor(Theme.textPrimary)
                    }
                    .font(.nSubheadline)
                }
                if items.count > 3 {
                    Text(items.dropFirst(3).joined(separator: " "))
                        .font(.nSubheadline)
                        .foregroundColor(Theme.textPrimary.opacity(0.8))
                        .padding(.top, 2)
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


struct ScaleSpringButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct Haptics {
    static func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }
    
    static func notification(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.prepare()
        generator.notificationOccurred(type)
    }
}

struct PatternInsightCard: View {
    let triggerName: String
    let topSymptom: String
    let occurrenceCount: Int
    let percentage: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Theme.accent.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: "bolt.fill")
                    .foregroundColor(Theme.accent)
                    .font(.subheadline)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Key Correlation • \(percentage)% Match")
                    .font(.caption2.bold())
                    .foregroundColor(Theme.accent)
                    .textCase(.uppercase)
                
                Text("**\(triggerName)** frequently leads to **\(topSymptom)**.")
                    .font(.nSubheadline)
                    .foregroundColor(Theme.textPrimary)
                
                Text("Observed across \(occurrenceCount) logged episodes.")
                    .font(.nCaption)
                    .foregroundColor(Theme.textPrimary.opacity(0.6))
            }
            
            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.03), radius: 6, x: 0, y: 3)
    }
}