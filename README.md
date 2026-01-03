# vid

A minimal vim-like text editor for modern terminals written in [Dart](https://dart.dev)

> Made for myself for fun and learning (not meant to replace your current editor)

## Features

- basic vim motions, operators and a minimal command mode
- render and edit emojis and wide characters
- syntax highlighting (dart, lua, c, yaml, md, json)
- LSP support for Dart, Lua, c (highlighting, go-to-def, find refs, completion, hover)
- multi-buffer support
- interactive popup for opening files, buffer selection, themes and diagnostics
- text wrap modes: no-wrap, character-wrap, word-wrap
- unlimited undo and redo

## Keyboard Shortcuts

See [bindings.dart](lib/bindings.dart) for the full list of vim-like key mappings.

## Configuration

vid loads configuration from YAML files at the following locations (first found wins):

1. `./vid.yaml` — local project config
2. `$XDG_CONFIG_HOME/vid/config.yaml`
3. `~/.config/vid/config.yaml`

Copy the example config to get started:

```bash
mkdir -p ~/.config/vid
cp config.example.yaml ~/.config/vid/config.yaml
```

All settings are optional — missing values use sensible defaults. See [config.example.yaml](config.example.yaml) for all available options.

## Contributing

I'm open to PR's that align with vid's minimal philosophy.

I don't accept issues solely for suggestions.
