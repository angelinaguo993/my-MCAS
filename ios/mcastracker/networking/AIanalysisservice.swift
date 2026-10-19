import Foundation

class AIAnalysisService {
    // private key, stored in Secrets.swift (not committed for security)
    private let apiKey = Secrets.openRouterAPIKey
    private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    private struct RecentSymptomChange {
        let symptom: String
        let recentCount: Int
        let recentEpisodeCount: Int
        let priorCount: Int
        let priorEpisodeCount: Int
        let frequencyIncreased: Bool
        let recentTriggers: [(name: String, count: Int)]
        let changedCooccurringTriggers: [(name: String, count: Int, priorCount: Int)]

        var contextLine: String {
            let triggerContext = recentTriggers.isEmpty
                ? "No triggers were logged in the same recent episodes."
                : "Co-occurring logged triggers: " + recentTriggers
                    .map { "\($0.name) in \($0.count) episode(s)" }
                    .joined(separator: ", ") + "."
            let newTriggerContext = changedCooccurringTriggers.isEmpty
                ? ""
                : " Symptom-trigger pairings recorded more often than in the prior 14 days: "
                    + changedCooccurringTriggers.map { "\($0.name): recent \($0.count), prior \($0.priorCount) episode(s)" }.joined(separator: ", ") + "."
            return "\(symptom): recent \(recentCount)/\(recentEpisodeCount) logged episodes; prior \(priorCount)/\(priorEpisodeCount). \(triggerContext)\(newTriggerContext)"
        }

        var fallbackSummary: String {
            let comparison = priorEpisodeCount == 0
                ? "new in recent logs"
                : "\(recentCount)/\(recentEpisodeCount) recent episodes versus \(priorCount)/\(priorEpisodeCount) previously"
            let triggerSummary = changedCooccurringTriggers.first.map {
                "\($0.name) also appeared alongside it more often"
            } ?? "no trigger pairing stood out"
            return "\(symptom) was \(comparison); \(triggerSummary). Your logs show co-occurrence, not why it changed."
        }
    }

