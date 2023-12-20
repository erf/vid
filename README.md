# vid

A minimal vi-like text editor for the terminal written in Dart 😎
 
> Note: for fun and learning; not meant to replace your current editor ;)

## Features 📋

- a minimal fast modal vi-like text editor for the terminal ⚡️
- correct rendering, editing and cursor movement of emojis and EastAsianWide ❤️‍🔥
- made for modern terminals that supports [mode 2027](https://github.com/contour-terminal/terminal-unicode-core) (e.g. [Ghostty](https://github.com/mitchellh/ghostty/), [WezTerm](https://github.com/wez/wezterm)) 🧠
- written in pragmatic Dart using the [characters](https://pub.dev/packages/characters) package ✨
- unlimited undo (and redo) ↩️

## Non-goals ❌

- no syntax highlighting (we just use terminal bg / fg colors)
- no plugins (let's keep things minimal)
- no window manager (open a new tab or use terminal split features)
- no 100 % vim compat (we only support a minimal subset)
- no pre-built binaries (just [build](build.sh) it yourself)

## Keyboard shortcuts ↔️

See [bindings.dart](lib/bindings.dart)

## Contributing 🙋‍♂️

I enjoy building **vid** on my own but I'm open to PR's that align with vid's minimal philosophy.

I won't accept issues solely for suggestions.

Thanks for considering! 🚀
