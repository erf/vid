# vid

A minimal vim-like text editor for modern terminals written in [Dart](https://dart.dev/overview)

> Made for myself for fun and learning and not meant to replace your current editor

## Features ✨

- Basic vim motions and operators with minimal command mode
- Properly render and edit emojis and wide characters
- Unlimited undo and redo
- Multiple text wrap modes: no-wrap, character-wrap, word-wrap
- Remember last cursor position per file

## Technical Details 🛠️

- Written in Dart using the [characters](https://pub.dev/packages/characters) package for handling grapheme clusters
- Built for modern terminals that support [mode 2027](https://github.com/contour-terminal/terminal-unicode-core) like [Ghostty](https://github.com/ghostty-org/ghostty) and [WezTerm](https://github.com/wez/wezterm)

## Non-goals ❌

- Syntax highlighting
- Plugins
- 100% vim compatibility
- Window manager (just use terminal tabs/splits)

## Keyboard Shortcuts

See [bindings.dart](lib/bindings.dart) for the full list of vim-like key mappings.

## Configuration

See [config.dart](lib/config.dart)

## Contributing

I'm open to PR's that align with vid's minimal philosophy.

I don't accept issues solely for suggestions.
