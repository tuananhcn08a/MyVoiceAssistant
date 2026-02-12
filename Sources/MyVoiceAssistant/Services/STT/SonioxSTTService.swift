import Foundation
import AVFoundation

enum SonioxSTTError: Error {
    case noAPIKey
    case connectionFailed(Error)
    case connectionTimeout
    case invalidResponse
    case audioConversionFailed
    case audioSendFailed(Error)
    case configSendFailed(Error)
}

final class SonioxSTTService: NSObject, STTService, URLSessionWebSocketDelegate, @unchecked Sendable {
    private let audioEngine: AudioEngine
    private let apiKey: String
    private var webSocketTask: URLSessionWebSocketTask?
    private var webSocketSession: URLSession?
    private var continuation: AsyncStream<STTResult>.Continuation?
    private var connectionContinuation: CheckedContinuation<Void, Error>?
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

        super.init()
    }

    func start() async throws {
        guard !apiKey.isEmpty else { throw SonioxSTTError.noAPIKey }

        // Debug: Print API key prefix
        let keyPrefix = apiKey.prefix(8)
        print("SonioxSTT: Using API key: \(keyPrefix)...")

        let url = URL(string: AppConfig.sonioxWebSocketURL)!
        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        // Configure session with delegate
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 10
        config.timeoutIntervalForResource = 30
        let session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        self.webSocketSession = session

        print("SonioxSTT: Connecting to \(url.absoluteString)...")
        webSocketTask = session.webSocketTask(with: request)
        webSocketTask?.resume()

        // Wait for connection to establish (with timeout)
        do {
            try await withTimeout(seconds: 10) {
                try await withCheckedThrowingContinuation { continuation in
                    self.connectionContinuation = continuation
                }
            }
            print("SonioxSTT: Connected to server")
        } catch {
            print("SonioxSTT: Connection failed: \(error.localizedDescription)")
            throw SonioxSTTError.connectionFailed(error)
        }

        // Send configuration after connection confirmed
        do {
            try await sendConfiguration()
            print("SonioxSTT: Configuration sent")
        } catch {
            throw SonioxSTTError.configSendFailed(error)
        }

        isActive = true

        // Start receiving messages
        Task { await receiveMessages() }

        // Start audio capture and send PCM data
        do {
            try startAudioCapture()
            print("SonioxSTT: Audio capture started")
        } catch {
            throw SonioxSTTError.connectionFailed(error)
        }
    }

    private func sendConfiguration() async throws {
        let configMessage: [String: Any] = [
            "api_key": apiKey,
            "model": AppConfig.sonioxModel,
            "audio_format": "pcm_s16le",
            "sample_rate": 16000,
            "num_channels": 1,
            "language_hints": ["en", "vi"],
            "enable_language_identification": true,
            "max_endpoint_delay_ms": 2000
        ]

        let configData = try JSONSerialization.data(withJSONObject: configMessage, options: .prettyPrinted)
        guard let configString = String(data: configData, encoding: .utf8) else {
            throw SonioxSTTError.invalidResponse
        }

        // Debug: Print full config JSON
        print("SonioxSTT: Sending config JSON:")
        print(configString)

        try await webSocketTask?.send(.string(configString))
    }

    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw SonioxSTTError.connectionTimeout
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }

    func stop() {
        isActive = false
        audioEngine.removeTap()
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        webSocketSession?.invalidateAndCancel()
        webSocketSession = nil
        print("SonioxSTT: Stopped")
    }

    func reset() {
        accumulatedText = ""
    }

    private func startAudioCapture() throws {
        guard let pcmFormat = audioEngine.pcm16Format() else {
            throw SonioxSTTError.audioConversionFailed
        }

        guard let converter = AVAudioConverter(from: audioEngine.inputFormat, to: pcmFormat) else {
            throw SonioxSTTError.audioConversionFailed
        }

        audioEngine.installTap(bufferSize: 4096) { [weak self] buffer, _ in
            guard let self, self.isActive else { return }

            let frameCount = AVAudioFrameCount(
                Double(buffer.frameLength) * pcmFormat.sampleRate / buffer.format.sampleRate
            )
            guard let convertedBuffer = AVAudioPCMBuffer(pcmFormat: pcmFormat, frameCapacity: frameCount) else {
                print("SonioxSTT: Failed to create converted buffer")
                return
            }

            var error: NSError?
            let inputBlock: AVAudioConverterInputBlock = { _, outStatus in
                outStatus.pointee = .haveData
                return buffer
            }
            converter.convert(to: convertedBuffer, error: &error, withInputFrom: inputBlock)

            if let conversionError = error {
                print("SonioxSTT: Audio conversion error: \(conversionError.localizedDescription)")
                return
            }

            guard let channelData = convertedBuffer.int16ChannelData else {
                print("SonioxSTT: No channel data in converted buffer")
                return
            }

            let data = Data(bytes: channelData[0], count: Int(convertedBuffer.frameLength) * 2)
            self.webSocketTask?.send(.data(data)) { sendError in
                if let sendError {
                    print("SonioxSTT: Audio send error: \(sendError.localizedDescription)")
                }
            }
        }

        try audioEngine.start()
    }

    private func receiveMessages() async {
        while isActive {
            do {
                guard let message = try await webSocketTask?.receive() else {
                    print("SonioxSTT: WebSocket task is nil")
                    break
                }

                switch message {
                case .string(let text):
                    processResponse(text)
                case .data:
                    break
                @unknown default:
                    break
                }
            } catch {
                print("SonioxSTT: WebSocket receive error: \(error.localizedDescription)")
                // Report error to the stream
                let errorResult = STTResult(
                    text: "",
                    isFinal: false,
                    newWords: ""
                )
                continuation?.yield(errorResult)
                break
            }
        }
    }

    private func processResponse(_ jsonString: String) {
        guard let data = jsonString.data(using: .utf8) else {
            print("SonioxSTT: Failed to convert response to data")
            return
        }

        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("SonioxSTT: Failed to parse JSON response")
            return
        }

        // Check if session finished
        if let finished = json["finished"] as? Bool, finished {
            print("SonioxSTT: Session finished by server")
            isActive = false
            return
        }

        // Parse Soniox response format
        guard let tokens = json["tokens"] as? [[String: Any]] else {
            // No tokens in this response, could be acknowledgment or status
            return
        }

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

    // MARK: - URLSessionWebSocketDelegate

    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        print("SonioxSTT: WebSocket opened")
        connectionContinuation?.resume()
        connectionContinuation = nil
    }

    nonisolated func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        let reasonString = reason.flatMap { String(data: $0, encoding: .utf8) } ?? "No reason provided"
        let reasonBytes = reason?.map { String(format: "%02x", $0) }.joined(separator: " ") ?? "none"
        print("SonioxSTT: WebSocket closed with code \(closeCode.rawValue)")
        print("SonioxSTT: Close reason: \(reasonString)")
        print("SonioxSTT: Close reason bytes: \(reasonBytes)")
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            print("SonioxSTT: Connection error: \(error.localizedDescription)")
            connectionContinuation?.resume(throwing: error)
            connectionContinuation = nil
        }
    }
}
