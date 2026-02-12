import Foundation

enum STTEngine: String, CaseIterable {
    case apple = "Apple"
    case soniox = "Soniox"
}

enum AppLanguage: String, CaseIterable {
    case english = "en-US"
    case vietnamese = "vi-VN"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        }
    }
}

enum AppConfig {
    static let defaultStopWord = "thank you"
    static let defaultLanguage = AppLanguage.english
    static let defaultSTTEngine = STTEngine.apple
    static let sttRestartInterval: TimeInterval = 55 // Restart before 60s limit
    static let sonioxModel = "stt-rt-v4"
    static let sonioxWebSocketURL = "wss://stt-rt.soniox.com/transcribe-websocket"
    static let xaiBaseURL = "https://api.x.ai/v1"
    static let xaiModel = "grok-3-mini-fast"

    // Keychain keys
    static let sonioxAPIKeyService = "com.anhdt14.MyVoiceAssistant.soniox"
    static let xaiAPIKeyService = "com.anhdt14.MyVoiceAssistant.xai"
}
