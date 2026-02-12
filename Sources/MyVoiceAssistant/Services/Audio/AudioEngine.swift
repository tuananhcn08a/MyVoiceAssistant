import AVFoundation

enum AudioEngineError: Error {
    case microphonePermissionDenied
    case engineStartFailed(Error)
    case noInputNode
}

final class AudioEngine: @unchecked Sendable {
    private let engine = AVAudioEngine()
    private var isRunning = false

    var inputNode: AVAudioInputNode {
        engine.inputNode
    }

    var inputFormat: AVAudioFormat {
        engine.inputNode.outputFormat(forBus: 0)
    }

    func requestMicrophonePermission() async -> Bool {
        await withCheckedContinuation { continuation in
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                continuation.resume(returning: granted)
            }
        }
    }

    func start() throws {
        guard !isRunning else { return }
        do {
            engine.prepare()
            try engine.start()
            isRunning = true
        } catch {
            throw AudioEngineError.engineStartFailed(error)
        }
    }

    func stop() {
        guard isRunning else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        isRunning = false
    }

    func installTap(bufferSize: AVAudioFrameCount = 1024,
                     format: AVAudioFormat? = nil,
                     block: @escaping (AVAudioPCMBuffer, AVAudioTime) -> Void) {
        let tapFormat = format ?? inputFormat
        engine.inputNode.installTap(onBus: 0, bufferSize: bufferSize, format: tapFormat, block: block)
    }

    func removeTap() {
        engine.inputNode.removeTap(onBus: 0)
    }

    /// Create a PCM16 16kHz mono format suitable for Soniox
    func pcm16Format() -> AVAudioFormat? {
        AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: 16000, channels: 1, interleaved: true)
    }
}
