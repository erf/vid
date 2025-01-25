# vid

A minimal vim-like text editor for modern terminals written in [Dart](https://dart.dev/overview)

> Made for myself for fun and learning and not meant to replace your current editor

## Features

- a minimal vim-like text editor for the terminal
- properly render and edit emojis and wide characters (like 🧑‍🧑‍🧒‍🧒)
- made for modern terminals that supports [mode 2027](https://github.com/contour-terminal/terminal-unicode-core) (e.g. [Ghostty](https://github.com/ghostty-org/ghostty), [WezTerm](https://github.com/wez/wezterm))
- written in Dart using the [characters](https://pub.dev/packages/characters) package
- unlimited undo and redo
- no-wrap, char-wrap or word-wrap
- basic vim motions and operators
- minimal command mode

## Non-goals ❌

- syntax highlighting
- plugins
- 100 % vim compat
- window manager (just open a new tab or use terminal split features)
- pre-built binaries (just build it yourself)

## Keyboard shortcuts

See [bindings.dart](lib/bindings.dart)

## Configuration

See [config.dart](lib/config.dart)

## Contributing

I'm open to PR's that align with vid's minimal philosophy.

I don't accept issues solely for suggestions.
