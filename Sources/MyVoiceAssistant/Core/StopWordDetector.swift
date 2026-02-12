import Foundation

struct StopWordResult {
    let detected: Bool
    let command: String
}

struct StopWordDetector {
    var stopWords: [String] = ["thank you", "cảm ơn"]

    func check(_ text: String) -> StopWordResult {
        let normalized = text
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .trimmingCharacters(in: .punctuationCharacters)

        for stopWord in stopWords {
            if normalized.hasSuffix(stopWord) {
                let commandEnd = normalized.index(normalized.endIndex, offsetBy: -stopWord.count)
                let command = String(normalized[normalized.startIndex..<commandEnd])
                    .trimmingCharacters(in: .whitespacesAndNewlines)

                // Return the original text with stop word removed (preserve case)
                let originalTrimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                let originalCommand: String
                if originalTrimmed.count >= stopWord.count {
                    let end = originalTrimmed.index(originalTrimmed.endIndex, offsetBy: -stopWord.count)
                    originalCommand = String(originalTrimmed[originalTrimmed.startIndex..<end])
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                } else {
                    originalCommand = command
                }

                return StopWordResult(detected: true, command: originalCommand)
            }
        }

        return StopWordResult(detected: false, command: text)
    }
}
