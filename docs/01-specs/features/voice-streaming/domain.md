# Voice Streaming — Domain Logic

## Core Algorithm: Diff-Based Streaming

### State
- `lastSentText: String` — what has been typed into Terminal so far

### On New STT Result

```
1. Check stop word ("thank you") at end of text
2. If stop word detected:
   a. Extract command (text minus stop word)
   b. Calculate new characters: command.dropFirst(lastSentText.count)
   c. Send new characters to Terminal
   d. Send Return key
   e. Reset lastSentText = ""
   f. Reset STT for next command
3. If no stop word:
   a. Calculate new characters: text.dropFirst(lastSentText.count)
   b. If text starts with lastSentText (no revision):
      - Send only new characters
      - Update lastSentText = text
   c. If text doesn't start with lastSentText (revision occurred):
      - Send backspaces to delete divergent portion
      - Send corrected text
      - Update lastSentText = text
```

### Revision Handling

SFSpeechRecognizer may revise partial results. Strategy:
- Track what was sent vs what STT now reports
- Use backspaces to correct Terminal when revision occurs
- Prefer streaming only `isFinal` segments for stability

## Stop Word Detection

- Normalize: lowercase, strip trailing punctuation
- Match: "thank you", "cảm ơn" at end of transcript
- Return tuple: (detected: Bool, command: String)
- Command = original text with stop word removed and trimmed

## STT Service Contract

All STT engines must conform to:
- Emit `STTResult` via `AsyncStream`
- Support start/stop/reset lifecycle
- Provide partial and final results
