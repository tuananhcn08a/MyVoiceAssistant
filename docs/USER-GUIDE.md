# MyVoiceAssistant User Guide

## Overview

MyVoiceAssistant is a macOS menubar app that converts your voice to text and streams it in real-time to Terminal.app. Say "thank you" to press Enter.

## Requirements

- macOS 14 (Sonoma) or later
- Microphone access
- Speech Recognition permission
- Accessibility permission (for keystroke injection)

## Quick Start

1. Launch MyVoiceAssistant — a mic icon appears in the menubar
2. Open Terminal.app
3. Click the mic icon to start listening
4. Speak your command — text streams to Terminal as you talk
5. Say **"thank you"** to press Enter

## Features

### Speech-to-Text Engines

| Engine | Setup | Cost | Accuracy |
|--------|-------|------|----------|
| Apple SFSpeechRecognizer | None (default) | Free | Good |
| Soniox | API key required | Paid | Higher |

### Supported Languages

- English (en-US)
- Vietnamese (vi-VN)

### LLM Correction (Optional)

Enable xAI Grok to automatically correct STT transcription errors before sending to Terminal.

## Permissions

On first launch, you'll be prompted for:

1. **Microphone**: Required for voice input
2. **Speech Recognition**: Required for Apple STT
3. **Accessibility**: Required to send keystrokes to Terminal.app
   - Go to System Settings > Privacy & Security > Accessibility
   - Add MyVoiceAssistant to the allowed list

## Settings

Access settings via the gear icon in the menubar popup:

- **STT Engine**: Switch between Apple and Soniox
- **LLM Correction**: Toggle xAI Grok error correction
- **Stop Word**: Customize the "thank you" trigger (default: "thank you")
- **Language**: Select Vietnamese or English
- **API Keys**: Manage Soniox and xAI API keys

## Build & Install from Source

```bash
# Clone the repository
git clone https://github.com/AceDroidX/MyVoiceAssistant.git
cd MyVoiceAssistant

# Build and create .app bundle
make app

# Install to /Applications
make install
```

Alternatively, build and run directly:
```bash
make run
```
