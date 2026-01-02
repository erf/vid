# vid

A minimal vim-like text editor for modern terminals written in [Dart](https://dart.dev)

> Made for myself for fun and learning (not meant to replace your current editor)

## Features

- basic vim motions, operators and a minimal command mode
- render and edit emojis and wide characters
- syntax highlighting (dart, lua, yaml, md, json)
- LSP support for Dart and Lua (semantic highlighting, go-to-definition, find references, completion, hover)
- multi-buffer support
- interactive popup for opening files, buffer selection and diagnostics
- text wrap modes: no-wrap, character-wrap, word-wrap
- unlimited undo and redo

## Technical Details

- for modern terminals like [Ghostty](https://github.com/ghostty-org/ghostty) that support [mode 2027](https://github.com/contour-terminal/terminal-unicode-core) 
- only dependencies are [termio](https://github.com/erf/termio) and [characters](https://pub.dev/packages/characters)

## Keyboard Shortcuts

See [bindings.dart](lib/bindings.dart) for the full list of vim-like key mappings.

## Configuration

See [config.dart](lib/config.dart)

## Contributing

I'm open to PR's that align with vid's minimal philosophy.

I don't accept issues solely for suggestions.
