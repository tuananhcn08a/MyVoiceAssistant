# Terminal Integration — Domain Logic

## Keystroke Injection via CGEvent

### Why CGEvent?
- `keyboardSetUnicodeString` supports full Unicode (Vietnamese diacritics)
- Faster than AppleScript `keystroke` command
- No scripting entitlement needed
- Works with any text field in any application

### Implementation

#### Send Text
```
For each character in text:
  1. Create CGEvent(.keyDown)
  2. Set keyboardSetUnicodeString with the character
  3. Post event to Terminal.app's process
  4. Create CGEvent(.keyUp) and post
```

#### Send Return
```
1. Create CGEvent(.keyDown) with keyCode 36 (Return)
2. Post to Terminal.app
3. Create CGEvent(.keyUp) and post
```

#### Send Backspace
```
For count times:
  1. Create CGEvent(.keyDown) with keyCode 51 (Delete)
  2. Post to Terminal.app
  3. Create CGEvent(.keyUp) and post
```

### Terminal.app Focus

Before sending keystrokes:
1. Find Terminal.app via NSRunningApplication
2. Activate it (bring to front)
3. Brief delay to ensure focus
4. Send keystrokes

### Accessibility Permission

- Check via `AXIsProcessTrusted()`
- If not trusted, prompt user with `AXIsProcessTrustedWithOptions`
- Required for CGEvent posting to other applications
