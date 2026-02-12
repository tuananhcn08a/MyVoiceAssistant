# Codebase Documentation

## Source Structure

```
Sources/MyVoiceAssistant/
├── App/                        # Application entry point
│   └── MyVoiceAssistantApp.swift
├── Views/                      # SwiftUI views
│   ├── ContentView.swift       # Main menubar popup
│   ├── TranscriptView.swift    # Live transcript display
│   ├── SetupView.swift         # API key entry
│   └── SettingsView.swift      # App settings
├── ViewModels/                 # State management
│   └── AppState.swift          # @Observable app state
├── Services/                   # Business logic
│   ├── STT/                    # Speech-to-text engines
│   ├── Terminal/               # Keystroke injection
│   ├── Audio/                  # Microphone capture
│   ├── LLM/                    # AI correction
│   └── Keychain/               # Secure storage
└── Core/                       # Shared utilities
    ├── StopWordDetector.swift
    ├── StreamingController.swift
    └── Config.swift
```

See [Architecture Overview](architecture-overview.md) for detailed design.
