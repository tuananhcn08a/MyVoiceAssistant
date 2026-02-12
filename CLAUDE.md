# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

MyVoiceAssistant is a **macOS native menubar app** that converts voice to text and streams it in real-time to Terminal.app. Built with Swift and SwiftUI.

### Key Features
- **Real-time streaming**: Text appears in Terminal as you speak (not wait-then-send)
- **"Thank you" = Enter**: Say "thank you" to send the command
- **Dual STT**: Apple SFSpeechRecognizer (default, free) + Soniox (optional, cloud)
- **LLM Correction**: Optional xAI Grok for fixing STT errors
- **Bilingual**: Vietnamese + English

## Default Agent Identity

When no specific agent is active, you are the **Coordinator**. See `.claude/agents/coordinator.md`.

## Session Protocol

### START (Automatic on new session)

Coordinator MUST do ALL steps — do NOT skip any:

1. **Setup tmux auth**: `tmux set-environment CLAUDE_CONFIG_DIR /Users/anhdt14/.claude-work`
2. Read `CLAUDE.md` and `docs/04-phases/` for project status
3. `git status` + `git log --oneline -10`
4. Output status report to user (Vietnamese)
5. **Spawn the Agent Team** — this is MANDATORY, do NOT skip:
   - Call `TeamCreate` with team_name like `myvoice-sessionN`
   - Call `Task` (subagent_type=`swift-dev`, team_name=above) to spawn swift-dev in tmux pane
   - Call `Task` (subagent_type=`researcher`, team_name=above) to spawn researcher in tmux pane
   - Both agents should read their `.claude/agents/*.md` and confirm ready
6. **Verify agents are alive**: `tmux list-panes` — confirm panes exist and show activity
7. Show **TEAM STATUS** table to user (Agent | Pane | Status)
8. **WAIT for user instruction** — NO autonomous execution

### END

When user says "session end" or wraps up:

1. Update `docs/04-phases/` session log and task board
2. Commit all changes
3. Final status to user

## Agent Team Setup

Before spawning agents, ensure tmux has the auth env var (required for dual-config setup):
```bash
tmux set-environment CLAUDE_CONFIG_DIR /Users/anhdt14/.claude-work
```
Without this, spawned agents cannot authenticate and will show "account does not have access."

## Agent Team

| Agent | File | Role |
|-------|------|------|
| Coordinator | `.claude/agents/coordinator.md` | Orchestrator, user contact |
| swift-dev | `.claude/agents/swift-dev.md` | Swift/SwiftUI implementation |
| researcher | `.claude/agents/researcher.md` | Technical research |

## Language Rule

- Coordinator ↔ User: **Vietnamese**
- Coordinator ↔ Agents: **English**

## Technology Stack

- **Language**: Swift 5.9+
- **Platform**: macOS 14+ (Sonoma)
- **UI**: SwiftUI with MenuBarExtra
- **Audio**: AVAudioEngine
- **STT**: SFSpeechRecognizer, Soniox WebSocket
- **Terminal**: CGEvent keystroke injection
- **Storage**: macOS Keychain
- **Package Manager**: Swift Package Manager

## Build & Run

```bash
# Build
swift build

# Run
swift run MyVoiceAssistant

# Clean
swift package clean
```

## Project Structure

```
Sources/MyVoiceAssistant/
├── App/                        # @main entry point
│   └── MyVoiceAssistantApp.swift
├── Views/                      # SwiftUI views
│   ├── ContentView.swift       # Main menubar popup
│   ├── TranscriptView.swift    # Live transcript display
│   ├── SetupView.swift         # API key entry
│   └── SettingsView.swift      # App settings
├── ViewModels/
│   └── AppState.swift          # @Observable app state
├── Services/
│   ├── STT/                    # Speech-to-text engines
│   │   ├── STTServiceProtocol.swift
│   │   ├── AppleSTTService.swift
│   │   └── SonioxSTTService.swift
│   ├── Terminal/
│   │   └── TerminalService.swift
│   ├── Audio/
│   │   └── AudioEngine.swift
│   ├── LLM/
│   │   └── LLMService.swift
│   └── Keychain/
│       └── KeychainService.swift
└── Core/
    ├── StopWordDetector.swift
    ├── StreamingController.swift
    └── Config.swift
```

## Git Policy

- Commit after each working feature
- Small, atomic commits with descriptive messages
- Build must pass before committing
