# Voice Streaming — UI/UX Spec

## Overview

Real-time voice-to-text streaming from microphone to Terminal.app.

## User Flow

1. User clicks menubar mic icon → recording starts
2. User speaks → text appears character-by-character in Terminal
3. User says "thank you" → Enter key is sent, ready for next command
4. User clicks mic icon again → recording stops

## UI Elements

### Menubar Icon
- **Idle**: Gray microphone icon
- **Recording**: Red/active microphone icon

### Popup Window
- Live transcript display (current recognition text)
- Final text in black, interim/partial text in gray
- Status indicator: "Listening...", "Idle", or error message
- STT engine badge (Apple/Soniox)

## Behaviors

- Text streams to Terminal as spoken (not after completion)
- "Thank you" at end of phrase triggers Enter key
- STT auto-restarts on 60-second Apple limit
- Corrections: if STT revises text, backspaces are sent to fix Terminal
