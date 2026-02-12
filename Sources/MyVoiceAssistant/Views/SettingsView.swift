import SwiftUI

struct SettingsView: View {
    @Bindable var appState: AppState
    @Binding var currentView: MenuView

    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.title2)

            // STT Engine
            VStack(alignment: .leading, spacing: 4) {
                Text("Speech-to-Text Engine")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Engine", selection: $appState.selectedEngine) {
                    ForEach(STTEngine.allCases, id: \.self) { engine in
                        Text(engine.rawValue).tag(engine)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()

                if appState.selectedEngine == .soniox && !appState.hasSonioxKey {
                    Text("Soniox requires an API key")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }

            // Language
            VStack(alignment: .leading, spacing: 4) {
                Text("Language")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Picker("Language", selection: $appState.selectedLanguage) {
                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                        Text(lang.displayName).tag(lang)
                    }
                }
                .pickerStyle(.segmented)
                .labelsHidden()
            }

            // LLM Correction
            Toggle("Enable LLM correction (xAI Grok)", isOn: $appState.isLLMEnabled)
                .font(.callout)

            if appState.isLLMEnabled && !appState.hasXAIKey {
                Text("LLM correction requires an xAI API key")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }

            // Stop word
            VStack(alignment: .leading, spacing: 4) {
                Text("Stop Word (triggers Enter)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("thank you", text: $appState.stopWord)
                    .textFieldStyle(.roundedBorder)
            }

            Divider()

            // API Keys
            Button("Manage API Keys...") {
                currentView = .setup
            }
            .buttonStyle(.bordered)

            HStack {
                Spacer()
                Button("Done") {
                    currentView = .main
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
    }
}