    /// insights is optional so this still works even before 5+ episodes
    /// exist (when /insights returns no computed stats yet).
    func fetchAnalysis(for episodes: [Episode], insights: InsightsResponse?, profile: UserProfile? = nil) async throws -> AIAnalysisResult {
        let episodeDataString = episodes.map {
            "Date/time: \($0.date) to \($0.endDate ?? $0.date), Triggers: \($0.triggers.map { $0.displayName }), Symptoms: \($0.symptoms.map { "\($0.category.displayName): \($0.specificSymptoms.joined(separator: ", "))" }), Weather: \($0.weatherSummary ?? "not recorded"), Meds Taken: \($0.medicationNames), Helped: \($0.medicationHelped ?? false), Notes: \($0.notes ?? "None")"
        }.joined(separator: "\n")

        let priorHistory = profile.map { profile in
            "\n\nUser-reported history from onboarding (these are prior, potentially unlogged episodes; do not count them as dated/logged episodes):\nPreviously reported triggers: \(profile.previousTriggers.map(\.displayName).joined(separator: ", "))\nPreviously reported symptoms: \((profile.previousSymptoms.map(\.displayName) + profile.previousSpecificSymptoms + [profile.otherSymptomDescription ?? ""]).filter { !$0.isEmpty }.joined(separator: ", "))"
        } ?? ""
        let profileCity = profile?.city.trimmingCharacters(in: .whitespacesAndNewlines)
        let city = (profileCity?.isEmpty == false ? profileCity : nil)
            ?? UserDefaults.standard.string(forKey: "userCity")
            ?? "Seattle"
        let weatherComparison = await WeatherService.shared.comparisonContext(for: episodes, city: city)
            .map { "\n\n\($0)" } ?? ""
        let recentChanges = recentSymptomChanges(in: episodes, endingAt: Date())
        let symptomChangeContext = recentChanges.isEmpty
            ? "\n\nComputed recent symptom comparison: no symptom frequency increased and no symptom-trigger pairing appeared more often between the last 14 days and the prior 14 days of logged episodes."
            : "\n\nComputed recent symptom changes (episode counts are the source of truth):\n"
                + recentChanges.map(\.contextLine).joined(separator: "\n")

        var statsContext = ""
        if let trend = insights?.recentTrend {
            statsContext += "\n\nComputed recent trend: \(trend.episodesLast14Days) episodes in the last 14 days vs \(trend.episodesPrior14Days) in the prior 14 days (\(trend.direction))."
        }
        if let insights = insights, insights.hasEnoughData {
            if !insights.triggerCooccurrence.isEmpty {
                let pairs = insights.triggerCooccurrence.map {
                    "\($0.name): co-occurred in \(Int($0.proportion * 100))% of episodes (\($0.sampleSize) total episodes)"
                }.joined(separator: "\n")
                statsContext += "\n\nComputed trigger combinations (statistically derived, not guessed):\n\(pairs)"
            }
            if !insights.medicationEffectiveness.isEmpty {
                let meds = insights.medicationEffectiveness.map {
                    "\($0.name): helped \(Int($0.proportion * 100))% of the \($0.sampleSize) times it was taken"
                }.joined(separator: "\n")
                statsContext += "\n\nComputed medication effectiveness (from this user's own logs only):\n\(meds)"
            }
        }

        let systemPrompt = """
        You are an analytical engine for a Mast Cell Activation Syndrome (MCAS) tracker. \
        You are NOT a medical professional and must never state general clinical facts \
        that aren't derived from the specific data given to you — no claims about how \
        medications "generally" work, only what THIS user's own logged data shows. \
        Treat computed stats as the source of truth. Write conclusion-first for someone scanning \
        the screen. Keep each list item to one or two short sentences and no more than 32 words. \
        Avoid introductions, filler, repeated caveats, and restating data. Use numbers only when \
        they clarify a comparison. Phrase findings as observations from these logs, not a diagnosis, \
        cause, or instruction. \
        Return STRICT JSON matching this structure exactly:
        {
          "triggersToAvoid": ["trigger 1", "trigger 2"],
          "medicationInsights": ["insight 1"],
          "notesAnalysis": ["pattern found in notes, grounded in the data given"]
          ,"whatsNew": ["one concise conclusion about the clearest symptom change and a relevant co-occurring trigger, if present"],
          "weatherInsights": ["Temperature: descriptive comparison with sample counts", "Humidity: descriptive comparison with sample counts", "Pressure: descriptive comparison with sample counts", "One sentence describing whether logged weather appears related to episode severity, or stating that no clear pattern is supported"]
        }
        """

        let userMessage = "Logged episodes (including episode weather when available):\n" + episodeDataString + statsContext + symptomChangeContext + priorHistory + weatherComparison + "\n\nFor what'sNew, return at most two concise takeaways. Lead with the clearest symptom change, then mention only a trigger recorded alongside it more often. Combine related symptoms where useful; don't enumerate every field or include raw counts unless one comparison makes the conclusion clearer. Say 'appeared alongside' rather than implying cause. If the computed comparison reports no changes, return an empty list. Use onboarding history only as undated context, never as a dated comparison. Do not infer symptoms on days without logs. Keep other insight items concise and conclusion-first. For weatherInsights, return exactly four short strings when data is available: three measurement comparisons beginning 'Temperature:', 'Humidity:', and 'Pressure:', then one brief conclusion about whether logged weather appears associated with episode severity. Avoid unnecessary statistics and boilerplate. If episode severity data cannot support a pattern, say no clear relationship can be determined. Describe association only; do not imply causation. If weather data is unavailable or insufficient, return an empty weatherInsights list. Days without a log are not confirmed symptom-free."

        let requestBody: [String: Any] = [
            "model": "openai/gpt-4o-mini",
            "response_format": ["type": "json_object"],
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userMessage]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let rawString = String(data: data, encoding: .utf8) {
            print("Raw OPENROUTER response: \(rawString)")
        }

        struct OpenAIResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }

