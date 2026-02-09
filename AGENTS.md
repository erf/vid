# AGENTS.md

Guide for AI agents working in **vid** — a minimal vim-like text editor in Dart.

## Philosophy

**Minimal and focused.** Don't add formatters/linters/tools that don't exist. Respect existing patterns.

## Commands

```bash
./build.sh              # Build to ~/bin/vid
dart run bin/vid.dart   # Run directly
dart test               # Run tests
dart analyze            # Check code
```

## Project Structure

```
lib/
  actions/         # Action handlers (*Actions classes with static methods)
  types/           # Command types (ActionCommand, MotionCommand, type enums)
  features/        # Feature modules (LSP, cursor position) with Feature interface
  file_buffer/     # Buffer ops split by concern (io, nav, text)
  grapheme/        # Unicode/grapheme utilities
  highlighting/    # Syntax highlighting and themes
  motion/          # Movement operations
  popup/           # Popup UI components
  bindings.dart    # All keybindings - DON'T MODIFY unless requested
  editor.dart      # Main editor class
test/              # Mirrors lib/ structure, *_test.dart files
```

## Critical Invariants

1. **Text ends with `\n`** — `FileBuffer` enforces this. All text must end with newline.

2. **Byte offsets, not char indices** — Cursor, viewport, line offsets are UTF-8 byte offsets.

3. **Cursor at grapheme boundaries** — Never position cursor mid-grapheme cluster.

4. **Lines rebuilt on change** — `FileBuffer.lines` rebuilds after every edit. Don't cache.

5. **Bindings are `const`** — Maps in `bindings.dart` are immutable.

## Conventions

- **Single-letter vars in tests**: `e` = Editor, `f` = FileBuffer
- **Static action classes**: `NormalActions.pasteAfter()`, `OperatorActions.change()`
- **Single quotes**: `'string'` not `"string"`
- **Import order**: dart:, packages, package:vid/, relative

## Testing Pattern

```dart
test('description', () {
  final e = Editor(
    terminal: TestTerminal(width: 80, height: 24),
    redraw: false,
  );
  final f = e.file;
  f.text = 'test\n';
  f.cursor = 0;
  
  e.input('x');
  
  expect(f.text, 'expected\n');
});
```

## References

- `docs/ARCHITECTURE.md` — Technical architecture
- `LSP_FEATURE_PLAN.md` — LSP roadmap
- `config.example.yaml` — Config options
