import Foundation

enum LLMError: Error {
    case noAPIKey
    case requestFailed(Error)
    case invalidResponse
}

struct LLMService: Sendable {
    private let apiKey: String

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func correctTranscript(_ text: String, context: String? = nil) async throws -> String {
        let url = URL(string: "\(AppConfig.xaiBaseURL)/chat/completions")!

        var systemPrompt = """
        You are a speech-to-text error corrector. Fix transcription errors in the following text.
        The text may be a terminal command, code, or natural language.
        If the text is Vietnamese, preserve Vietnamese. If English, preserve English.
        Only fix clear STT errors. Do not add or remove content.
        Return ONLY the corrected text, nothing else.
        """
        if let context {
            systemPrompt += "\nContext: \(context)"
        }

        let body: [String: Any] = [
            "model": AppConfig.xaiModel,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": text]
            ],
            "temperature": 0.1,
            "max_tokens": 256
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw LLMError.invalidResponse
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw LLMError.invalidResponse
        }

        return content.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
