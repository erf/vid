# vid

A minimal vim-like text editor for modern terminals written in [Dart](https://dart.dev)

> Made for myself for fun and learning and not meant to replace your current editor

## Features ✨

- basic vim motions, operators and a minimal command mode
- render and edit emojis and wide characters
- unlimited undo (u) and redo (U)
- text wrap modes: no-wrap, character-wrap, word-wrap (ctrl-w)
- syntax highlighting (Dart, Yaml, Markdown, JSON) (zh, zt)
- remember previous cursor position

## Technical Details 🛠️

- written in [Dart](https://dart.dev) using only my own [termio](https://pub.dev/packages/termio) package and the [characters](https://pub.dev/packages/characters) package for handling grapheme clusters
- built for modern terminals like [Ghostty](https://github.com/ghostty-org/ghostty) that support [mode 2027](https://github.com/contour-terminal/terminal-unicode-core) 

## Keyboard Shortcuts

See [bindings.dart](lib/bindings.dart) for the full list of vim-like key mappings.

## Configuration

See [config.dart](lib/config.dart)

## Contributing

I'm open to PR's that align with vid's minimal philosophy.

I don't accept issues solely for suggestions.
