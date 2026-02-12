import Speech
import AVFoundation

enum AppleSTTError: Error {
    case recognizerUnavailable
    case authorizationDenied
    case recognitionFailed(Error)
}

final class AppleSTTService: STTService, @unchecked Sendable {
    private let audioEngine: AudioEngine
    private var recognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private var continuation: AsyncStream<STTResult>.Continuation?
    private var lastTranscript = ""
    private let language: AppLanguage

    let transcriptStream: AsyncStream<STTResult>

    init(audioEngine: AudioEngine, language: AppLanguage = AppConfig.defaultLanguage) {
        self.audioEngine = audioEngine
        self.language = language

        var cont: AsyncStream<STTResult>.Continuation?
        self.transcriptStream = AsyncStream { continuation in
            cont = continuation
        }
        self.continuation = cont
    }

    static func requestAuthorization() async -> SFSpeechRecognizerAuthorizationStatus {
        await withCheckedContinuation { continuation in
            SFSpeechRecognizer.requestAuthorization { status in
                continuation.resume(returning: status)
            }
        }
    }

    func start() async throws {
        let status = await Self.requestAuthorization()
        guard status == .authorized else {
            throw AppleSTTError.authorizationDenied
        }

        let locale = Locale(identifier: language.rawValue)
        recognizer = SFSpeechRecognizer(locale: locale)

        guard let recognizer, recognizer.isAvailable else {
            throw AppleSTTError.recognizerUnavailable
        }

        startRecognition()
    }

    func stop() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        audioEngine.removeTap()
    }

    func reset() {
        stop()
        lastTranscript = ""
        startRecognition()
    }

    private func startRecognition() {
        guard let recognizer else { return }

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.addsPunctuation = false
        self.recognitionRequest = request

        let inputFormat = audioEngine.inputFormat
        audioEngine.installTap(bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.recognitionRequest?.append(buffer)
        }

        do {
            try audioEngine.start()
        } catch {
            continuation?.yield(STTResult(text: "", isFinal: false, newWords: ""))
            return
        }

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            guard let self else { return }

            if let result {
                let text = result.bestTranscription.formattedString
                let newWords: String
                if text.hasPrefix(self.lastTranscript) {
                    newWords = String(text.dropFirst(self.lastTranscript.count))
                } else {
                    newWords = text
                }

                let sttResult = STTResult(
                    text: text,
                    isFinal: result.isFinal,
                    newWords: newWords
                )
                self.continuation?.yield(sttResult)

                if result.isFinal {
                    self.lastTranscript = text
                }
            }

            if error != nil || (result?.isFinal == true) {
                self.restartRecognition()
            }
        }
    }

    private func restartRecognition() {
        recognitionTask?.cancel()
        recognitionTask = nil
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        audioEngine.removeTap()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            self?.startRecognition()
        }
    }
}
