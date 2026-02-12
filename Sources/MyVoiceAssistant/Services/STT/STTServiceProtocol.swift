import Foundation

struct STTResult: Sendable {
    let text: String
    let isFinal: Bool
    let newWords: String

    static let empty = STTResult(text: "", isFinal: false, newWords: "")
}

protocol STTService: AnyObject, Sendable {
    var transcriptStream: AsyncStream<STTResult> { get }
    func start() async throws
    func stop()
    func reset()
}
