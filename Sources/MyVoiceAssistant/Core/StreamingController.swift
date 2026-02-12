import Foundation

@MainActor
final class StreamingController {
    private let terminalService: TerminalService
    private let stopWordDetector: StopWordDetector
    private var lastSentText = ""
    private var onReset: (() -> Void)?

    init(terminalService: TerminalService, stopWordDetector: StopWordDetector, onReset: (() -> Void)? = nil) {
        self.terminalService = terminalService
        self.stopWordDetector = stopWordDetector
        self.onReset = onReset
    }

    func processResult(_ result: STTResult) {
        let text = result.text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        let stopResult = stopWordDetector.check(text)

        if stopResult.detected {
            handleStopWord(command: stopResult.command)
        } else {
            handleStreaming(text: text)
        }
    }

    func resetState() {
        lastSentText = ""
    }

    private func handleStopWord(command: String) {
        // Send any remaining characters
        if command.count > lastSentText.count, command.hasPrefix(lastSentText) {
            let newChars = String(command.dropFirst(lastSentText.count))
            try? terminalService.sendText(newChars)
        } else if !command.hasPrefix(lastSentText) {
            // Revision happened — correct it
            handleRevision(newText: command)
        }

        // Send Enter
        try? terminalService.sendReturn()

        // Reset for next command
        lastSentText = ""
        onReset?()
    }

    private func handleStreaming(text: String) {
        if text.hasPrefix(lastSentText) {
            // Normal case: text extended
            let newChars = String(text.dropFirst(lastSentText.count))
            if !newChars.isEmpty {
                try? terminalService.sendText(newChars)
                lastSentText = text
            }
        } else {
            // Revision: STT changed earlier text
            handleRevision(newText: text)
        }
    }

    private func handleRevision(newText: String) {
        // Find common prefix
        let commonLength = zip(lastSentText, newText).prefix(while: { $0 == $1 }).count
        let charsToDelete = lastSentText.count - commonLength
        let newSuffix = String(newText.dropFirst(commonLength))

        // Delete divergent characters and type corrected text
        if charsToDelete > 0 {
            try? terminalService.sendBackspace(count: charsToDelete)
        }
        if !newSuffix.isEmpty {
            try? terminalService.sendText(newSuffix)
        }
        lastSentText = newText
    }
}
