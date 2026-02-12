# Architecture Overview

## System Design

```
┌─────────────────────────────────────────────────┐
│                  MyVoiceAssistant                │
│                                                  │
│  ┌──────────┐    ┌──────────────┐               │
│  │ MenuBar  │◄──►│   AppState   │               │
│  │   UI     │    │ (@Observable)│               │
│  └──────────┘    └──────┬───────┘               │
│                         │                        │
│         ┌───────────────┼───────────────┐       │
│         ▼               ▼               ▼       │
│  ┌─────────────┐ ┌──────────────┐ ┌──────────┐ │
│  │ AudioEngine │ │ STTService   │ │ Terminal  │ │
│  │ (mic input) │─►│(Apple/Soniox)│─►│ Service  │ │
│  └─────────────┘ └──────────────┘ └──────────┘ │
│                         │                        │
│                  ┌──────┴───────┐               │
│                  ▼              ▼               │
│           ┌───────────┐ ┌────────────┐         │
│           │ StopWord  │ │ Streaming  │         │
│           │ Detector  │ │ Controller │         │
│           └───────────┘ └────────────┘         │
│                                                  │
│  Optional:                                       │
│  ┌──────────┐  ┌───────────────┐               │
│  │ Keychain │  │  LLMService   │               │
│  │ Service  │  │ (xAI Grok)    │               │
│  └──────────┘  └───────────────┘               │
└─────────────────────────────────────────────────┘
```

## Data Flow

1. **AudioEngine** captures microphone input (AVAudioEngine)
2. Audio buffers feed into **STTService** (Apple or Soniox)
3. STTService emits `STTResult` via `AsyncStream`
4. **StreamingController** receives results, computes diff
5. **StopWordDetector** checks for "thank you"
6. **TerminalService** sends keystrokes to Terminal.app via CGEvent

## Key Patterns

- **Protocol-oriented**: `STTService` protocol enables engine swapping
- **@Observable**: AppState drives UI updates
- **AsyncStream**: STT results flow via structured concurrency
- **Diff-based streaming**: Only new characters are sent to Terminal

## Permissions

| Permission | Framework | Check |
|-----------|-----------|-------|
| Microphone | AVFoundation | `AVCaptureDevice.requestAccess` |
| Speech | Speech | `SFSpeechRecognizer.requestAuthorization` |
| Accessibility | ApplicationServices | `AXIsProcessTrusted()` |
