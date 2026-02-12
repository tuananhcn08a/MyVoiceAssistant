import SwiftUI

@main
struct MyVoiceAssistantApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        MenuBarExtra {
            ContentView(appState: appState)
        } label: {
            Image(systemName: appState.isListening ? "mic.fill" : "mic")
        }
        .menuBarExtraStyle(.window)
    }
}
