# Phase 1 MVP — Release Notes

**Version**: 1.0.0
**Build Date**: 2026-02-13
**Commit**: See `git log` at time of Phase 1 close

## What's Included

### Core Features
- **Real-time voice-to-Terminal streaming** — text appears as you speak, diff-based (only new characters sent)
- **"Thank you" = Enter** — configurable stop word triggers keystroke
- **Apple SFSpeechRecognizer** — default STT engine, free, no setup required
- **Soniox STT** — cloud-based alternative with higher accuracy (API key required)
- **Bilingual support** — Vietnamese (vi-VN) and English (en-US)
- **LLM correction** — optional xAI Grok integration to fix transcription errors
- **Menubar app** — LSUIElement, no Dock icon, always accessible from menubar

### UI
- MenuBarExtra with mic icon
- Live transcript view
- Settings view (STT engine, language, stop word, LLM toggle)
- Setup view (API key entry for Soniox / xAI)

### Infrastructure
- CGEvent keystroke injection with Unicode support (Vietnamese diacritics)
- AVAudioEngine audio capture
- Soniox WebSocket with PCM16 audio conversion
- macOS Keychain for secure API key storage
- SFSpeechRecognizer auto-restart on 60-second limit

## Stats
- **16 Swift source files**, ~1,426 LOC
- **App bundle size**: ~608K
- **Build time**: ~7s (release)

## Known Issues / Limitations
- Accessibility permission must be granted manually by user
- SFSpeechRecognizer has 60-second recognition limit (auto-restart implemented, needs real-world testing)
- End-to-end integration testing not yet done (T-017, moved to Phase 2)
- No app icon (uses default)

## Build Instructions

To reproduce this build:

```bash
git checkout <phase-1-close-commit>
make app
# Output: build/MyVoiceAssistant.app
```

## Requirements
- macOS 14 (Sonoma) or later
- Xcode Command Line Tools
- Microphone, Speech Recognition, and Accessibility permissions
