# ADR-001: STT Engine Selection

## Status
Accepted

## Context
We need speech-to-text for a macOS voice assistant that supports Vietnamese and English, with real-time streaming capability.

## Options Considered

### 1. Apple SFSpeechRecognizer (Selected as Default)
- **Pros**: Free, no API key, built into macOS, supports vi-VN and en-US, partial results
- **Cons**: 60-second recognition limit, lower accuracy for mixed-language, requires internet for some features
- **Complexity**: Low

### 2. Soniox WebSocket API (Selected as Optional)
- **Pros**: Higher accuracy, bilingual context injection, no time limit, proven in reference app
- **Cons**: Requires API key, costs money, network dependency
- **Complexity**: Medium

### 3. OpenAI Whisper (Rejected)
- **Pros**: High accuracy, multilingual
- **Cons**: Not real-time streaming (batch only), requires API key
- **Complexity**: Medium

### 4. Google Cloud Speech-to-Text (Rejected)
- **Pros**: High accuracy, streaming support
- **Cons**: Complex setup, higher cost, heavier SDK
- **Complexity**: High

## Decision
- **Default**: Apple SFSpeechRecognizer — zero setup, free, good enough for most use cases
- **Optional upgrade**: Soniox — for users who want higher accuracy and are willing to pay

## Consequences
- Must handle SFSpeechRecognizer's 60-second limit with auto-restart
- Must define STTService protocol so engines are swappable
- Soniox requires WebSocket implementation and API key storage
