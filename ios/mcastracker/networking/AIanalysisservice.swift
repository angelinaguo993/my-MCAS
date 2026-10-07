import Foundation

class AIAnalysisService {
    // private key, stored in Secrets.swift (not committed for security)
    private let apiKey = Secrets.openRouterAPIKey
    private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    /// `insights` is optional so this still works even before 5+ episodes
    /// exist (when /insights returns no computed stats yet).
    func fetchAnalysis(for episodes: [Episode], insights: InsightsResponse?) async throws -> AIAnalysisResult {
        let episodeDataString = episodes.map {
            "Date: \($0.date), Triggers: \($0.triggers.map { $0.displayName }), Meds Taken: \($0.medicationNames), Helped: \($0.medicationHelped ?? false), Notes: \($0.notes ?? "None")"
        }.joined(separator: "\n")

        // Ground the AI in real computed stats instead of letting it
        // free-associate patterns from raw text alone.
        var statsContext = ""
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
        When a "Computed" stats section is provided, treat those numbers as ground truth \
        and cite them directly (e.g. "your logs show X helped 80% of the 5 times you took it"). \
        Never state a pattern as fact without a number or sample size behind it. Phrase \
        everything as an observation to consider, not a diagnosis or instruction. \
        Return STRICT JSON matching this structure exactly:
        {
          "triggersToAvoid": ["trigger 1", "trigger 2"],
          "medicationInsights": ["insight 1"],
          "notesAnalysis": ["pattern found in notes, grounded in the data given"]
        }
        """

        let userMessage = episodeDataString + statsContext

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

        return try JSONDecoder().decode(AIAnalysisResult.self, from: jsonData)
    }
}