import Cocoa
import ApplicationServices

enum TerminalServiceError: Error {
    case accessibilityNotGranted
    case terminalNotRunning
    case eventCreationFailed
}

final class TerminalService: @unchecked Sendable {

    static func isAccessibilityGranted() -> Bool {
        AXIsProcessTrusted()
    }

    static func requestAccessibility() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
    }

    private func terminalProcessID() -> pid_t? {
        NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Terminal")
            .first?.processIdentifier
    }

    func isTerminalRunning() -> Bool {
        terminalProcessID() != nil
    }

    func focusTerminal() -> Bool {
        guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.Terminal").first else {
            return false
        }
        return app.activate()
    }

    func sendText(_ text: String) throws {
        guard Self.isAccessibilityGranted() else {
            throw TerminalServiceError.accessibilityNotGranted
        }
        guard let pid = terminalProcessID() else {
            throw TerminalServiceError.terminalNotRunning
        }

        for char in text {
            try sendCharacter(char, to: pid)
        }
    }

    func sendReturn() throws {
        guard let pid = terminalProcessID() else {
            throw TerminalServiceError.terminalNotRunning
        }
        try sendKeyCode(36, to: pid) // Return key
    }

    func sendBackspace(count: Int) throws {
        guard let pid = terminalProcessID() else {
            throw TerminalServiceError.terminalNotRunning
        }
        for _ in 0..<count {
            try sendKeyCode(51, to: pid) // Delete key
        }
    }

    private func sendCharacter(_ char: Character, to pid: pid_t) throws {
        let chars = Array(String(char).utf16)
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) else {
            throw TerminalServiceError.eventCreationFailed
        }
        keyDown.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: chars)

        guard let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            throw TerminalServiceError.eventCreationFailed
        }
        keyUp.keyboardSetUnicodeString(stringLength: chars.count, unicodeString: chars)

        keyDown.postToPid(pid)
        keyUp.postToPid(pid)
    }

    private func sendKeyCode(_ keyCode: CGKeyCode, to pid: pid_t) throws {
        guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true) else {
            throw TerminalServiceError.eventCreationFailed
        }
        guard let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
            throw TerminalServiceError.eventCreationFailed
        }

        keyDown.postToPid(pid)
        keyUp.postToPid(pid)
    }
}
