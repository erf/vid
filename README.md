# vid

A minimal vim-like text editor for modern terminals written in Dart 🧑‍💻

> Note: made for myself for fun and learning and not meant to replace your current editor 😅

## Features 📋

- a minimal vim-like text editor for the terminal ⚡️
- properly render and edit emojis and wide characters 🍜
- made for modern terminals that supports [mode 2027](https://github.com/contour-terminal/terminal-unicode-core) (e.g. [Ghostty](https://github.com/mitchellh/ghostty/), [WezTerm](https://github.com/wez/wezterm)) 🧠
- written in Dart using the [characters](https://pub.dev/packages/characters) package ✨
- unlimited undo and redo ↩️
- no-wrap, char-wrap or word-wrap 🎁
- most **vim** motions and operations covered ⚙️

## Non-goals ❌

- no syntax highlighting (only bg / fg colors)
- no plugins (let's keep things minimal)
- no 100 % vim compat (we support a minimal subset)
- no window manager (just open a new tab, use terminal split features etc.)
- no pre-built binaries ([build](build.sh) it yourself using Dart)

## Keyboard shortcuts ↔️

See [bindings.dart](lib/bindings.dart)

## Configuration 📜

See [config.dart](lib/config.dart)

## Contributing 🙋‍♂️

I enjoy building [vid](https://github.com/erf/vid) myself but I'm open to pull requests that align with its minimal philosophy.

I don't accept issues solely for suggestions.

Enjoy ✨
