import SwiftUI
import Observation

@Observable
@MainActor
final class AppState {
    var isListening = false
    var transcript = ""
    var interimText = ""
    var statusMessage = "Idle"

    var selectedEngine: STTEngine = AppConfig.defaultSTTEngine {
        didSet {
            UserDefaults.standard.set(selectedEngine.rawValue, forKey: "selectedEngine")
        }
    }

    var selectedLanguage: AppLanguage = AppConfig.defaultLanguage {
        didSet {
            UserDefaults.standard.set(selectedLanguage.rawValue, forKey: "selectedLanguage")
        }
    }

    var stopWord: String = AppConfig.defaultStopWord {
        didSet {
            UserDefaults.standard.set(stopWord, forKey: "stopWord")
        }
    }

    var isLLMEnabled = false {
        didSet {
            UserDefaults.standard.set(isLLMEnabled, forKey: "isLLMEnabled")
        }
    }

    var errorMessage: String?

    private var audioEngine: AudioEngine
    private var currentSTTService: (any STTService)?
    private var terminalService: TerminalService
    private var streamingController: StreamingController?
    private var stopWordDetector: StopWordDetector
    private var listeningTask: Task<Void, Never>?

    var hasSonioxKey: Bool {
        (try? KeychainService.read(key: "apiKey", service: AppConfig.sonioxAPIKeyService)) != nil
    }

    var hasXAIKey: Bool {
        (try? KeychainService.read(key: "apiKey", service: AppConfig.xaiAPIKeyService)) != nil
    }

    init() {
        self.audioEngine = AudioEngine()
        self.terminalService = TerminalService()
        self.stopWordDetector = StopWordDetector()

        self.streamingController = StreamingController(
            terminalService: terminalService,
            stopWordDetector: stopWordDetector,
            onReset: { [weak self] in
                Task { @MainActor in
                    self?.transcript = ""
                    self?.interimText = ""
                    self?.currentSTTService?.reset()
                }
            }
        )

        // Load saved settings from UserDefaults
        if let engineRaw = UserDefaults.standard.string(forKey: "selectedEngine"),
           let engine = STTEngine(rawValue: engineRaw) {
            self.selectedEngine = engine
        }

        if let languageRaw = UserDefaults.standard.string(forKey: "selectedLanguage"),
           let language = AppLanguage(rawValue: languageRaw) {
            self.selectedLanguage = language
        }

        if let savedStopWord = UserDefaults.standard.string(forKey: "stopWord") {
            self.stopWord = savedStopWord
        }

        self.isLLMEnabled = UserDefaults.standard.bool(forKey: "isLLMEnabled")
    }

    func toggleListening() async {
        if isListening {
            stopListening()
        } else {
            await startListening()
        }
    }

    func resetTranscript() {
        transcript = ""
        interimText = ""
        streamingController?.resetState()
    }

    private func startListening() async {
        errorMessage = nil

        // Check permissions
        let micGranted = await audioEngine.requestMicrophonePermission()
        guard micGranted else {
            errorMessage = "Microphone permission denied"
            return
        }

        if !TerminalService.isAccessibilityGranted() {
            TerminalService.requestAccessibility()
            errorMessage = "Accessibility permission required"
            return
        }

        guard terminalService.isTerminalRunning() else {
            errorMessage = "Terminal.app is not running"
            return
        }

        // Create STT service
        let sttService = createSTTService()
        self.currentSTTService = sttService

        do {
            try await sttService.start()
            isListening = true
            statusMessage = "Listening..."

            // Focus terminal
            _ = terminalService.focusTerminal()

            // Start processing transcript stream
            listeningTask = Task {
                for await result in sttService.transcriptStream {
                    guard !Task.isCancelled else { break }
                    self.handleSTTResult(result)
                }
            }
        } catch {
            errorMessage = "Failed to start: \(error.localizedDescription)"
            isListening = false
            statusMessage = "Error"
        }
    }

    private func stopListening() {
        listeningTask?.cancel()
        listeningTask = nil
        currentSTTService?.stop()
        currentSTTService = nil
        audioEngine.stop()
        isListening = false
        statusMessage = "Idle"
    }

    private func createSTTService() -> any STTService {
        switch selectedEngine {
        case .apple:
            return AppleSTTService(audioEngine: audioEngine, language: selectedLanguage)
        case .soniox:
            let apiKey = (try? KeychainService.read(key: "apiKey", service: AppConfig.sonioxAPIKeyService)) ?? ""
            return SonioxSTTService(audioEngine: audioEngine, apiKey: apiKey)
        }
    }

    private func handleSTTResult(_ result: STTResult) {
        if result.isFinal {
            transcript = result.text
            interimText = ""
        } else {
            interimText = result.text
        }

        // Focus terminal and stream
        _ = terminalService.focusTerminal()
        streamingController?.processResult(result)
    }
}
