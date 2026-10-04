import Foundation

class AIAnalysisService {
    // Replace with your actual key, but NEVER commit this key to GitHub!
    private let apiKey = Secrets.openRouterAPIKey 
    private let endpoint = URL(string: "https://openrouter.ai/api/v1/chat/completions")!

    func fetchAnalysis(for episodes: [Episode]) async throws -> AIAnalysisResult {
        // 1. Format the user's data into a readable string for the AI
        let episodeDataString = episodes.map { 
            "Date: \($0.date), Triggers: \($0.triggers.map { $0.displayName }), Meds Taken: \($0.medicationNames), Helped: \($0.medicationHelped ?? false), Notes: \($0.notes ?? "None")"
        }.joined(separator: "\n")

        // 2. Instruct the AI to act as a data analyzer and return STRICT JSON
        let systemPrompt = """
        You are an analytical engine for a Mast Cell Activation Syndrome (MCAS) tracker. 
        Analyze the following episode logs. Return your analysis in STRICT JSON format matching this structure exactly:
        {
          "triggersToAvoid": ["trigger 1", "trigger 2"],
          "medicationInsights": ["insight 1"],
          "notesAnalysis": ["hidden pattern from notes"]
        }
        Identify common triggers, note if certain medications help or fail, and read the 'Notes' to find hidden environmental or emotional causes.
        """

        let requestBody: [String: Any] = [
            "model": "anthropic/claude-opus-5.5",
            "response_format": ["type": "json_object"], // Forces JSON output
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": episodeDataString]
            ]
        ]

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        // 3. Make the network call and decode the result
        let (data, _) = try await URLSession.shared.data(for: request)
        
        // Parse the nested OpenAI JSON response to extract your AIAnalysisResult
        struct OpenAIResponse: Codable {
            struct Choice: Codable {
                struct Message: Codable { let content: String }
                let message: Message
            }
            let choices: [Choice]
        }
        
        let response = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        guard let jsonString = response.choices.first?.message.content,
              let jsonData = jsonString.data(using: .utf8) else {
            throw URLError(.cannotParseResponse)
        }
        
        return try JSONDecoder().decode(AIAnalysisResult.self, from: jsonData)
    }
}