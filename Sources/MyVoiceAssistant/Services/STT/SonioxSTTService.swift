import Foundation
import AVFoundation

enum SonioxSTTError: Error {
    case noAPIKey
    case connectionFailed(Error)
    case invalidResponse
}

final class SonioxSTTService: STTService, @unchecked Sendable {
    private let audioEngine: AudioEngine
    private let apiKey: String
    private var webSocketTask: URLSessionWebSocketTask?
    private var continuation: AsyncStream<STTResult>.Continuation?
    private var accumulatedText = ""
    private var isActive = false

    let transcriptStream: AsyncStream<STTResult>

    init(audioEngine: AudioEngine, apiKey: String) {
        self.audioEngine = audioEngine
        self.apiKey = apiKey

        var cont: AsyncStream<STTResult>.Continuation?
        self.transcriptStream = AsyncStream { continuation in
            cont = continuation
        }
        self.continuation = cont
    }

    func start() async throws {
        guard !apiKey.isEmpty else { throw SonioxSTTError.noAPIKey }

        let url = URL(string: AppConfig.sonioxWebSocketURL)!
        var request = URLRequest(url: url)
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")

        let session = URLSession(configuration: .default)
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        // Send configuration
        let config: [String: Any] = [
            "model": AppConfig.sonioxModel,
            "language_hints": ["vi", "en"],
            "include_nonfinal": true
        ]
        let configData = try JSONSerialization.data(withJSONObject: config)
        let configString = String(data: configData, encoding: .utf8)!
        try await webSocketTask?.send(.string(configString))

        isActive = true

        // Start receiving messages
        Task { await receiveMessages() }

        // Start audio capture and send PCM data
        startAudioCapture()
    }

    func stop() {
        isActive = false
        audioEngine.removeTap()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
    }

    func reset() {
        accumulatedText = ""
    }

    private func startAudioCapture() {
        guard let pcmFormat = audioEngine.pcm16Format() else { return }

        let converter = AVAudioConverter(from: audioEngine.inputFormat, to: pcmFormat)

        audioEngine.installTap(bufferSize: 4096) { [weak self] buffer, _ in
            guard let self, self.isActive, let converter else { return }

            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * pcmFormat.sampleRate / buffer.format.sampleRate
            )
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: frameCount) else { return }

            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)

            if error == nil, let channelData = convertedBuffer.int16ChannelData {
                let data = Data(bytes: channelData[0], count: Int(convertedBuffer.frameLength) * 2)
                self.webSocketTask?.send(.data(data)) { _ in }
            }
        }

        try? audioEngine.start()
    }

    private func receiveMessages() async {
        while isActive {
            guard let message = try? await webSocketTask?.receive() else { break }

            switch message {
            case .string(let text):
                processResponse(text)
            case .data:
                break
            @unknown default:
                break
            }
        }
    }

    private func processResponse(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        // Parse Soniox response format
        if let tokens = json["tokens"] as? [[String: Any]] {
            var finalText = ""
            var nonFinalText = ""

            for token in tokens {
                let text = token["text"] as? String ?? ""
                let isFinal = token["is_final"] as? Bool ?? false

                if isFinal {
                    finalText += text
                } else {
                    nonFinalText += text
                }
            }

            if !finalText.isEmpty {
                accumulatedText += finalText
            }

            let fullText = accumulatedText + nonFinalText
            let result = STTResult(
                text: fullText,
                isFinal: !finalText.isEmpty,
                newWords: finalText
            )
            continuation?.yield(result)
        }
    }
}
