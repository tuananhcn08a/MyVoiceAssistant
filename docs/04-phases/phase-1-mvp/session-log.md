# Phase 1 MVP — Session Log

## Session 2 — UI Fix + Soniox Debug

**Date**: 2026-02-12
**Agent**: Coordinator + swift-dev + researcher (tmux agent team)

### Accomplished
- **Tmux agent team setup**: Adopted pattern from myYoutubePostcastApp, updated CLAUDE.md + coordinator.md
- **MenuBarExtra dismiss fix**: Replaced `.sheet` with inline view switching (enum MenuView) — sheets are fundamentally broken in MenuBarExtra
- **Soniox error handling**: Replaced all silent `try?` with proper `do/catch`, added console logging
- **Soniox WebSocket delegate**: Added URLSessionWebSocketDelegate to wait for handshake before sending
- **Settings persistence**: Added UserDefaults for selectedEngine, selectedLanguage, stopWord, isLLMEnabled
- **Soniox config debug**: Identified root cause of server rejection (code 1000)

### Bug Found (T-024)
- Soniox server rejects config due to extra fields (`enable_language_identification`, `max_endpoint_delay_ms`)
- Working config found in `/Volumes/Extend_Disk/Ext_Download/voice-terminal-main`
- Fix: remove extra fields, add `language_hints_strict: true`, order `["vi", "en"]`

### Files Modified
- `CLAUDE.md` — added tmux setup to session protocol
- `.claude/agents/coordinator.md` — added tmux setup steps
- `Sources/MyVoiceAssistant/Views/ContentView.swift` — inline view switching, WindowAccessor
- `Sources/MyVoiceAssistant/Views/SettingsView.swift` — binding-based navigation
- `Sources/MyVoiceAssistant/Views/SetupView.swift` — binding-based navigation
- `Sources/MyVoiceAssistant/Services/STT/SonioxSTTService.swift` — error handling, delegate, debug logs
- `Sources/MyVoiceAssistant/ViewModels/AppState.swift` — UserDefaults persistence

### Next Steps
- T-024: Fix Soniox config (remove extra fields, match voice-terminal format)
- T-017: End-to-end testing with microphone

---

## Session 1 — Full Implementation

**Date**: 2026-02-12
**Agent**: Coordinator (direct implementation, no sub-agents spawned)

### Accomplished
- **Phase 0 complete**: Agent teams infrastructure, documentation scaffold, Xcode project setup
- **Phase 1 complete**: All MVP source code implemented
- **Phase 2 complete**: All enhanced features implemented (Soniox, Keychain, LLM, Settings)
- **Build passing**: `swift build` succeeds (9.16s)

### Files Created (37 total)
- 4 agent/config files (.claude/)
- 1 CLAUDE.md (updated)
- 14 documentation files (docs/)
- 1 Package.swift
- 1 Info.plist
- 16 Swift source files

### Key Implementation Details
- macOS 14+ target (for @Observable)
- CGEvent + keyboardSetUnicodeString for Unicode-safe keystroke injection
- Diff-based streaming: only new chars sent, backspace correction for revisions
- STTService protocol with AsyncStream for engine swapping
- Apple SFSpeechRecognizer with auto-restart on 60s limit
- Soniox WebSocket with PCM16 audio conversion
- LLMService using xAI Grok (OpenAI-compatible endpoint)
- KeychainService for secure API key storage
- MenuBarExtra with .window style (LSUIElement = true)

### Known Issues
- T-017 (end-to-end testing) requires manual testing with microphone
- T-023 (error handling polish) not yet done — basic error handling is in place
- Accessibility permission must be granted manually by user
- SFSpeechRecognizer 60-second limit auto-restart implemented but needs real-world testing

### Next Steps
- Manual testing: launch app, test voice → Terminal streaming
- Test Vietnamese diacritics (ă, â, ê, ô, ơ, ư, đ)
- Test "thank you" stop word detection
- Test Soniox STT with API key
- Polish error handling edge cases
