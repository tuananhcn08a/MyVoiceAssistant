import SwiftUI

struct SetupView: View {
    @Binding var currentView: MenuView
    @State private var sonioxKey = ""
    @State private var xaiKey = ""
    @State private var saveError: String?

    var body: some View {
        VStack(spacing: 16) {
            Text("API Key Setup")
                .font(.title2)

            Text("Both keys are optional. Apple STT works without any keys.")
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                Text("Soniox API Key")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("sk-...", text: $sonioxKey)
                    .textFieldStyle(.roundedBorder)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("xAI (Grok) API Key")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                SecureField("xai-...", text: $xaiKey)
                    .textFieldStyle(.roundedBorder)
            }

            if let error = saveError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            HStack {
                Button("Cancel") {
                    currentView = .settings
                }
                .buttonStyle(.bordered)
                Spacer()
                Button("Save") { saveKeys() }
                    .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .onAppear { loadExistingKeys() }
    }

    private func loadExistingKeys() {
        sonioxKey = (try? KeychainService.read(key: "apiKey", service: AppConfig.sonioxAPIKeyService)) ?? ""
        xaiKey = (try? KeychainService.read(key: "apiKey", service: AppConfig.xaiAPIKeyService)) ?? ""
    }

    private func saveKeys() {
        do {
            if !sonioxKey.isEmpty {
                try KeychainService.save(key: "apiKey", value: sonioxKey, service: AppConfig.sonioxAPIKeyService)
            }
            if !xaiKey.isEmpty {
                try KeychainService.save(key: "apiKey", value: xaiKey, service: AppConfig.xaiAPIKeyService)
            }
            currentView = .settings
        } catch {
            saveError = "Failed to save: \(error.localizedDescription)"
        }
    }
}
