import SwiftUI

struct TranscriptView: View {
    let finalText: String
    let interimText: String

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 2) {
                if !finalText.isEmpty {
                    Text(finalText)
                        .foregroundStyle(.primary)
                        .font(.system(.body, design: .monospaced))
                }
                if !interimText.isEmpty {
                    Text(interimText)
                        .foregroundStyle(.secondary)
                        .font(.system(.body, design: .monospaced))
                }
                if finalText.isEmpty && interimText.isEmpty {
                    Text("Speak to see transcript...")
                        .foregroundStyle(.tertiary)
                        .font(.system(.body, design: .monospaced))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
        }
        .frame(height: 120)
        .background(.background.secondary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