        let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let jsonString = decodedResponse.choices.first?.message.content,
              let jsonData = jsonString.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }

        let result = try JSONDecoder().decode(AIAnalysisResult.self, from: jsonData)
        return AIAnalysisResult(
            triggersToAvoid: concise(result.triggersToAvoid, limit: 3),
            medicationInsights: concise(result.medicationInsights, limit: 3),
            notesAnalysis: concise(result.notesAnalysis, limit: 3),
            whatsNew: concise(result.whatsNew.isEmpty ? recentChanges.map(\.fallbackSummary) : result.whatsNew, limit: 2),
            weatherInsights: concise(result.weatherInsights, limit: 4)
        )
    }

    private func concise(_ items: [String], limit: Int) -> [String] {
        items.prefix(limit).map { item in
            let trimmed = item.trimmingCharacters(in: .whitespacesAndNewlines)
            let words = trimmed.split(whereSeparator: \.isWhitespace)
            guard words.count > 36 else { return trimmed }
            return words.prefix(35).joined(separator: " ") + "…"
        }
    }

    private func recentSymptomChanges(in episodes: [Episode], endingAt now: Date) -> [RecentSymptomChange] {
        guard let recentStart = Calendar.current.date(byAdding: .day, value: -14, to: now),
              let priorStart = Calendar.current.date(byAdding: .day, value: -28, to: now) else {
            return []
        }

        let recentEpisodes = episodes.filter { $0.date >= recentStart && $0.date <= now }
        let priorEpisodes = episodes.filter { $0.date >= priorStart && $0.date < recentStart }
        guard !recentEpisodes.isEmpty else { return [] }

        func symptomLabels(in episode: Episode) -> Set<String> {
            Set(episode.symptoms.flatMap { symptom in
                let specifics = symptom.specificSymptoms
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                return specifics.isEmpty ? [symptom.category.displayName] : specifics
            })
        }

        var recentCounts: [String: Set<String>] = [:]
        var priorCounts: [String: Set<String>] = [:]
        var recentTriggers: [String: [String: Set<String>]] = [:]
        var priorTriggers: [String: [String: Set<String>]] = [:]

        for episode in recentEpisodes {
            for symptom in symptomLabels(in: episode) {
                recentCounts[symptom, default: []].insert(episode.id)
                for trigger in Set(episode.triggers) {
                    recentTriggers[symptom, default: [:]][trigger.displayName, default: []].insert(episode.id)
                }
            }
        }
        for episode in priorEpisodes {
            for symptom in symptomLabels(in: episode) {
                priorCounts[symptom, default: []].insert(episode.id)
                for trigger in Set(episode.triggers) {
                    priorTriggers[symptom, default: [:]][trigger.displayName, default: []].insert(episode.id)
                }
            }
        }

        return recentCounts.compactMap { symptom, recentIDs in
            let priorIDs = priorCounts[symptom] ?? []
            let recentRate = Double(recentIDs.count) / Double(recentEpisodes.count)
            let priorRate = priorEpisodes.isEmpty ? 0 : Double(priorIDs.count) / Double(priorEpisodes.count)
            let frequencyIncreased = recentRate > priorRate

            let triggers = (recentTriggers[symptom] ?? [:])
                .map { (name: $0.key, count: $0.value.count) }
                .sorted { $0.count > $1.count }
            let priorTriggerCounts = priorTriggers[symptom] ?? [:]
            let changedCooccurringTriggers = triggers.compactMap { trigger -> (name: String, count: Int, priorCount: Int)? in
                let priorCount = priorTriggerCounts[trigger.name]?.count ?? 0
                let recentRate = Double(trigger.count) / Double(recentEpisodes.count)
                let priorRate = priorEpisodes.isEmpty ? 0 : Double(priorCount) / Double(priorEpisodes.count)
                return recentRate > priorRate
                    ? (name: trigger.name, count: trigger.count, priorCount: priorCount)
                    : nil
            }
            guard frequencyIncreased || !changedCooccurringTriggers.isEmpty else { return nil }
            return RecentSymptomChange(
                symptom: symptom,
                recentCount: recentIDs.count,
                recentEpisodeCount: recentEpisodes.count,
                priorCount: priorIDs.count,
                priorEpisodeCount: priorEpisodes.count,
                frequencyIncreased: frequencyIncreased,
                recentTriggers: triggers,
                changedCooccurringTriggers: changedCooccurringTriggers
            )
        }
        .sorted { lhs, rhs in
            let lhsPriorRate = lhs.priorEpisodeCount == 0 ? 0 : Double(lhs.priorCount) / Double(lhs.priorEpisodeCount)
            let rhsPriorRate = rhs.priorEpisodeCount == 0 ? 0 : Double(rhs.priorCount) / Double(rhs.priorEpisodeCount)
            let lhsChange = Double(lhs.recentCount) / Double(lhs.recentEpisodeCount) - lhsPriorRate
            let rhsChange = Double(rhs.recentCount) / Double(rhs.recentEpisodeCount) - rhsPriorRate
            return lhsChange > rhsChange
        }
    }
}
