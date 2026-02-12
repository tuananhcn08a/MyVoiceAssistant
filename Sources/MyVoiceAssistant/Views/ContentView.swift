import SwiftUI
import AppKit

enum MenuView {
    case main
    case settings
    case setup
}

struct ContentView: View {
    @Bindable var appState: AppState
    @State private var currentView: MenuView = .main

    var body: some View {
        Group {
            switch currentView {
            case .main:
                mainView
            case .settings:
                SettingsView(appState: appState, currentView: $currentView)
            case .setup:
                SetupView(currentView: $currentView)
            }
        }
        .frame(width: 320)
        .background(WindowAccessor { window in
            window.hidesOnDeactivate = false
            window.level = .floating
        })
    }

    private var mainView: some View {
        VStack(spacing: 12) {
            // Header
            HStack {
                Text("MyVoiceAssistant")
                    .font(.headline)
                Spacer()
                engineBadge
            }

            // Transcript
            TranscriptView(
                finalText: appState.transcript,
                interimText: appState.interimText
            )

            // Mic button
            Button(action: {
                Task { await appState.toggleListening() }
            }) {
                HStack {
                    Image(systemName: appState.isListening ? "mic.fill" : "mic")
                        .foregroundStyle(appState.isListening ? .red : .primary)
                    Text(appState.isListening ? "Stop" : "Start Listening")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(.borderedProminent)
            .tint(appState.isListening ? .red : .accentColor)

            // Status
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Text(appState.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            // Error
            if let error = appState.errorMessage {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            // Bottom actions
            HStack {
                Button(action: { appState.resetTranscript() }) {
                    Label("Clear", systemImage: "trash")
                        .font(.caption)
                }
                .buttonStyle(.borderless)

                Spacer()

                Button(action: { currentView = .settings }) {
                    Label("Settings", systemImage: "gear")
                        .font(.caption)
                }
                .buttonStyle(.borderless)

                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Label("Quit", systemImage: "power")
                        .font(.caption)
                }
                .buttonStyle(.borderless)
            }
        }
        .padding()
    }

    private var engineBadge: some View {
        Text(appState.selectedEngine.rawValue)
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(.fill.tertiary)
            .clipShape(Capsule())
    }

    private var statusColor: Color {
        if appState.isListening {
            return .green
        } else if appState.errorMessage != nil {
            return .red
        } else {
            return .gray
        }
    }
}

// MARK: - Window Accessor
struct WindowAccessor: NSViewRepresentable {
    let configure: (NSWindow) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            if let window = view.window {
                configure(window)
            }
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {}
}
