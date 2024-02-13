# vid

A minimal vi-like text editor for the terminal written in Dart 🧑‍💻
 
> Note: made for myself for fun and learning

## Features 📋

- a minimal vi-like text editor for the terminal ⚡️
- correct rendering and editing of emojis and EastAsianWide 🍜
- made for modern terminals that supports [mode 2027](https://github.com/contour-terminal/terminal-unicode-core) (e.g. [Ghostty](https://github.com/mitchellh/ghostty/), [WezTerm](https://github.com/wez/wezterm)) 🧠
- written in pragmatic Dart using the [characters](https://pub.dev/packages/characters) package ✨
- undo and redo ↩️
- word wrap and no wrap mode 🎁

## Non-goals ❌

- no syntax highlighting (only bg / fg colors)
- no plugins (let's keep things minimal)
- no 100 % vim compat (we support a minimal subset)
- no window manager (just open a new tab, use terminal split features etc.)
- no pre-built binaries ([build](build.sh) it yourself using Dart)

## Keyboard shortcuts ↔️

See [bindings.dart](lib/bindings.dart)

## Configuraion 📜

See [config.dart](lib/config.dart)

## Contributing 🙋‍♂️

I enjoy building [vid](https://github.com/erf/vid) myself but I'm open to pull requests that align with its minimal philosophy.

I don't accept issues solely for suggestions.

Enjoy ✨
