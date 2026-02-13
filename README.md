# MyVoiceAssistant

A macOS native menubar app that converts voice to text and streams it in real-time to Terminal.app. Speak your commands naturally — text appears as you talk, and say **"thank you"** to press Enter.

<!-- ![Screenshot](docs/assets/screenshot.png) -->

## Features

- **Real-time streaming** — text appears in Terminal as you speak, not after you finish
- **Dual STT engines** — Apple SFSpeechRecognizer (free, default) or Soniox (cloud, higher accuracy)
- **Bilingual** — Vietnamese and English
- **LLM correction** — optional xAI Grok integration to fix STT transcription errors
- **"Thank you" = Enter** — natural stop word triggers command execution
- **Menubar app** — lives in your menubar, no Dock icon, always accessible

## Requirements

- macOS 14 (Sonoma) or later
- Xcode Command Line Tools (`xcode-select --install`)
- Microphone permission
- Speech Recognition permission
- Accessibility permission (for keystroke injection to Terminal)

## Quick Start

```bash
# Clone
git clone https://github.com/AceDroidX/MyVoiceAssistant.git
cd MyVoiceAssistant

# Build and run
make run
```

## Build & Install

```bash
# Build release binary
make build

# Create .app bundle
make app

# Install to /Applications
make install

# Clean build artifacts
make clean
```

The `make app` command creates `build/MyVoiceAssistant.app` — a proper macOS app bundle you can double-click or drag to Applications.

## Permissions Setup

On first launch, grant these permissions in **System Settings > Privacy & Security**:

1. **Microphone** — required for voice input
2. **Speech Recognition** — required for Apple STT engine
3. **Accessibility** — required to send keystrokes to Terminal.app
   - System Settings > Privacy & Security > Accessibility > add MyVoiceAssistant

## Configuration

### STT Engine

| Engine | Setup | Cost | Accuracy |
|--------|-------|------|----------|
| Apple SFSpeechRecognizer | None (default) | Free | Good |
| Soniox | API key required | Paid | Higher |

Switch engines in the app's Settings view. For Soniox, enter your API key in the Setup view.

### LLM Correction (Optional)

Enable xAI Grok in Settings to automatically correct STT transcription errors before sending to Terminal. Requires an xAI API key.

## Project Structure

```
Sources/MyVoiceAssistant/
├── App/                    # @main entry point
├── Views/                  # SwiftUI views (ContentView, Settings, Setup, Transcript)
├── ViewModels/             # @Observable app state
├── Services/
│   ├── STT/                # Speech-to-text (Apple + Soniox)
│   ├── Terminal/            # CGEvent keystroke injection
│   ├── Audio/               # AVAudioEngine capture
│   ├── LLM/                 # xAI Grok correction
│   └── Keychain/            # Secure API key storage
└── Core/                   # StopWordDetector, StreamingController, Config
```

See [docs/](docs/) for detailed architecture and specifications.

## Tech Stack

- **Swift 5.9+** / **SwiftUI** / **macOS 14+**
- AVAudioEngine for audio capture
- SFSpeechRecognizer + Soniox WebSocket for STT
- CGEvent for Terminal keystroke injection
- macOS Keychain for secure storage

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/my-feature`)
3. Make your changes and ensure `swift build` passes
4. Commit with descriptive messages
5. Push and open a Pull Request

## License

This project is licensed under the MIT License — see the [LICENSE](LICENSE) file for details.
