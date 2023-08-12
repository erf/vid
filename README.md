# vid

A minimal vi-like text editor for the terminal written in Dart by [@erf](https://github.com/erf)😎
 
> Note: for fun and learning; not meant to replace your current editor ;)

## Features 📋

- a minimal fast modal vi-like text editor for the terminal 🤓
- correct rendering, editing and cursor movement of emojis ❤️‍🔥
- made for modern terminal emulators ([WezTerm](https://github.com/wez/wezterm)<3) using the latest Unicode version (15) 📚
- written in pragmatic Dart wo deps (except for the [characters](https://pub.dev/packages/characters) package) 💻
- unlimited undo ↩️

## Non-goals 🛑

- no syntax highlighting (just terminal bg / fg colors)
- no plugins (let's keep things minimal)
- no window manager (just open a new tab)
- no 100 % vim compat (only a minimal subset)
- no pre-built binaries (just build it yourself)

## Keyboard shortcuts ⌨

See [bindings.dart](lib/bindings.dart)

Note the following keybindings differ from vim as we don't have command mode yet; also i quite like these bindings =))

- Save with 's'
- Quit with 'q' or force quit with 'Q' (ignoring changes)
