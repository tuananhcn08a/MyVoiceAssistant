# Terminal Integration — UI/UX Spec

## Overview

Send keystrokes to Terminal.app in real-time, simulating user typing.

## Target Application

- **Terminal.app** (macOS built-in)
- Must be running and have an active window

## Behaviors

### Text Streaming
- Characters appear in Terminal as if typed by user
- Supports full Unicode (Vietnamese diacritics: ă, â, ê, ô, ơ, ư, đ)
- No visible delay between voice and Terminal output

### Enter Key
- Triggered by stop word detection ("thank you")
- Sends Return key (CGKeyCode 36)
- Equivalent to user pressing Enter

### Corrections
- When STT revises text, backspaces are sent to delete incorrect characters
- Then correct text is typed

## Error States

- Terminal.app not running → show error in menubar popup
- Accessibility permission not granted → prompt user to enable
